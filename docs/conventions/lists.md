# Lists

## When to use a list

Use prose by default. Use bullets only when the text genuinely enumerates
parallel items and each item stands on its own. Don't use bullets to chop
narrative prose into fragments.

## Bullet character

Use `-`: it is unambiguously a list marker, while `*` can read as a wildcard or
emphasis depending on the renderer.

## Indentation

Put top-level items at the text margin with no indent before the bullet; add two
spaces per nesting level. A wrapped line aligns under its item's text, not the
bullet.

Top-level items sit flush, and nesting indents two spaces:

```text
- First step.
- Second step.
  - A detail of the second step.
```

A wrapped item keeps its continuation aligned under the item text:

```text
- A point that needs a full sentence to explain, long enough that the text
  wraps onto a second line.
```

## Item spacing

When any item wraps to multiple lines, separate items with a blank line so item
boundaries stand out. Items that all fit on a single line can stay tight (no
blank line between them); don't mix the two styles within the same list.
