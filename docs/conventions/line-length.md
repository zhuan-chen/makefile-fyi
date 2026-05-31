# Line length

Lines should not exceed 80 columns, with a tab counted as 8 columns. This
applies to both prose and code unless a more specific convention overrides it.

Use ASCII punctuation only. Non-ASCII characters (em dashes, en dashes, smart
quotes, and similar) have terminal-, font-, and editor-dependent widths, so the
column count is no longer well-defined when they are used.

## Prose

Pack words greedily up to the limit: break to a new line only when the next word
would overflow. Wrapping earlier, when the next word still fits, is wrong.

## Code

Rely on language-specific formatters or linters to handle wrapping. Quoted
strings are the usual exception: they stay unbroken even when they push the line
past the limit.

## Exceptions

- `LICENSE` keeps the format of its standard upstream version.
- Commit messages use narrower line limits; see
  `docs/conventions/commit-message.md`.
