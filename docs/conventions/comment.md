# Comment

A comment is prose carried on lines that begin with a comment marker. Treat the
marker as the comment syntax plus its usual following space; for a line comment
that starts with `#`, that is `#` and one space.

The text-formatting conventions apply to comment text, with indentation and
alignment measured from after the marker, not from column zero, so a nested list
or wrapped line sits relative to the comment text.

The line-length limit still counts the whole line, marker included.

## Placement

Attach a comment directly to the code it describes, with no blank line or bare
comment line between them. A comment and the code it describes form one visual
unit:

```make
# Comment that explains why next_thing exists.
next_thing := something
```

When a comment describes several code blocks, place it before the group and end
it with a blank line. The blank line keeps the group comment from visually
attaching to the first code block; each block can still have its own attached
comment:

```make
# Directories used by build outputs.

# Intermediate build artifacts.
build_dir := build

# Release archives.
dist_dir := dist
```

File-level comments are different: they apply to the whole file rather than the
first code block. Place them at the very top, with a single blank line
separating them from the rest, so they do not visually bind to whatever appears
first.

```make
# Shared defaults for every target in this file.

SHELL := /bin/sh
```

## Paragraphs

When a comment block spans multiple paragraphs, separate them with a bare
comment line, since an empty line would end the block:

```make
# First paragraph of the explanation.
#
# Second paragraph of the explanation.
next_thing := something
```

## Preformatted examples

For code, tables, command output, and other preformatted text inside a comment,
use indentation after the marker rather than Markdown fences. Fences are useful
in Markdown, but in a raw comment they are literal lines and make the example
harder to scan.

Indent each preformatted line two spaces from the comment text margin. Preserve
any additional indentation inside the example after those two spaces.

```sh
# Usage:
#   ./run.sh --check
#   ./run.sh --fix
```

## References

Add a reference when a comment relies on an official or otherwise authoritative
external source. Cite it with a `See:` prefix followed by the URL.

For a short comment, put the citation directly after the comment:

```make
# Short explanation.
# See: https://example.org/single-link
```

For a longer comment, separate the citation with a bare comment line so the
citation is easy to spot when scanning:

```make
# Long explanation that takes several lines to develop. The reader has to scan
# past three lines of prose before reaching the citation, so a visual break
# helps the eye land on the link.
#
# See: https://example.org/single-link
```

For multiple references on the same concept, switch to a bulleted list. Follow
`docs/conventions/list.md` for the bullet character.

```make
# Explanation citing multiple sources.
#
# See:
# - https://example.org/first
# - https://example.org/second
```
