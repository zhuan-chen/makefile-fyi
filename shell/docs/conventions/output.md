# Output

Use `printf`, not `echo`. Across shells `echo` differs in how it treats
backslash escapes and a leading `-`, while `printf` prints its arguments the
same way everywhere.

Send error messages to stderr and exit non-zero, so a failure is both visible to
a person and detectable by a caller. Centralize the prefix and exit in a small
helper:

```sh
# die MESSAGE...: report an error on stderr and stop.
die() {
	printf 'app: %s\n' "$*" >&2
	exit 1
}
```
