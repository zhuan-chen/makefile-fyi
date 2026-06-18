# Release

Installs are additive, and every installed release is a directory under the
install prefix:

```text
bin/<command> -> ../lib/<tool>/<command-path>  one stable link per command
lib/<tool>    -> <tool>-<version>[-<host>]     active release symlink
lib/<tool>-<version>[-<host>]/                 release directory
```

A version bump installs the new release next to the old ones and swaps the
active release symlink. Normal version changes do not delete older release
directories, so every installed version stays runnable by its release path.

A downgrade to an already-installed release needs no download: the installer
activates the release before fetching anything.
