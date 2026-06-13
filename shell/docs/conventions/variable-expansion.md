# Variable expansion

Although the shell accepts braces on every expansion, use braces only when
omitting them would change the expansion's parsing or semantics. Braces are
needed in only two cases: when the brace marks the parameter's boundary, or when
it applies a parameter-expansion operator.

## Boundary

The shell takes the longest valid name: a letter or underscore followed by zero
or more letters, digits, or underscores. For a positional parameter it takes one
digit, and for a special parameter one character, as in `$#` or `$@`. When the
next character cannot belong to the parameter, as with `/`, `.`, `-`,
whitespace, or a quote, the bare expansion already ends where it should:

```sh
archive=app-v$version.linux.x86_64.tar.gz
url=$url/$archive
```

Here, write `$version` and `$url`, not `${version}` and `${url}`.

Braces set the boundary where the bare form gets it wrong: `${prefix}bin/tool`
keeps `bin` out of the name, and `${10}` reaches the tenth argument, while bare
`$10` is `${1}0`.

## Operator

A parameter-expansion operator always requires braces, on names and special or
positional parameters alike: `stem=${file%.*}`, `parent=${1%/*}`.
