#!/bin/sh

# Install ShellCheck (https://www.shellcheck.net).
#
# See:
# - https://github.com/koalaman/shellcheck#installing
# - https://github.com/koalaman/shellcheck/releases

# shellcheck disable=SC1091
. "$(dirname "$0")/lib/install.sh"

version="0.11.0"

selected_asset=$(
	select_host_asset shellcheck <<EOF
Linux x86_64
shellcheck-v${version}.linux.x86_64.tar.xz
8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
EOF
)
archive=${selected_asset%%|*}
sha256=${selected_asset#*|}

url="https://github.com/koalaman/shellcheck/releases/download/v${version}/${archive}"

fetch_and_verify "$url" "$archive" "$sha256"
unpack "$archive"
install_bin "shellcheck-v${version}/shellcheck" shellcheck
