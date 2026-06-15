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
them only where bare text would be misread or hard to parse. The examples here
use backticks because this file is Markdown. When this section says a token
stays bare, omit those backticks in the comment.

In a comment, use backticks only in these cases:

- A token could be read as ordinary English: `make`, `all`, `include`, `read`.

- A multi-word command needs to stay bound as one statement, spaces and all, so
  it reads as one unit and is not split across a line break: `IFS= read -r`,
  `sha256sum -c -`.

Otherwise the token already reads as technical, so leave it bare:

- Command names whose spelling is not ordinary English: `printf`.

- Paths and filenames in their ordinary form: `file.txt`, `.tar.gz`, `src/abc`,
  `/usr/local/bin`. Slashes and dots are expected file syntax and read clearly.

- Punctuation, set apart by its symbols: `$(...)`, `-r`, `||`.

- Placeholders, marked as slots by their brackets: `<name>`, `foo_<bar>`.

- Identifier case styles: `snake_case`, `camelCase`, `PascalCase`.

- Underscore-marked identifiers: `_foo`, `foo_`, `_foo_`, `__foo__`.

- All-caps names: `PATH`.

For multi-line examples inside comments, follow the `Preformatted examples`
section in `docs/conventions/comment.md` rather than Markdown fences.
