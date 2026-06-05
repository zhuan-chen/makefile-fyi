# Dialect

Use POSIX `sh` unless a script truly needs another shell. Runnable scripts start
with `#!/bin/sh`; sourced libraries that are linted directly declare their
dialect with `# shellcheck shell=sh` instead.
