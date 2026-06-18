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
# SHA256. Empty HOST lines are skipped. HOST is either the normalized host key
# or "-" for a host-agnostic asset. A SHA256 line containing "-" skips
# verification.
_install_select_host_asset() {
	# `uname -sm` prints the system and machine names. Lowercase that and
	# change spaces to hyphens, so "Linux x86_64" becomes the host key
	# linux-x86_64, which matches a HOST line in tool_assets.
	#
	# Two tr calls: combining a character class and literal characters in
	# one translation is not reliably portable.
	_install_host=$(uname -sm | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

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

		case $_install_candidate_host in
		"$_install_host"|-)
			# The matched HOST doubles as the release host suffix. A
			# "-" HOST means the asset is host-agnostic, so clear
			# the suffix before `main` builds install_release.
			case $_install_candidate_host in
			-) _install_host= ;;
			esac

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
	#   1a2b3c...  demo-1.0.tar.xz
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
	: "${install_staging:?set install_staging}"
	: "${install_archive:?set install_archive}"

	_install_archive_path=$install_staging/$install_archive
	case $install_archive in
	*.tar.xz) tar -xJf "$_install_archive_path" -C "$install_staging" ;;
	*.tar.gz) tar -xzf "$_install_archive_path" -C "$install_staging" ;;
	*.zip) unzip -q "$_install_archive_path" -d "$install_staging" ;;
	*) _install_die "unsupported archive: $install_archive" ;;
	esac || _install_die "unpack failed: $install_archive"
}

# _install_place_release: place the release at lib/TOOL-VERSION[-HOST].
_install_place_release() {
	: "${install_staging:?set install_staging}"
	: "${install_release:?set install_release}"

	# tool_stage_dir is the release directory within the staging area.
	: "${tool_stage_dir:?set tool_stage_dir}"

	_install_stage_path=$install_staging/$tool_stage_dir
	_install_release_path=$install_prefix/lib/$install_release

	[ -d "$_install_stage_path" ] ||
		_install_die "_install_place_release: not found: $tool_stage_dir"

	# Normalize the staged release's declared commands: check each exists,
	# then set its exec bit. Some archives (notably .zip) and source builds
	# omit +x, which the later -x checks in _install_try_activate_release
	# and _install_expose_command would then reject. chmod lives here, at
	# placement, not in _install_expose_command: a placed release is not
	# modified afterward, while exposure reruns on every activation.
	while IFS= read -r _install_command; do
		[ -n "$_install_command" ] || continue
		_install_command_path=$_install_stage_path/$_install_command
		[ -f "$_install_command_path" ] ||
			_install_die "_install_place_release: not found:" \
				"$_install_command"
		chmod +x "$_install_command_path"
	done <<EOF
$(tool_commands)
EOF

	mkdir -p "$install_prefix/lib" ||
		_install_die "_install_place_release: cannot create lib"
	rm -rf "$_install_release_path"
	mv "$_install_stage_path" "$_install_release_path"
}

# _install_try_activate_release: activate an installed release if it is intact.
#
# A version bump leaves old releases in lib/. If the requested release is
# already present, activation can relink it without installing anything. A
# damaged release falls through to the full installation path.
_install_try_activate_release() {
	_install_release_path=$install_prefix/lib/$install_release
	[ -d "$_install_release_path" ] || return 1

	while IFS= read -r _install_command; do
		[ -n "$_install_command" ] || continue
		_install_command_path=$_install_release_path/$_install_command
		if [ ! -f "$_install_command_path" ] ||
			[ ! -x "$_install_command_path" ]; then
			return 1
		fi
	done <<EOF
$(tool_commands)
EOF

	_install_activate_release
}

# _install_activate_release: make install_release the active tool release.
_install_activate_release() {
	# Create the command directory before changing the active release. If
	# this fails, the existing release link still points through the old
	# selection.
	mkdir -p "$install_prefix/bin" ||
		_install_die "_install_activate_release: cannot create bin"

	_install_select_release

	# Selecting the release is enough for existing healthy command links,
	# but first installs, repaired installs, and newly added commands still
	# need stable PATH entries under bin/.
	while IFS= read -r _install_command; do
		[ -n "$_install_command" ] || continue
		_install_expose_command "$_install_command"
	done <<EOF
$(tool_commands)
EOF
}

# _install_select_release: set lib/TOOL to install_release.
#
# This symlink chooses the tool's active release:
#   TOOL=demo
#   RELEASE=demo-1.0
#   <prefix>/lib/demo -> demo-1.0
_install_select_release() {
	# Select only an installed release directory. Without this check, a bad
	# caller could leave lib/TOOL pointing at a release that is not present.
	[ -d "$install_prefix/lib/$install_release" ] ||
		_install_die "_install_select_release: not installed:" \
			"$install_release"

	_install_tool_path=$install_prefix/lib/$install_tool

	# Refuse a real directory at lib/TOOL, which the swap helper cannot
	# replace. The normal active release is a symlink that resolves to a
	# directory, so -d alone would reject the healthy state; -L tests the
	# directory entry itself, which lets a symlink-to-directory pass.
	[ ! -d "$_install_tool_path" ] || [ -L "$_install_tool_path" ] ||
		_install_die "_install_select_release:" \
			"destination is directory: $_install_tool_path"

	_install_swap_symlink "$install_release" "$_install_tool_path"
}

# _install_expose_command COMMAND: set one bin/COMMAND symlink.
#
# COMMAND is the executable path inside the active release. Its final path
# component becomes the stable PATH entry:
#   TOOL=demo
#   COMMAND=pkg/demo
#   <prefix>/bin/demo -> ../lib/demo/pkg/demo
#
# It points through the active release symlink, not straight at
# lib/demo-1.0/..., so an active release swap moves every command from the
# release at once.
#
# Even if the command link already has the right text, recreate it. Skipping
# that portably would require reading symlink text, but readlink is not POSIX.
# Recreating the link also repairs a missing or wrong command link.
_install_expose_command() {
	[ "$#" -eq 1 ] ||
		_install_die "_install_expose_command: expected COMMAND"

	# Expose the command by its final path component on PATH: ${1##*/}
	# strips the longest prefix ending in /, so pkg/demo becomes demo, and
	# pkg/sub/demo also becomes demo. The target keeps the full command path
	# inside the release.
	_install_target=../lib/$install_tool/$1
	_install_link=${1##*/}

	# Check the executable through the link text itself, relative to bin/,
	# so the check validates exactly what the new link will resolve to.
	if [ ! -f "$install_prefix/bin/$_install_target" ] ||
		[ ! -x "$install_prefix/bin/$_install_target" ]; then
		_install_die "_install_expose_command: not executable:" \
			"$_install_target"
	fi

	_install_link_path=$install_prefix/bin/$_install_link

	# A command link resolves to an executable file, never a directory.
	# Reject real directories and symlinks to directories alike, so the swap
	# helper never sees a directory-shaped destination here.
	[ ! -d "$_install_link_path" ] ||
		_install_die "_install_expose_command: destination is directory:" \
			"$_install_link_path"

	_install_swap_symlink "$_install_target" "$_install_link_path"
}

# _install_swap_symlink TARGET LINK: make LINK a symlink to TARGET.
#
# The swap creates a scratch symlink in staging and moves it into place:
#   TARGET=demo-1.0
#   LINK=<prefix>/lib/demo
#   scratch:
#     <prefix>/.staging.X/.symlink -> demo-1.0
#   after mv:
#     <prefix>/lib/demo -> demo-1.0
#
# `ln -sf` is not equivalent: POSIX `ln -f` removes an existing path before
# creating the new link, leaving a short no-link window. The final mv is the
# atomic commit point when mv can replace the destination entry directly, so
# readers see either the old link or the new link.
#
# The scratch link lives in staging because staging is inside the install
# prefix, on the same filesystem as bin/ and lib/. A same-filesystem rename can
# replace one directory entry atomically. The symlink text is written for the
# link's final location, so it need not resolve from staging; that is fine,
# because the scratch link is only renamed into place, never dereferenced.
#
# One case needs a portable fallback: replacing LINK when it is already a
# symlink to a directory, the healthy shape of an active release symlink. Plain
# mv follows LINK and moves the scratch link inside it. GNU mv's
# --no-target-directory replaces the entry instead, but POSIX does not define it
# and BusyBox mv lacks it, so the swap tries it and otherwise unlinks LINK
# before the final mv, which briefly leaves no link.
#
# Callers must refuse a real directory at LINK first: plain mv would move the
# scratch link inside it.
#
# See:
# - https://pubs.opengroup.org/onlinepubs/9699919799/utilities/ln.html
# - https://pubs.opengroup.org/onlinepubs/9699919799/functions/rename.html
_install_swap_symlink() {
	[ "$#" -eq 2 ] ||
		_install_die "_install_swap_symlink: expected TARGET LINK"

	install_ensure_staging
	_install_scratch=$install_staging/.symlink
	ln -s "$1" "$_install_scratch" ||
		_install_die "_install_swap_symlink:" \
			"cannot create scratch link: $_install_scratch"

	if [ -L "$2" ] && [ -d "$2" ]; then
		# Prefer mv --no-target-directory, which replaces the entry
		# atomically; where mv lacks that option, unlink first.
		if ! mv --no-target-directory \
			"$_install_scratch" "$2" 2>/dev/null; then
			rm -f "$2" ||
				_install_die "_install_swap_symlink:" \
					"cannot remove link: $2"
			mv "$_install_scratch" "$2" ||
				_install_die "_install_swap_symlink:" \
					"cannot replace link: $2"
		fi
	else
		mv "$_install_scratch" "$2" ||
			_install_die "_install_swap_symlink:" \
				"cannot replace link: $2"
	fi
}

# Install interface: shared names for tool definitions and phase hooks.
#
# Tool definitions may read install_ names from phase overrides, but should not
# assign them. The driver owns that state.

# Set before phases run:
# - install_tool: requested tool name.
# - install_prefix: install destination.
#
# Set by host-asset selection:
# - install_url: release asset URL.
# - install_archive: downloaded archive filename.
# - install_sha256: expected checksum, or empty to skip verification.
#
# Set after host-asset selection:
# - install_release: installed release directory name.
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

# main TOOL: validate the request and require a destination, then load the tool
# definition and run the phases.
main() {
	[ "$#" -eq 1 ] || _install_die "usage: install.sh TOOL"

	# Phase hooks are called with no arguments, so publish the requested
	# tool name as shared install state. The name is later interpolated into
	# tools/<tool>.sh and the destination command link path, so accept only
	# a simple filename stem, not a path.
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

	# tool_assets is optional. Tools with release assets define it so the
	# driver picks the right asset. A tool without assets overrides phases
	# to install another way, e.g. building from source. `command -v` is the
	# POSIX test for whether the function is defined; output is ignored.
	if command -v tool_assets >/dev/null 2>&1; then
		_install_select_host_asset
	fi

	# Build the release name here, not in _install_select_host_asset,
	# because every tool needs it: tools without tool_assets (e.g., a
	# from-source build) never run the selector, yet still install as
	# TOOL-VERSION.
	: "${tool_version:?set tool_version}"
	install_release=$install_tool-$tool_version
	# The :+ expansion appends -$_install_host only when _install_host is
	# set and non-empty; it yields nothing (and stays set -u safe) when
	# unset, so a host-agnostic tool gets a bare TOOL-VERSION name.
	install_release=$install_release${_install_host:+-$_install_host}
	readonly install_release

	if _install_try_activate_release; then
		return 0
	fi

	tool_fetch
	tool_unpack
	_install_place_release
	_install_activate_release
}

# "$@" forwards this script's arguments as separate arguments to main. The
# quotes preserve spaces and empty arguments.
main "$@"
