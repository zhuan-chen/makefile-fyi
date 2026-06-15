# shellcheck shell=sh

# Tool definition for ShellCheck, a static-analysis linter for shell scripts.
#
# See:
# - https://www.shellcheck.net
# - https://github.com/koalaman/shellcheck#installing
# - https://github.com/koalaman/shellcheck/releases

tool_version=0.11.0

tool_assets() {
	cat <<EOF
Linux x86_64
https://github.com/koalaman/shellcheck/releases/download/v$tool_version/shellcheck-v$tool_version.linux.x86_64.tar.xz
8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198
EOF
}

# shellcheck disable=SC2034
tool_binary=shellcheck-v$tool_version/shellcheck
