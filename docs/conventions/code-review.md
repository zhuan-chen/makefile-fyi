# Code review

A code review evaluates a staged change before it becomes a commit.

## Scope

By default a review covers the staged change. If there are no staged changes,
say so directly and wait for the next prompt. Do not include unstaged work
except to mention when it may affect the review.

## Passes

Run the review in passes. Where a documented convention applies, check the
change against it; otherwise rely on judgment.

- Correctness: Look for bugs, behavioral regressions, broken contracts, missing
  validation, unsafe edge cases, and missing tests.

- Structure: Check which directory a new file belongs to, how a file is split,
  and how functions or sections are ordered within it. A new file should match
  how its siblings are arranged.

- Naming: Check every directory, file, variable, function, and target the change
  introduces or renames.

- Prose: Proofread the comments and documentation the change touches, section
  and subsection titles included. Review structure, not just wording. A comment
  may sit in the wrong place, a title may name its section poorly, a paragraph
  may read better reordered, or a doc may need splitting.

- Design: Check whether the overall shape is the one you would choose writing
  the change from scratch, weighed against how the diff is actually written.

- Simplicity: Take the shape as given and find the simplest code and text that
  still works. Cut needless moving parts and indirection, remove duplication,
  and reuse what the repo already has over adding a new mechanism.

- Cohesion: Check whether the staged diff is one coherent change or should be
  split into separate commits.

## Findings

State each finding with three things: where it is (path, or file and line), what
is wrong and which convention or reason it breaks, and a concrete fix. Keep each
one tight; a review holds to the same low-noise bar as the code it reads.

Sort findings into two kinds, because they ask different things of the author:

- Must-fix: a breach of a documented convention, or a bug. The standard is
  written down, so the change has to meet it.

- Proposal: a design or prose improvement that rests on judgment. Present it
  with its reasoning for the author to take or leave.

## Commit message

Draft a commit message for the change, one per commit when it splits, following
`docs/conventions/commit-message.md`.
