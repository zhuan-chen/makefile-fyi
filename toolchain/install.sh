#!/bin/sh

# install.sh TOOL: install one tool into TOOLCHAIN_INSTALL_PREFIX.
#
# This is the tool installer driver. It owns the shared mechanism: the private
# helpers, the install interface, and the default phase hooks for all tools.
#
# Each tool is defined by a sourced file at tools/<tool>.sh, which declares what
# to install and may override default phases.

set -eu

# Driver helpers: private building blocks for the phase hooks below.

# _install_die MESSAGE...: report an error on stderr and stop.
_install_die() {
	printf 'install: %s\n' "$*" >&2
	exit 1
}

# _install_select_host_asset: choose this host's release asset from tool_assets.
#
# tool_assets provides a small table as three-line records:
#   HOST
#   URL
#   SHA256
#
# POSIX sh has no arrays, so the here-doc table keeps the per-tool host data in
# the tool definition while this helper owns the repeated host detection and
# matching logic. A match sets install_url, install_archive, and install_sha256
# for the default phase hooks or a tool definition's override functions.
#
# The loop reads one HOST line, then consumes the next two lines as URL and
# SHA256. Empty HOST lines are skipped. A SHA256 line containing "-" skips
# verification; an empty one is an error, because the $(tool_assets) feeding
# this loop drops trailing blank lines, so a blank last field would vanish. If a
# record starts but a following line is missing or empty, the helper dies.
_install_select_host_asset() {
	_install_host=$(uname -sm)

	# Read each line with `IFS= read -r`. IFS is the shell's Internal Field
	# Separator; `read` uses it to split fields and trim leading or trailing
	# separators. Setting IFS to empty for this command preserves the line
	# as written, and -r keeps backslashes literal.
	#
	# Feed tool_assets through a here-doc rather than a pipeline, so this
	# loop stays in the current shell and selected install_ assignments
	# survive. Many POSIX sh implementations run pipeline loops in
	# subshells.
	while IFS= read -r _install_candidate_host; do
		[ -n "$_install_candidate_host" ] || continue
		IFS= read -r _install_candidate_url &&
			[ -n "$_install_candidate_url" ] ||
			_install_die "_install_select_host_asset: bad URL line"
		IFS= read -r _install_candidate_sha &&
			[ -n "$_install_candidate_sha" ] ||
			_install_die "_install_select_host_asset: bad SHA line"

		case $_install_host in
		"$_install_candidate_host")
			install_url=$_install_candidate_url

			# The URL's basename: ${install_url##*/} strips the
			# longest prefix ending in a slash.
			install_archive=${install_url##*/}

			# A SHA256 value of "-" is the skip sentinel: store an
			# empty checksum, which the fetch phase treats as "do
			# not verify".
			case $_install_candidate_sha in
			-) install_sha256= ;;
			*) install_sha256=$_install_candidate_sha ;;
			esac

			return 0
			;;
		esac
	done <<EOF
$(tool_assets)
EOF

	_install_die "no release asset for $_install_host"
}

# _install_fetch: fetch install_url into install_archive. curl retries a few
# times and gives up rather than hang forever on a stalled connection. If
# install_sha256 is set, verify the archive before anything trusts it.
_install_fetch() {
	: "${install_url:?set install_url}"
	: "${install_archive:?set install_archive}"

	install_ensure_staging

	# curl flags:
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
		--output "$install_staging/$install_archive" "$install_url" ||
		_install_die "download failed: $install_url"

	[ -n "${install_sha256:-}" ] || return 0

	# The subshell scopes the cd, so the rest of the script keeps its own
	# working directory. We cd into the staging dir because the checksum
	# line names the file by its bare name, which sha256sum resolves against
	# the current directory.
	#
	# printf writes one line in the format sha256sum expects,
	# "<hash><space><mode><filename>", for example:
	#   1a2b3c...  app-1.0.0.tar.xz
	# The mode character is a space for text mode (the default) or * for
	# binary mode. The canonical text-mode line therefore shows two spaces:
	# a field separator and the mode marker.
	#
	# `sha256sum -c -` reads those check lines from stdin (-) and verifies
	# them in check mode (-c): it hashes the named file and compares. A
	# match prints "<file>: OK" and exits 0; a mismatch prints
	# "<file>: FAILED" and exits non-zero, so the `|| _install_die` guard
	# aborts the install.
	(cd "$install_staging" &&
		printf '%s  %s\n' "$install_sha256" "$install_archive" |
		sha256sum -c -) ||
		_install_die "checksum mismatch for $install_archive"
}

# _install_unpack: extract install_archive in place. The format follows the
# filename suffix; supported suffixes are .tar.xz, .tar.gz, and .zip.
_install_unpack() {
	: "${install_archive:?set install_archive}"

	# Needs staging from _install_fetch; fail clearly if absent.
	[ -n "${install_staging:-}" ] ||
		_install_die "_install_unpack: run _install_fetch first"

	_install_archive_path=$install_staging/$install_archive
	case $install_archive in
	*.tar.xz) tar -xJf "$_install_archive_path" -C "$install_staging" ;;
	*.tar.gz) tar -xzf "$_install_archive_path" -C "$install_staging" ;;
	*.zip) unzip -q "$_install_archive_path" -d "$install_staging" ;;
	*) _install_die "unsupported archive: $install_archive" ;;
	esac || _install_die "unpack failed: $install_archive"
}

# _install_place_bin: place tool_binary on PATH as install_tool. tool_binary is
# the binary's path within the staging area; it lands under the install prefix's
# bin/ directory through an atomic rename from that same-filesystem staging
# area, so PATH never sees a half-written file and a failed or interrupted
# install leaves nothing in bin/.
_install_place_bin() {
	: "${tool_binary:?set tool_binary}"

	# Needs staging from _install_fetch; fail clearly if absent.
	[ -n "${install_staging:-}" ] ||
		_install_die "_install_place_bin: run _install_fetch first"

	_install_src=$install_staging/$tool_binary
	_install_dest=$install_prefix/bin/$install_tool

	[ -f "$_install_src" ] ||
		_install_die "_install_place_bin: not found: $tool_binary"

	# Plain mv treats an existing directory destination as "move into it",
	# so reject that before the rename.
	[ ! -d "$_install_dest" ] ||
		_install_die "bad install destination: $install_tool"

	mkdir -p "$install_prefix/bin"
	chmod +x "$_install_src"
	mv "$_install_src" "$_install_dest"
}

# Install interface: shared names for tool definitions and phase hooks.

# Set before phases run:
# - install_tool: requested tool name.
# - install_prefix: install destination.
#
# Set by host-asset selection, or by a tool definition without tool_assets:
# - install_url: release asset URL.
# - install_archive: downloaded archive filename.
# - install_sha256: expected checksum, or empty to skip verification.
#
# Set by install_ensure_staging:
# - install_staging: staging directory.

# install_ensure_staging: create install_staging on first use.
install_ensure_staging() {
	if [ -z "${install_staging:-}" ]; then
		mkdir -p "$install_prefix"
		install_staging=$(mktemp -d "$install_prefix/.staging.XXXXXX")
		readonly install_staging
		trap 'rm -rf "$install_staging"' EXIT
		trap 'exit 130' INT TERM HUP
	fi
}

# Default phase hooks. A tool definition may replace any of these by defining
# the same tool_<phase> function when it is sourced.

tool_fetch() {
	_install_fetch
}

tool_unpack() {
	_install_unpack
}

tool_install() {
	_install_place_bin
}

# main TOOL: validate the request and require a destination, then load the tool
# definition and run the phases.
main() {
	[ "$#" -eq 1 ] || _install_die "usage: install.sh TOOL"

	# Phase hooks are called with no arguments, so publish the requested
	# tool name as shared install state. The name is later interpolated into
	# tools/<tool>.sh and the destination bin path, so accept only a simple
	# filename stem, not a path.
	install_tool=$1
	case $install_tool in
	""|*[!abcdefghijklmnopqrstuvwxyz0123456789_-]*)
		_install_die "invalid tool name: $install_tool"
		;;
	esac
	readonly install_tool

	# $0 is the path used to invoke this POSIX sh script. That matters only
	# because this file is executed, not sourced; a sourced file would see
	# its caller's $0. Make runs the driver by absolute path, so
	# `dirname "$0"` anchors sibling tool definitions regardless of the
	# current working directory.
	_install_definition=$(dirname "$0")/tools/$install_tool.sh
	[ -f "$_install_definition" ] ||
		_install_die "no tool definition: $install_tool"

	# Install prefix: the directory tools install under. Make passes a
	# repo-local default; tests or direct runs can point it elsewhere, e.g.
	# TOOLCHAIN_INSTALL_PREFIX=/tmp/x. Required with no default, so a run
	# with no destination dies before any phase can write.
	#
	# Snapshot the caller's value once into readonly install_prefix. That
	# keeps caller input at the boundary and prevents a tool definition from
	# accidentally changing the install destination. The common alternative
	# is `: "${TOOLCHAIN_INSTALL_PREFIX:?set TOOLCHAIN_INSTALL_PREFIX}"`,
	# which checks input but later code still reads the environment.
	install_prefix=${TOOLCHAIN_INSTALL_PREFIX:?set TOOLCHAIN_INSTALL_PREFIX}
	readonly install_prefix

	# The source path is a variable ShellCheck can't follow (SC1090); the
	# tool definitions are linted on their own, so no coverage is lost.
	# shellcheck disable=SC1090
	. "$_install_definition"

	# tool_assets is optional. Tools with host-specific prebuilt releases
	# define it so the driver picks the right asset. A tool without it sets
	# install_url itself (one URL for every host) or overrides phases to
	# install another way, e.g. building from source. `command -v` is the
	# POSIX test for whether the function is defined; output is ignored.
	if command -v tool_assets >/dev/null 2>&1; then
		_install_select_host_asset
	fi

	tool_fetch
	tool_unpack
	tool_install
}

# "$@" forwards this script's arguments as separate arguments to main. The
# quotes preserve spaces and empty arguments.
main "$@"
