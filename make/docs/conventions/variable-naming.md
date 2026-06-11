# Variable naming

## Case

Case is not decoration; it tells the reader who is expected to set the variable.

Use lowercase for variables that serve an internal purpose in the makefile:
values the makefile computes for its own use and nobody sets from outside.
`build_dir` is one such variable.

Use uppercase for parameters a user is meant to override on the command line,
such as `CC`, `CFLAGS`, or `PREFIX`. Uppercase signals that `make CC=clang` is a
supported thing to do.

This division is the GNU Make manual's own recommendation, not a local
invention: it advises lowercase for names that "serve internal purposes in the
makefile" and reserves uppercase for "parameters that the user should override
with command options".

See: https://www.gnu.org/software/make/manual/html_node/Using-Variables.html

## Word separator

Join words with underscores, as in `build_dir`. The underscore is the only
separator to use; whether the letters are lowercase or uppercase follows the
rules above.

Make permits other styles, but the two common ones each cause real trouble:

- Hyphens. Make accepts `-` in a name, and `$(some-dir)` does expand, but the
  name does not survive cleanly as a shell variable. A POSIX shell variable name
  does not allow hyphens, so a child shell cannot read `$some-dir` back as one
  variable.

- camelCase. `someDir` is legal and works, but it is unidiomatic in Make, whose
  names conventionally use underscores. Following the convention keeps them
  predictable.
