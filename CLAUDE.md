# Working with specs

This repository describes the architecture of every repository in the winterchill-trading
organization. Use it before changing code, and keep it true after.

## Before touching a repository

1. Read [overview.md](overview.md) for the layers and dependency graph.
2. Read `repos/<repo>.md` for the repository you will change, and the pages of the
   repositories it depends on or that depend on it ("Depends on" / "Used by").
3. If the change touches a cross-repository design (data platform, market making,
   simulators, cloud sinks, deployment), read the matching page in `design/` and the ADRs
   it links to.
4. The repository's own README and `.mli` files win over specs when they disagree; fix
   specs in the same session.

## When architecture changes

Update specs in the same session, one commit per document, when a change:

- adds a repository, a public library, a binary or an opam dependency between org
  repositories (update `repos/<repo>.md`, the graph in `overview.md`, and the CI pin
  order on the pages of every repository whose CI pins it);
- changes an on-disk format, a file layout, a wire protocol or a venue adapter contract
  (update the `design/` page);
- reverses or adds a significant decision (add an ADR, `adr/NNNN-title.md`, next free
  number; mark the superseded one);
- finishes or starts work listed in [roadmap.md](roadmap.md).

Every such change also adds one line to [CHANGELOG.md](CHANGELOG.md) under today's date
(UTC), newest day first, naming the repositories and linking the page that describes it.
A change that needs no spec update needs no changelog line.

## Writing rules

- Present tense, factual, short. Every claim must be checkable in a repository's
  `dune-project`, `*.opam`, `.mli`, CI workflow or README; say "planned" or "in progress"
  for anything not in code yet.
- Every `design/` page states its kind on the line after the H1, as
  `Kind: <kind>.`, where the kind is one of
  - `tutorial`: a guided first run that teaches by doing;
  - `how-to`: steps or recipes for one task, for a reader who knows the system;
  - `reference`: facts to look up (tables, formats, columns), complete and dry;
  - `explanation`: why the design is the way it is, its trade-offs and open questions.

  A page that needs two kinds is two pages. Keep the line when editing, and change it if
  the page changes kind.
- Mermaid for diagrams. Node ids use underscores (`exchange_core["exchange-core"]`).
- Run `npx -y markdownlint-cli2 '**/*.md'` and `scripts/check-mermaid.sh` before
  pushing.
- No person or company names; no absolute paths from a developer machine.
