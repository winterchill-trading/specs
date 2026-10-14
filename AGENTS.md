# AGENTS.md: specs

## Purpose

specs holds the architecture and design documentation for every repository of the organization:
what each one does, how they fit together and why. Read it before changing code, and update it
in the same piece of work when the architecture changes. It contains Markdown only.

The detailed rules for agents are in [CLAUDE.md](CLAUDE.md). This file is the entry point:
where things are, how to check them, and how to write.

## Layout

| Path | Holds |
| --- | --- |
| `overview.md` | The ecosystem on one page: layers, dependency graph, runtime data flow |
| `repos/` | One page per repository: purpose, libraries and binaries, key modules, dependencies, CI pins, status, gaps |
| `design/` | Cross-repository designs: data platform, market making, simulators, price anchor, deployment, copy trading |
| `adr/` | Numbered architecture decision records, `NNNN-short-title.md` (see `adr/AGENTS.md`) |
| `research/` | Reading notes and studies that feed proposals (see `research/AGENTS.md`) |
| `postmortems/` | Blameless incident write-ups, started from `TEMPLATE.md` |
| `scripts/` | `check-mermaid.sh`, which renders every Mermaid block |
| `.github/` | `ci.yml`: the Markdown lint and the Mermaid check |
| `roadmap.md`, `CHANGELOG.md` | Done, in progress and next; one line per architecture change, by day |
| `README.md`, `CLAUDE.md` | Navigation and conventions for people; the agent rules |
| `.markdownlint-cli2.jsonc` | Lint configuration: 100 characters for prose, tables and code excluded |

## Checks

There is no build. Before a push, run both checks from the repository root:

```sh
npx -y markdownlint-cli2 '**/*.md'
scripts/check-mermaid.sh
```

The Mermaid script renders every fenced `mermaid` block with a pinned `mermaid-cli`, so it needs
network access on the first run. CI runs the same two checks with Node 22.

## Conventions

- One document per topic: a repository gets one page under `repos/`; a design spanning
  repositories gets one page under `design/`. Link instead of repeating.
- Each `design/` page states its kind on the line after the H1 (`Kind: tutorial`, `how-to`, `reference`
  or `explanation`). A page that needs two kinds is two pages.
- Status words are `done`, `in progress` and `planned`, with the same meaning everywhere.
- Present tense, factual and short. Every claim about a repository must be checkable in its
  `dune-project`, `*.opam`, `.mli` files, CI workflow or README. Use "planned" or "in progress"
  for anything not in code yet.
- Names follow the code: repositories and opam packages as in `dune-project`, modules as in the source.
- Mermaid for diagrams. Node ids use underscores (`exchange_core["exchange-core"]`).
- Relative links only. No absolute paths from a developer machine, and no person or company names
  other than the organization and the public projects and venues it builds on.

## Dependencies and dependents

specs is a sibling checkout next to every repository (`../<repo>`). Each `repos/<repo>.md` page lists
"Depends on" and "Used by"; keep both sides in step when an edge changes. Changes to a CI pin order
show up on the page of every repository whose CI pins it.

## CI

`.github/workflows/ci.yml` has two jobs: `lint` runs `markdownlint-cli2-action` on `**/*.md`, and
`mermaid` runs `scripts/check-mermaid.sh` with Node 22. A pull request that changes architecture needs
the `repos/`, `overview.md`, `design/` or ADR update and a `CHANGELOG.md` line in the same
piece of work.
To check a run, use `gh run list --limit 1`, and at most one `gh run watch <id> --exit-status`.
Do not poll in a loop.

## Pitfalls

- A spec that disagrees with the code is a bug in the spec. Read the repository's README and `.mli`
  files first; they win, and the spec is fixed in the same session.
- Commit one document per commit when several documents change, so each commit reads on its own.
- When the shared checkout holds other agents' uncommitted edits, commit only your own paths.
- ADRs are never renumbered or deleted. A reversed decision gets a new ADR and a
  "Superseded by" line on the old one.

## Where to read more

- `CLAUDE.md` (the rules for updating specs), `README.md` (navigation), `overview.md` (the layers).
- `../oxcaml-claude-skills/AGENTS.md`, the workspace guide, and its repository map.
- `../oxcaml-claude-skills/GOTCHAS.md` for the workspace's log of pitfalls.

## Never do

- Describe a repository's behaviour from memory. Check its files, or leave the claim out.
- Add a secret, a credential, a customer record or an unpublished account name to any document.
- Publish, tag or release. Do not edit another repository's files from here.
