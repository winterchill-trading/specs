# opam-repository

The organization's own opam repository: the one place our libraries are published. Users
add it next to the OxCaml repository and install our packages by name and version, with no
`opam pin`. Not an OCaml repository. The plan it implements is
[design/opam-publishing.md](../design/opam-publishing.md); the per-library audits it
takes commits from are in [research/opam-readiness](../research/opam-readiness/README.md).

| | |
| --- | --- |
| Repository | `winterchill-trading/opam-repository` |
| opam package | none (it holds opam package entries) |
| Add it | `opam repo add winterchill https://github.com/winterchill-trading/opam-repository.git` |
| Status | in progress: first wave of entries and CI in place |

## Layout

| Path | Purpose |
| --- | --- |
| `repo` | `opam-version: "2.0"` |
| `packages/<name>/<name>.<version>/opam` | One entry per package version |
| `scripts/check.sh` | `opam lint` on every entry plus the repository rules below |
| `ci/ci-deps.opam` | Third-party dependencies CI installs and caches through `ox-setup`; not a package entry |
| `.github/workflows/ci.yml` | `lint` and `install` jobs |

## Entries

| Package | Version | Source commit | OxCaml-only |
| --- | --- | --- | --- |
| `pg-async` | 0.1.0 | `65fda87` | no: also builds on upstream OCaml 5.2 with Jane Street v0.17 |
| `fixed-decimal` | 0.1.0 | `7efc3ae` | yes |
| `money` | 0.1.0 | `53e2d0f` | yes |
| `money-cli` | 0.1.0 | `53e2d0f` | yes |
| `ledger` | 0.1.0 | `e2822f9` | yes, through `money` |
| `venue-net` | 0.1.0 | `97fc083` | yes, through the Jane Street v0.18 previews |
| `parquet` | 0.1.0 | `b3141c1` | yes |

`order-book` is left out: it depends on `exchange-core`, which has no entry, and
`exchange-core`'s second package `exchange-core-engine` depends on `order-book` (see
[Common blockers](../design/opam-publishing.md#common-blockers)).

## Rules

- The library repositories are not tagged, so each `url` is a git URL with the full
  commit: `git+https://github.com/winterchill-trading/<repo>.git#<40-hex commit>`, the
  audited head from the library's audit page.
- Each entry is the dune-generated `<name>.opam` at that commit, minus the generated-file
  comment, plus the `url` section and bounds on our own packages
  (`{>= "0.1.0" & < "0.2~"}`). No `name`, `version` or `pin-depends`; `x-maintenance-intent`
  is kept.
- Packages are OxCaml-only unless marked; OxCaml-only ones depend on `oxcaml`.
- Semver; every package starts at `0.1.0`. Only our own packages, never a patched copy of
  someone else's. `main` is the published state.

## CI

- `lint`: `scripts/check.sh` with the distribution's `opam` (lint, `<name>.<version>`
  directories, semver versions, exact-commit urls, no `pin-depends`, an
  `x-maintenance-intent`).
- `install`: a fresh `5.2.0+ox` switch through the infra `ox-setup` action with
  `working-directory: ci` and no pins (the third-party dependencies are cached), then
  `opam repo add winterchill <copy of repo and packages/>`, `opam install --dry-run` and a
  real `opam install` of `pg-async`, `fixed-decimal` and `money`. `money-cli`, `ledger`,
  `venue-net` and `parquet` are installed one at a time in a step that reports failures
  without failing the job.
- Not yet: `--with-test` (PostgreSQL and DuckDB are not opam packages), `--with-doc`
  (`odoc` is not on the CI switch), `opam admin check --installability`, the upstream
  opam-ci-check lint.

## Depends on

Nothing at build time. Each entry points at a commit of its library repository; CI uses
the infra `ox-setup` action.

## Used by

Users of the libraries. No organization repository pins from it yet; their CI still pins
siblings from GitHub.
