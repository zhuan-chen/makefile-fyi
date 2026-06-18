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
passed to `install.sh <tool>` and, under this repo's Make wiring, selected by
the `.local/lib/<tool>` active release symlink.

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

- `tool_version`: the pinned upstream version. The driver uses it in the
  installed release directory name.

- `tool_assets`: a function printing one or more three-line records: `HOST`,
  then `URL`, then `SHA256`.

  A host-specific `HOST` is the output of `uname -sm`, lowercased with spaces
  changed to hyphens, such as `linux-x86_64`. Use `-` as the `HOST` line for a
  host-agnostic asset. Set the `SHA256` line to `-` to skip checksum
  verification; the table cannot carry an empty `SHA256`, because command
  substitution strips a blank trailing line.

  The driver reads it before the phases and sets `install_url`,
  `install_archive`, and `install_sha256` from the selected record. Tool
  definitions should not assign `install_url`, `install_archive`, or
  `install_sha256`; those `install_` names are installer-produced public state
  for phase overrides to read, not tool-definition inputs to write. Keeping host
  specificity in `tool_assets` keeps the public API small and makes that table
  the single place that describes release asset selection.

- `tool_stage_dir`: the tool-owned release directory relative to
  `install_staging`. It is usually the directory produced by unpacking the
  archive, or by a source build, and the driver installs this whole directory
  into the release store.

- `tool_commands`: a function printing one executable path per line, relative to
  `tool_stage_dir`. The final path component becomes the command name under
  `.local/bin/`.

## Phases

Before running any phase, the driver computes `install_release`, the installed
release directory name. Phase overrides may read it, but must not assign it.

If that release is already present and intact, the driver reactivates it and
skips the phases below. Otherwise it runs two phase hooks in order:

- `tool_fetch`: fetch the release asset or source.
- `tool_unpack`: extract a downloaded archive.

It then installs `tool_stage_dir` as `install_release` and activates it.

The driver defines default `tool_<phase>` functions before sourcing the tool
definition. A tool definition overrides a phase by defining the same function
name; otherwise the default runs.

When overriding a phase, use the shared `install_` interface documented in
`install.sh`. Treat `_install_` names as driver internals.
