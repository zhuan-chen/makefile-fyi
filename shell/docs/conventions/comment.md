# Comment

The root comment conventions apply to shell comments too. These rules add
shell-specific comment patterns.

## Function comments

For reusable functions, introduce the function with a compact signature comment:

```sh
# install_bin SRC NAME: place one executable on PATH.
install_bin() {
```

Use uppercase placeholders in the signature comment for positional parameters.
Keep the prose after the colon short; put longer rationale next to the code path
that needs it.

## Command flags

When a shell command needs several flags, put a short flag glossary immediately
before the command. Shell cannot carry inline comments between arguments, so the
glossary makes non-obvious flags reviewable without breaking the command shape.

```sh
# --fail: HTTP 4xx/5xx becomes a non-zero exit, not a saved error page.
# --location: follow redirects.
# --max-time 600: cap total time so a stall can't hang forever.
# --output: write to a file instead of stdout.
curl --fail --location --max-time 600 --output "$dest" "$url"
```
