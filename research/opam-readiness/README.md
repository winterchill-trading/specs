# Opam readiness

Kind: reference.

Findings on publishing OxCaml-only libraries through opam, the audit process every
general-purpose library goes through before release, and an index of the per-library audit
pages. The plan built on these findings is [design/opam-publishing.md](../../design/opam-publishing.md).
Nothing is published: no package, tag, GitHub release or pull request to any opam repository
exists or is made by this work.

Facts were read on 2026-10-14 from the sources listed under [Sources](#sources), cited by
title. Claims marked "verified" were reproduced on our machines: the `5.2.0+ox` switch
(compiler `ocaml-variants.5.2.0+ox`, `oxcaml-compiler.5.2.0minus39`, `oxcaml.latest`, Core
`v0.18~preview.130.106+341`) and an upstream switch with `ocaml-base-compiler.5.2.0` and
Core `v0.17.2`.

## Key findings

1. **Upstream opam-repository cannot carry OxCaml-only packages today.** Its CI builds every
   submission on upstream compilers only (4.11, 4.14 and 5.2 to 5.5 variants, across many
   distributions and five architectures; no OxCaml entry in the platform list). The
   archiving policy keeps a version only while it is "installable on at least one of the
   supported platforms" with a compiler at or above the cutoff (4.11 on 2026-05-05).
2. **There is a sanctioned way to name the OxCaml dependency, but no policy for releasing
   on it.** Since 2026-04-30 upstream carries `oxcaml.action-required`, a virtual package
   whose build always fails with a message telling the user to add the OxCaml repository.
   The OxCaml repository overrides it with `oxcaml.latest` and `oxcaml.archived`
   (`action-required` < `archived` < `latest`, so upgrades are quiet). The pull request
   that added it says plainly that it is not settled whether packages depending on OxCaml
   should be released upstream. A GitHub code search of ocaml/opam-repository on
   2026-10-14 finds no package depending on `oxcaml` besides the virtual package itself.
3. **Even our syntax-clean libraries are OxCaml-only, because of Core.** Our libraries build
   against Core and Async `v0.18~preview.*`, which exist only in the OxCaml repository;
   upstream stops at `core.v0.17.2`. Verified: `kyc-core`, which uses no OxCaml syntax,
   fails on upstream OCaml 5.2.0 with Core v0.17.2 (`String_id.make` is unbound;
   `quickcheck_observer` is missing on `Date.Stable.V1`). A dual build therefore needs a
   Core v0.17 port as well as syntax shims.
4. **The OxCaml repository is not a place for third-party libraries.** It holds the
   compiler (`ocaml-variants`, `oxcaml-compiler`, the `oxcaml` signal package), the Core
   and Async family at `v0.18~preview.*`, and patched third-party packages as
   `oxcaml-<name>` plus `oxcaml-<name>-patches` pairs (554 package directories in our
   clone). It has no contribution guide. The issue "How to publish an opam repository that
   depends on oxcaml" was answered with "add `oxcaml` to your `depends`", leaving the
   release venue open. We should not ask it to carry ours.
5. **Our own opam repository is the practical path.** An opam repository is a git tree of
   `packages/<name>/<name>.<version>/opam` plus a `repo` file; users add it next to the
   OxCaml one with `opam repo add`. `dune-release opam submit` takes `--opam-repo
   OWNER/REPO` ("Use this to release to a custom repo") and `opam publish` takes `--repo`,
   `--target-branch`, `--dry-run` and `--output-patch`, so the standard tools target it.
6. **Dual builds work with a dune `select` on a compiler-shipped library.**
   `stdlib_upstream_compatible` is installed with the OxCaml compiler and absent upstream.
   Verified on both switches: a library with
   `(select impl.ml from (stdlib_upstream_compatible -> impl.ox.ml) (-> impl.upstream.ml))`
   builds and runs on each, picking the matching file. `[@zero_alloc]` and `[@@zero_alloc]`
   are plain attributes that upstream OCaml ignores, so they need no shim; a non-escaping
   `ref` passes the `[@zero_alloc]` check on OxCaml (verified), so `let mutable` can often
   become a local `ref` in shared code with no allocation cost.
7. **Some OxCaml constructs have no upstream spelling.** `type t : immediate` becomes
   `type t [@@immediate]` (accepted by both), but a layout-polymorphic signature such as
   `('a : immediate). (module S with type t = 'a) -> ...` does not: upstream rejects
   `with type t = 'a` against an `[@@immediate]` abstract type (verified on `money`).
   `or_null`, `exclave_`, `@ local`, `float#` and unboxed products need a second
   implementation file, not a rewrite.
8. **ocaml.org will not host our docs.** Package documentation on ocaml.org is built by
   the docs CI from opam-repository metadata, so packages outside upstream get none.
   `dune-release` stopped publishing docs to GitHub Pages in 2.1.0 for the same reason
   (it relies on ocaml.org). We host `dune build @doc` output ourselves. `odoc` is not on
   our switch; `opam install --dry-run odoc` plans `odoc.3.2.0+ox2` from the OxCaml
   repository plus `crunch` and `ptime`, removes the `oxcaml-odoc` guard and leaves the
   compiler and Core alone.
9. **Every candidate name is free.** None of `pg-async`, `fixed-decimal`, `money`,
   `ledger`, `order-book`, `venue-net`, `parquet`, `payments-core`, `kyc-core`,
   `card-core`, `risk-rules`, `banking-provider` (nor their underscore forms) exists on
   opam.ocaml.org or in the OxCaml repository on 2026-10-14. Close neighbours: `decimal`
   (upstream), `bigdecimal` and `postgres_async` (OxCaml repository), `postgresql`, `pgx`
   and `pgx_async` (upstream). The upstream lint treats `-` and `_` as the same character
   when it checks for collisions.

## Upstream lint rules that apply to us

The opam-repository CI lint (opam-ci-check) rejects or warns on, among others:

- `pin-depends` and `extra-files` (use `extra-source`), and weak checksums (use SHA-256 or
  SHA-512);
- `dune subst` without `{dev}`, and `dune` marked `{build}`;
- a `name` or `version` field that disagrees with the directory;
- a maintainer with no contact address;
- a name that collides with an existing one ignoring case, `-` and `_`;
- restricted name prefixes tied to conflict classes (`arch-`, `host-arch-`,
  `host-system-`, `system-`, `ocaml-env-mingw`, `ocaml-env-msvc`);
- archived versions without upper bounds on their dependencies.

The archiving policy reads `x-maintenance-intent` (for example `["(latest)"]`, as Core
declares) to decide which old versions stay. Generated opam files from dune already avoid
most of these; our own repository's CI should run the same checks so a later move upstream
costs nothing.

## Audit process

Each general-purpose library gets an audit page `<library>.md` in this directory, written
by the agent that owns the library, against one checklist:

1. Purpose and wording: README, odoc and opam text describe the library on its own terms;
   internal consumers appear once, under "Used by".
2. opam metadata generated from `dune-project`: license, authors, maintainers, source,
   homepage, bug reports, documentation, synopsis, description, exact bounds,
   `:with-test` and `:with-doc` markers.
3. Versioning: `CHANGES.md` with `## Unreleased` and a `0.1.0` entry; a "Releasing"
   section in the README. No tags.
4. API surface: `.mli` and odoc on every public value, a compiled example under
   `examples/`, consistent naming, `Or_error` or `Result` for errors, stable types apart.
5. Portability: every OxCaml-only construct listed, with the shim a plain OCaml 5 build
   would need, and the dependencies that exist only in the OxCaml repository.
6. Docs build: `dune build @doc` without warnings.
7. Tests and CI green; CI changed only to build the examples.
8. Known gaps fixed where bounded, explained where not.

Each page has: purpose in one sentence, a readiness table (done, open, not applicable)
per item, OxCaml-only constructs, a dependency table with the opam repository each
dependency comes from, suggested package names, open questions and the top three
blockers.

## Audits

| Library | Tier in the plan | Audit |
| --- | --- | --- |
| `fixed-decimal` | 1 | [fixed-decimal.md](fixed-decimal.md) |
| `pg-async` | 1 | pending |
| `money` | 1 | pending |
| `ledger` | 2 | pending |
| `order-book` | 2 | [order-book.md](order-book.md) |
| `venue-net` | 2 | pending |
| `parquet` | 2 | pending |
| `payments-core`, `kyc-core`, `card-core`, `risk-rules`, `banking-provider` | 3 | pending |

An audit replaces "pending" with a link to its page.

## Sources

- "Contributing to the OCaml opam repository" (ocaml/opam-repository, `CONTRIBUTING.md`).
- "opam Repository Archiving Policy" (ocaml/opam-repository,
  `governance/policies/archiving.md`).
- "Platforms Tested on the Opam Repository CI" (opam-repo-ci, `doc/platforms.md`).
- opam-ci-check lint sources (opam-repo-ci, `opam-ci-check/lint/`).
- "RFC: add a virtual package for OxCaml dependency" (ocaml/opam-repository pull request
  29809, merged 2026-04-30) and the package `oxcaml.action-required`.
- "OPAM repository for OxCaml" (oxcaml/opam-repository, `README.md`) and the opam files of
  `ocaml-variants`, `oxcaml`, `oxcaml-compiler` and `core` in that repository.
- "How to publish an opam repository that depends on oxcaml" (oxcaml/opam-repository
  issue 35).
- "dune-release: release dune packages in opam" (README, `CHANGES.md` entry for 2.1.0,
  and `bin/cli.ml` for `--opam-repo`).
- "opam-publish" (README and `src/publishMain.ml` for `--repo`).
- "Docs CI" (ocaml-docs-ci, `README.md`).
- The opam manual, sections on repositories, `available`, `conflict-class` and version
  ordering.
