# Sourcing

Source helper files by a path relative to the running script, not through a
configuration variable:

```sh
# shellcheck disable=SC1091
. "$(dirname "$0")/lib/install.sh"
```

`$0` is the running script's own path, set by the shell at invocation, so
`$(dirname "$0")` resolves the helper's location relative to the script and
works from any directory.

The ShellCheck directive is for the analyzer, not the shell. Use that
suppression when the sourced path is computed and the helper is checked directly
as its own shell file.
