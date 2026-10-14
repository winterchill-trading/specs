# Repository pages (AGENTS.md)

One page per repository of the organization: `<repo>.md`, named as the repository is named on GitHub.

Each page has the same sections, in the same order: a summary, a facts table (repository, opam package,
libraries, binaries, status), key modules, dependencies and dependents, CI pins, and known gaps.

- Fill every row from the repository itself: `dune-project`, `*.opam`, `lib/dune`, `bin/dune`, the CI
  workflow and the README. A fact that is not in the repository is marked as planned.
- When a repository gains a library, a binary or an opam dependency on another organization repository,
  update its page, the `overview.md` graph, and the "Used by" line of every page it now depends on.
- Keep the CI pin order identical to the `pins:` block of the repository's workflow.
- Status is one of `done`, `in progress` or `planned`, with a short reason in the same line.
- Known gaps are facts from the README or from measurements, with the date when a measurement was taken.
- Link other repositories by their page, `[name](name.md)`, and never by an absolute path.
