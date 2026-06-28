# Makefile FYI

An opinionated GNU Make setup for my polyglot projects, shared as a learning
reference.

Comments throughout explain the underlying concepts and design choices, so a
reader can pick up the patterns alongside the rationale.

This repository also documents code style and repository structure conventions,
so AI agents can apply those rules consistently in this repository and
downstream projects.

## How it works

This repository provides the Make build graph and managed tool environment that
my downstream projects rely on instead of maintaining their own makefiles.

The typical workflow starts by running this setup's `enter` target:

```sh
make -f /path/to/makefile-fyi/Makefile enter
```

This starts an interactive shell configured for downstream work. In that shell,
`MAKEFILES` points Make at this repository's top `Makefile` from any directory,
and `PATH` prioritizes this setup's managed tools. From there, I run `make` in
downstream projects with this build graph and tool environment.

`MAKEFILES` does not disable normal makefile discovery. If a downstream project
has its own discoverable makefile, Make reads it after this setup. That case is
outside this setup's contract: the downstream makefile may override variables or
targets from this setup and cause conflicts.

## Stance

This repository is my personal makefile setup, not a general-purpose framework.

Feel free to fork it for your own use. Makefiles are highly project-specific, so
I do not accept PRs, but issues for errata or questions are welcome.

## License

MIT. See [LICENSE](LICENSE).
