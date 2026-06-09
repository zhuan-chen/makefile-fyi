# Agents

Instructions for AI coding agents working in this repo and in downstream
projects that rely on it.

## Conventions

Conventions are layered: root rules apply everywhere, language rules apply to
that language, and area rules add to or override them within their scope.

- Root: `docs/conventions/*.md`.
- Language: `<language>/docs/conventions/*.md` when touching that language.
- Area: `<area>/docs/conventions/*.md` for each code area.

Always read the root conventions before starting. Before touching a language or
area, read the matching conventions.

### Compose conventions

Each convention file documents one concept: name the file and its `#` title as
the singular of that concept (kebab-case filename), and cover the concept's
facets as `##` sections. Split a file rather than letting it bundle unrelated
concepts.

## Version control

Keep generated changes unstaged. Any changes already staged when the session
began stay staged; this keeps pre-existing work and AI-generated work visually
distinct in `git status`. If I stage a generated change during the session, do
not unstage it; leave any later generated edits to that change unstaged.

Do not commit. I may ask for help drafting a commit message, but I run
`git commit` myself.
