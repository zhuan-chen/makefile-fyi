# Commit message

Commit messages have a subject, an optional body, and optional trailers. This is
the same general shape used by the Linux kernel, Git, and the Go standard
library.

## Subject

Use the `<subsystem>: <description>` form, with a 50-character maximum including
the prefix and no trailing period.

`<subsystem>` is the code area touched and keeps `git log` skimmable by area.
Use the directory path relative to the repository root, with `/` for nesting.
Pick the most specific path that captures the change. For repository-wide
changes, omit the `<subsystem>` prefix and use only `<description>`. There is no
fixed scope list; the tree is the source of truth.

`<description>` names the change in imperative mood. It starts with a lowercase
imperative verb ("use X", not "Use X" or "used X") unless a proper noun, path,
or API name requires capitalization.

## Body

Write a body when the subject alone does not provide enough context about the
change. Separate it from the subject with a blank line.

Body lines use the greedy wrapping rule from `docs/conventions/line-length.md`
at 72 columns.

### Content

The diff already shows every file, line, and expression. The body earns its
space by carrying context the diff cannot:

- The conceptual "what", not a file-by-file recap.
- The "why": motivation, trade-offs, or constraints that drove the choice.
- Non-obvious decisions or consequences.

Skip mechanical details already visible in the diff, such as line edits, file
moves, and path changes. Keep code-level "how" in comments next to the code it
describes. Keep process detail in issues or pull requests.

### Style

Follow `docs/conventions/list.md` for prose versus bullets.

Follow `docs/conventions/backtick.md` for backticks.

### Related commits

Reference related commits by 7-character short hash when that is unambiguous in
this repository (`Follows 1a2b3c4`, `Built on 1a2b3c4`). For load-bearing
references like a revert, include the subject in quotes:
`Reverses "rename build output" (1a2b3c4)`.

## Trailers

Trailers attach machine-readable metadata, such as issue links and revert
markers. Put each trailer on its own line after the body, separated from the
body by a blank line.

Each trailer is a single logical line. Do not wrap, even if it exceeds 72
columns.

- `Fixes: #123` closes an issue on merge.
- `Refs: #456` references an issue without closing it.
- `Reverts: 1a2b3c4` reverts a prior commit.
