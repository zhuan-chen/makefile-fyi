# Installer

## Layout

Runnable installer scripts for individual tools live at
`toolchain/tools/install-<tool>.sh`. The shared installer library lives at
`toolchain/tools/lib/install.sh`; keep it a sourced helper, not a runnable
installer or aggregate entrypoint.

The split is deliberate.

A tool script says what to install: the version, the per-platform asset and
checksum, the download URL, and final binary placement. A tool script names no
installation paths or environment variables of its own, so adding a tool is
mostly declaring what to fetch.

The library handles where and how: it resolves the install prefix, creates a
staging area with cleanup traps on the first fetch, and provides the host
selection, fetch, verify, unpack, and install helpers.

## Contract

A tool script in `toolchain/tools/` sources the shared helper by the script's
own path:

```sh
# shellcheck disable=SC1091
. "$(dirname "$0")/lib/install.sh"
```

The path is a self-reference, not an environment variable: `$0` is the tool
script's own path, so `$(dirname "$0")` locates the library relative to it, from
any directory.
