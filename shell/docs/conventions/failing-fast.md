# Failing fast

Run scripts under `set -eu` to stop on the first failed command (`-e`) and on
any unset variable (`-u`). A sourced library can set this once for the script
that sources it, so the helpers and their caller share one failure policy.

Guard a required caller or environment input with `${VAR:?message}`. It expands
to the value when the name is set and non-empty; otherwise it prints the message
and exits, so a missing input fails at once rather than expanding to an empty
string:

```sh
config_path="${APP_CONFIG:?set APP_CONFIG}"
```
