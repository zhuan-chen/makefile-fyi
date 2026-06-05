# shellcheck shell=sh

# Shared helpers for the per-tool install scripts in `toolchain/tools/`.
#
# The split is deliberate. A tool script says what to install: the version, the
# per-platform asset and checksum, the download URL, and the placement step
# (install_bin). This library handles where and how: it resolves the install
# prefix, creates a staging area with cleanup traps on the first fetch, and
# provides the host selection, fetch, verify, unpack, and install helpers. A
# tool script names no paths or environment variables of its own, so adding a
# tool is mostly declaring what to fetch.
#
# Contract: a tool script in `toolchain/tools/` sources this from its `lib/`
# subdirectory, locating the file by its own path:
#   # shellcheck disable=SC1091
#   . "$(dirname "$0")/lib/install.sh"
#
# The ShellCheck directive is for the analyzer, not the shell. Tool scripts
# suppress the "not following" message for this computed source path because the
# shared helper is checked directly as its own shell script.
#
# The path is `$(dirname "$0")` (self-reference), not an environment variable:
# the library sits at a fixed path relative to the tool script, so the script
# finds it by its own location. `$0` is set by the shell at invocation and works
# from any directory.

# Stop on the first failed command and on any unset variable. These apply to the
# sourcing tool script too, which is what we want.
set -eu

# Install prefix: the tree whose `bin/` goes on the caller's PATH.
#
# The destination is supplied by `TOOLCHAIN_INSTALL_PREFIX`. Make can compute
# and pass the repo-local default, while tests or direct invocations can point
# it elsewhere, e.g. `TOOLCHAIN_INSTALL_PREFIX=/tmp/x` for tests that must not
# touch the real tree.
#
# The `${NAME:?MSG}` expansion uses NAME when set and non-empty; otherwise it
# prints MSG and exits. So a bare `./toolchain/tools/<tool>.sh` without an
# install destination dies before it can write anywhere.
_install_prefix="${TOOLCHAIN_INSTALL_PREFIX:?set TOOLCHAIN_INSTALL_PREFIX}"

# die MESSAGE...: report an error on stderr and stop.
die() {
	printf 'install: %s\n' "$*" >&2
	exit 1
}

# select_host_asset TOOL: choose the current host's release asset from stdin.
#
# The caller provides a small table as three-line records:
#   HOST
#   ARCHIVE
#   SHA256
#
# POSIX sh has no arrays, so the here-doc table keeps the per-tool host data in
# the tool script while this helper owns the repeated host detection and
# matching logic. A match prints `ARCHIVE|SHA256`, leaving the caller to split
# and assign those names explicitly.
#
# The helper reads each line with `IFS= read -r`. `IFS` is the shell's Internal
# Field Separator; `read` uses it to split fields and trim leading or trailing
# separators. Setting it to empty for this command preserves the line as
# written, and `-r` keeps backslashes literal. The uppercase name is the
# standard shell variable name, like `PATH` and `HOME`.
#
# The loop reads one HOST line, then consumes the next two lines as ARCHIVE and
# SHA256. Empty HOST lines are skipped. If a record starts but either following
# line is missing or empty, the helper dies instead of returning partial data.
#
# Usage:
#   selected_asset=$(
#       select_host_asset tool-name <<EOF
#   Linux x86_64
#   tool-v${version}.linux.x86_64.tar.xz
#   8c3be...
#   EOF
#   )
#   archive=${selected_asset%%|*}
#   sha256=${selected_asset#*|}
#
# The final two lines are POSIX parameter expansion. The first removes the
# longest suffix that starts with `|`, leaving the archive before the separator.
# The second removes the shortest prefix that ends with `|`, leaving the sha256
# after the separator. In those shell patterns, `*` is the wildcard and `|` is a
# literal separator.
select_host_asset() {
	[ "$#" -eq 1 ] || die "select_host_asset: expected TOOL"
	_install_tool=$1
	_install_host=$(uname -sm)

	while IFS= read -r _install_candidate; do
		[ -n "$_install_candidate" ] || continue
		IFS= read -r _install_archive && [ -n "$_install_archive" ] ||
			die "select_host_asset: bad archive line"
		IFS= read -r _install_sha && [ -n "$_install_sha" ] ||
			die "select_host_asset: bad sha256 line"

		case $_install_host in
		"$_install_candidate")
			printf '%s|%s\n' "$_install_archive" "$_install_sha"
			return 0
			;;
		esac
	done

	die "no $_install_tool build for $_install_host"
}

# fetch_and_verify URL FILENAME SHA256: download into the staging area and check
# its SHA-256 before anything trusts it. curl retries a few times and gives up
# rather than hang forever on a stalled connection.
fetch_and_verify() {
	_install_url=$1
	_install_file=$2
	_install_sha=$3

	# Create the staging dir and arm cleanup on the first fetch; the guard
	# makes a later fetch a no-op. Deferred from source time so a tool that
	# dies on an unsupported platform touches nothing. It lives inside the
	# install prefix (same filesystem as its bin/) so install_bin can place
	# a tool by rename.
	if [ -z "${_install_staging:-}" ]; then
		mkdir -p "$_install_prefix"
		_install_staging=$(mktemp -d "$_install_prefix/.staging.XXXXXX")
		trap 'rm -rf "$_install_staging"' EXIT
		trap 'exit 130' INT TERM HUP
	fi

	# curl flags (shell can't annotate them inline mid-command):
	# --fail: HTTP 4xx/5xx becomes a non-zero exit, not a saved error page.
	# --location: follow redirects (GitHub releases redirect to a CDN).
	# --retry 3, --retry-delay 1: retry transient errors, 1s apart.
	# --connect-timeout 10: fail if the connection isn't made within 10s.
	# --max-time 600: cap total time so a stall can't hang forever.
	# --output: write to the staging file instead of stdout.
	# No --silent, so curl's progress meter stays visible.
	curl --fail --location \
		--retry 3 --retry-delay 1 \
		--connect-timeout 10 --max-time 600 \
		--output "$_install_staging/$_install_file" "$_install_url" ||
		die "download failed: $_install_url"

	# The subshell scopes the cd, so the rest of the script keeps its own
	# working directory. We cd into the staging dir because the checksum
	# line names the file by its bare name, which sha256sum resolves
	# against the current directory.
	#
	# printf writes one line in the format sha256sum expects,
	# "<hash><space><mode><filename>", for example:
	#   8c3be...198  shellcheck-v0.11.0.linux.x86_64.tar.xz
	# The mode character is a space for text mode (the default) or `*` for
	# binary mode. The canonical text-mode line therefore shows two spaces:
	# a field separator and the mode marker.
	#
	# `sha256sum -c -` reads those check lines from stdin (-) and verifies
	# them (-c): it hashes the named file and compares. A match prints
	# "<file>: OK" and exits 0; a mismatch prints "<file>: FAILED" and
	# exits non-zero, so the `|| die` aborts the install.
	(cd "$_install_staging" &&
		printf '%s  %s\n' "$_install_sha" "$_install_file" |
		sha256sum -c -) ||
		die "checksum mismatch for $_install_file"
}

# unpack FILENAME: extract a staged archive in place. The format follows the
# extension: .tar.xz, .tar.gz, and .zip are supported.
unpack() {
	# Needs the staging dir from fetch_and_verify; fail clearly if absent.
	[ -n "${_install_staging:-}" ] ||
		die "unpack: run fetch_and_verify first"

	case $1 in
	*.tar.xz) tar -xJf "$_install_staging/$1" -C "$_install_staging" ;;
	*.tar.gz) tar -xzf "$_install_staging/$1" -C "$_install_staging" ;;
	*.zip) unzip -q "$_install_staging/$1" -d "$_install_staging" ;;
	*) die "unpack: unsupported archive type: $1" ;;
	esac || die "unpack failed: $1"
}

# install_bin SRC NAME: place one executable on PATH. SRC is the binary's path
# within the staging area; it lands at $_install_prefix/bin/NAME through an
# atomic rename from that same-filesystem staging area, so PATH never sees a
# half-written file and a failed or interrupted install leaves nothing in bin/.
install_bin() {
	# Needs the staging dir from fetch_and_verify; fail clearly if absent.
	[ -n "${_install_staging:-}" ] ||
		die "install_bin: run fetch_and_verify first"

	_install_src=$_install_staging/$1
	_install_name=$2
	_install_dest=$_install_prefix/bin/$_install_name

	[ -f "$_install_src" ] || die "install_bin: not found: $1"
	mkdir -p "$_install_prefix/bin"

	# Plain mv treats an existing directory destination as "move into it",
	# so reject that before the rename.
	[ ! -d "$_install_dest" ] ||
		die "install_bin: destination is directory: $_install_name"

	chmod +x "$_install_src"
	mv "$_install_src" "$_install_dest"
}
