# Comments

## Placement

Attach a comment directly to the code it describes, with no blank line or bare
comment line between them. A comment and the code it describes form one visual
unit:

```make
# Comment that explains why next_thing exists.
next_thing := something
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
comment line:

```make
# First paragraph of the explanation.
#
# Second paragraph of the explanation.
next_thing := something
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

For multiple references on the same concept, switch to a bulleted list. Use `-`
as the bullet character: it is unambiguously a list marker, while `*` can read
as a wildcard or emphasis depending on the renderer.

```make
# Explanation citing multiple sources.
#
# See:
#   - https://example.org/first
#   - https://example.org/second
```
