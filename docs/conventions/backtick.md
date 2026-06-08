# Backtick

Backticks mark a literal token, not emphasis. Use them when the reader should
read a specific sequence of characters instead of an ordinary prose concept. How
freely to reach for them depends on the medium: rendered Markdown versus a raw
code comment.

## Markdown

Rendered Markdown shows a backticked token as highlighted inline code, so a
backtick costs nothing and adds real distinction. There, backtick every literal
token (paths, commands, expressions, identifiers), as technical writing
conventionally does.

## Comments

Backticks are literal characters in a comment, not rendered formatting, so use
them only where bare text would be misread or hard to parse. In a comment, a
token needs backticks only when one of these is true:

- It could be read as ordinary English: `make`, `all`, `include`. Tokens whose
  shape already marks them as technical stay bare: command names like `printf`,
  snake_case names like `root_dir`, camelCase names like `abcXyz`, PascalCase
  names like `AbcXyz`, and all-caps names like `PATH`.

- The token uses punctuation or operator characters whose exact spelling or
  boundary matters: `$(...)`, `-r`, `||`, `ARCHIVE|SHA256`. Filename suffixes
  stay bare when they are clear in context: `.tar.xz`, `.tar.gz`, `.zip`.

- It is a multi-word command, where the backticks bound the whole statement,
  spaces and all, so it reads as one unit and is not split across a line break:
  `IFS= read -r`, `sha256sum -c -`.

For multi-line examples inside comments, follow the `Preformatted examples`
section in `docs/conventions/comment.md` rather than Markdown fences.
