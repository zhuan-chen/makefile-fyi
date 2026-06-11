# Path anchor

Anchor paths to the makefile being read, not the working directory. Every
makefile here needs its own directory as a stable anchor for sibling files
(includes, scripts, data): the top Makefile wants the repo root, an included
module wants its own location. This one macro serves them all as a recursive
variable:

```make
self_dir = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
```

## How `MAKEFILE_LIST` records paths

`MAKEFILE_LIST` is the list of makefiles GNU Make has opened so far, and its
last word is the one Make is reading right now. That name is exactly the string
Make was given. For the top makefile, the form depends on how you launched Make:

- `Makefile` from a bare `make`, found in the current directory.
- `path/to/Makefile` from `make -f path/to/Makefile`.
- `/path/to/Makefile` from `make -f /path/to/Makefile`.

An included makefile is recorded the same way, by the path in its `include`
directive: `include inc/foo.mk` stores `inc/foo.mk`.

See: https://www.gnu.org/software/make/manual/html_node/Special-Variables.html

## Prefer `abspath` to `realpath`

`$(dir ...)` keeps the directory portion, and `$(abspath ...)` makes it absolute
so the result no longer depends on the current directory, which can change with
`make -C`, sub-makes, or recipes that run `cd`.

We use `abspath` rather than `realpath`. Both make the path absolute, but
`realpath` also resolves symlinks to their target, while `abspath` works purely
textually: it collapses `.` and `..` and leaves any symlinks alone. That keeps
the result faithful to the path Make was actually invoked through.

Symlinks survive only in the part of the path Make is actually handed, though.
To make a relative name absolute, `abspath` prepends Make's working directory,
which Make reads from `getcwd` with symlinks already resolved. So
`make -f /link/Makefile` keeps `/link`, but a bare `make` or `make -C` from a
symlinked checkout reports the resolved directory.

See: https://www.gnu.org/software/make/manual/html_node/File-Name-Functions.html

## Keep `self_dir` recursive

`self_dir` is recursive (`=`), so it is not expanded where it is defined.
Instead, each use re-reads `MAKEFILE_LIST` and reports whichever makefile is
current at that point.

## Capture before includes

An `include` appends the included file to `MAKEFILE_LIST`, so capture a
makefile's own directory with `:=` before it includes anything:

```make
root_dir := $(self_dir)

include $(root_dir)/rules.mk
```

If a makefile waits until after an `include`, `self_dir` resolves to the
included file and yields the wrong directory.

## Name captured paths

Name each captured path for its role.

Use `root_dir` for the top-level makefile because it names the repository root
and is shared across the whole Make setup, including included `.mk` files. Use
it for repo-relative paths so every include, script, and data reference starts
from the same anchor.

Use `here` in an included module when that module needs its own directory for
sibling files.

## Keep `self_dir` in the top Makefile

This macro lives in the top Makefile and cannot be moved into an included
library, no matter how that library is located.

If the library is located with `include $(root_dir)/lib/...`, the include hits a
cycle: `root_dir` is `$(self_dir)`, but `self_dir` would be defined inside the
not-yet-included file, so `$(root_dir)` is still empty and the path breaks.

If the library is located with a path that avoids `root_dir` (hardcoded or
relative), the include works, but appends the library to `MAKEFILE_LIST`, so a
later `root_dir := $(self_dir)` resolves to the library's directory.

## Relative paths resolve against the working directory

A relative path in an `include` resolves against Make's working directory, not
the directory of the makefile that wrote it. The same goes for paths in recipes
and in `$(wildcard ...)`. The working directory is not fixed: `make -C`, a
sub-make, or a plain `make` started from another directory each move it. So a
bare relative `include rules.mk` finds the file only when you start from the
repo root.

Prefixing the path with the captured anchor removes that dependence:

```make
include $(root_dir)/rules.mk
```

`$(root_dir)` is absolute, so the include resolves to the same file wherever
Make starts. That is the payoff of capturing the anchor: a path written
`$(root_dir)/...` points to one file no matter where Make runs.
