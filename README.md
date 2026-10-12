# specs

Architecture and design documentation for the winterchill-trading organization: what each
repository does, how the repositories fit together, and why they are built the way they
are. Markdown only; no code lives here.

The audience is both people and coding agents working on the organization's repositories.
Documents are short, factual and written in the present tense. Every statement about a
repository is checked against that repository's `dune-project`, `*.opam`, `lib/*.mli`,
CI workflow and README at the time of writing.

## Navigating

| Path | Contents |
| --- | --- |
| [overview.md](overview.md) | The ecosystem on one page: layers, dependency graph, runtime data flow |
| [repos/](repos/) | One page per repository: purpose, libraries and binaries, key modules, dependencies, CI pin order, status, known gaps |
| [design/](design/) | Cross-repository designs: data platform, example queries, market making, simulators, price anchor, cloud sinks and replication, deployment |
| [adr/](adr/) | Architecture decision records, numbered |
| [postmortems/](postmortems/) | Blameless incident write-ups, from [TEMPLATE.md](postmortems/TEMPLATE.md) |
| [CHANGELOG.md](CHANGELOG.md) | One line per architecture change, by day |
| [roadmap.md](roadmap.md) | Done, in progress, next |
| [CLAUDE.md](CLAUDE.md) | How an agent uses and maintains this repository |

Start with [overview.md](overview.md), then the `repos/` page of the repository you are
about to change, then any `design/` document it links to.

## Conventions

- **One document per topic.** A repository gets one page under `repos/`; a design that
  spans repositories gets one page under `design/`. Link instead of repeating.
- **ADRs are numbered** `adr/NNNN-short-title.md`, never renumbered or deleted. Each has
  Context, Decision and Consequences. A reversed decision gets a new ADR that supersedes
  the old one, and the old one gets a "Superseded by" line.
- **Diagrams are Mermaid** fenced blocks (`mermaid`), so they render on GitHub and are
  reviewed as text. CI renders every block with mermaid-cli.
- **Status words** are `done`, `in progress` and `planned`, with the same meaning
  everywhere.
- **Names.** Repositories, opam packages and binaries are written as in their
  `dune-project` (`exchange-core-engine`), OCaml modules as in code (`Mm_core.Venue.S`).
- No person or company names other than the organization and the public projects and
  venues it builds on.

## Keeping specs current

Every new repository, and every pull request that changes architecture (a new
dependency edge, a public library or binary, an on-disk format, a wire protocol, a
deployment shape), updates `specs` in the same piece of work: the repository's
`repos/` page, the dependency graph in `overview.md`, and the relevant `design/` page or
a new ADR, and adds a line to `CHANGELOG.md`. A spec that disagrees with the code is a bug in the spec.

## CI

`markdownlint-cli2` (configuration in `.markdownlint-cli2.jsonc`) and
`scripts/check-mermaid.sh`, which renders every Mermaid block. Locally:

```sh
npx -y markdownlint-cli2 '**/*.md'
scripts/check-mermaid.sh
```
