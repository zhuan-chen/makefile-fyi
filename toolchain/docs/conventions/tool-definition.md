# Tool definition

The installer is one driver plus one tool definition per tool:

- `install.sh` is the driver: a single executable that installs any tool,
  invoked as `install.sh <tool>`.

- `tools/<tool>.sh` is a tool definition: a sourced file that describes one
  tool.

The driver owns the shared installation mechanism. Tool definitions describe
what to install.

## Location

Put one tool definition at `tools/<tool>.sh`, where `<tool>` is the tool name
passed to `install.sh <tool>` and, under this repo's Make wiring, installed as
`.local/bin/<tool>`.

Tool names are filename stems, not paths. Use lowercase letters, digits,
underscores, and hyphens only.

## File shape

A tool definition is sourced, not run, so it carries no shebang and sets no
shell options. Declare its dialect so ShellCheck can lint it directly:

```sh
# shellcheck shell=sh
```

Use `tool_` names for the tool definition's public surface: data variables and
phase overrides that the driver reads or calls. Use `_tool_` names only for
private scratch.

Because the driver reads some `tool_` data across a `source` boundary,
ShellCheck may see the data as unused in the tool definition. Disable `SC2034`
near those declarations instead of adding dummy reads.

## Data

Most prebuilt-release tools declare the following data and use every default
phase:

- `tool_assets`: a function printing one three-line record per supported host:
  `HOST`, then `URL`, then `SHA256`. If present, the driver reads it before the
  phases and sets `install_url`, `install_archive`, and `install_sha256` for the
  selected host. Set the `SHA256` line to `-` to skip checksum verification; the
  table cannot carry an empty `SHA256`, because command substitution strips a
  blank trailing line.

- `tool_binary`: the executable's path inside the unpacked archive. This is
  per-tool packaging the driver cannot derive, so the tool definition states it.
  It is required by the default `tool_install` phase.

If a tool does not use `tool_assets`, it may set `install_url` and
`install_archive` (and optionally `install_sha256`) itself and keep the default
fetch phase.

## Phases

The driver runs three phase hooks in order for every tool:

- `tool_fetch`: fetch the release asset or source.
- `tool_unpack`: extract a downloaded archive.
- `tool_install`: place the executable on `PATH` under the prefix.

The driver defines default `tool_<phase>` functions before sourcing the tool
definition. A tool definition overrides a phase by defining the same function
name; otherwise the default runs.

When overriding a phase, use the shared `install_` interface documented in
`install.sh`. Treat `_install_` names as driver internals.
