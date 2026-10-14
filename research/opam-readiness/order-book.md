# Opam readiness: order-book

Kind: reference.

Audit of `winterchill-trading/order-book` against the checklist in
[README.md](README.md), on 2026-10-14. Nothing is published, tagged or released.

## Purpose

A deterministic, allocation-conscious limit order book for one instrument, with
price-time priority matching, three self-trade prevention policies and O(1) cancel, for
OxCaml.

## Readiness

| # | Item | State | Notes |
| --- | --- | --- | --- |
| 1 | Purpose and wording | done | README and odoc describe the library on its own terms; the self-trade table no longer names internal simulators; internal users appear once under "Used by". |
| 2 | opam metadata | done | Generated from `dune-project`: MIT, authors `WinterChill AI`, maintainer `hello@winterchill.xyz`, source, homepage, bug reports, documentation, synopsis, description, tags. Depends on `oxcaml`, `ocaml >= 5.2.0 & < 5.3~`, Core and `ppx_jane` `>= v0.18~preview.130.106+341 & < v0.19~`, test-only `core_bench`/`core_unix`, `odoc {with-doc}`; `x-maintenance-intent` through `order-book.opam.template`. `opam lint` passes. `fixed-decimal` and `exchange-core` carry no bounds: neither has a version yet. |
| 3 | Versioning | done | `CHANGES.md` with `## Unreleased` and a `0.1.0` entry; "Releasing" in the README describes the `dune-release` flow. No tags. |
| 4 | API surface | done | `.mli` for both modules; odoc on every value, `@param` on `add_limit`, the raising cases stated; module doc with a worked example; `examples/quickstart.ml` is compiled and its output checked by `dune test` and run in CI. Interfaces no longer `open! Exchange_core`. Errors are documented exceptions (see open questions). No serialized types, so no stable types are needed. |
| 5 | Portability | done (documented) | OxCaml-only; see below. No shim, by design. |
| 6 | Docs build | open | `odoc` is not on the switch. `opam install --dry-run odoc` plans `odoc.3.2.0+ox2`, `crunch`, `ptime` and removes the `oxcaml-odoc` guard; compiler and Core untouched. Not installed here; `dune build @doc` is unverified. |
| 7 | Tests and CI | done | `dune build @all @runtest` green locally and in CI; CI gained one step, `dune exec examples/quickstart.exe`. Dependents (`exchange-core`, six simulators, `price-anchor`) build unchanged. |
| 8 | Known gaps | done | Two fixed (below); the rest need a decision and are explained in the README. |

Fixed in this audit:

- `mid_or_null` now carries `[@@zero_alloc]`; it was blocked until `fixed-decimal`
  annotated `Price.of_units`. The check is live: an allocation added to its body fails the
  build.
- `l2 ~n_levels` with a negative count raised `Failure "Sequence.take"`; it now returns two
  empty lists, with a test.

## OxCaml-only constructs

| Construct | Where | Plain OCaml 5.x |
| --- | --- | --- |
| `'a or_null`, `Null`, `This` | public: `best_bid_or_null`, `best_ask_or_null`, `mid_or_null`; private: level links (`prev`, `next`, `head`, `tail`) | does not parse; a variant `Null \| This of 'a` keeps sources, boxes `This` |
| `[@@zero_alloc]` | the three `_or_null` values in the `.mli` | ignored attribute; no shim |
| `local_` | `execute` (`let local_ taker`), `sweep` parameter | does not parse; erase |
| `exclave_` | every return of `sweep` | does not parse; erase |
| `global_` fields | private records `taker`, `swept` | does not parse; erase |
| `@ local` | `iter ~f` in the `.mli`; `Level.iter`, `iter` | does not parse; erase |
| `let mutable` | `Level.iter` loop | does not parse; a non-escaping `ref` |
| `[@nontail]` | the final `Map.iter` in `iter` | ignored attribute |

There are no unboxed types (`float#`, unboxed tuples, `[@unboxed]` records), no uniqueness
or `borrow_`, no stack allocation beyond `local_`, and no `Stdlib_upstream_compatible`.

A plain OCaml build would need a second, mode-free `order_book.ml` and `.mli` with a
compatibility `or_null`, chosen by a dune `select` on `stdlib_upstream_compatible`, plus
the same treatment in `fixed-decimal` (`let mutable`, an unboxed tuple, `type t :
immediate`) and a Core v0.17 port. That matches the plan's verdict in
[design/opam-publishing.md](../../design/opam-publishing.md): `order-book` stays
OxCaml-only. The public `or_null` queries would also make a dual build expose two
different APIs.

## Dependencies

| Dependency | Use | Version on our switch | opam repository |
| --- | --- | --- | --- |
| `oxcaml` | compiler signal | `latest` | OxCaml (upstream has `action-required` only) |
| `ocaml` | compiler | `5.2.0` via `ocaml-variants.5.2.0+ox` | OxCaml |
| `dune` | build | `3.22.2+ox` | OxCaml (upstream also has dune) |
| `core` | library | `v0.18~preview.130.106+341` | OxCaml only |
| `ppx_jane` | preprocessing | `v0.18~preview.130.106+341` | OxCaml only |
| `fixed-decimal` | prices and sizes | unversioned | none yet: GitHub pin |
| `exchange-core` | ids, sides, TIF, `L2.Level` | unversioned | none yet: GitHub pin |
| `core_bench` | tests (benchmark) | `v0.18~preview.130.106+341` | OxCaml only |
| `core_unix` | tests (benchmark command) | `v0.18~preview.130.106+341` | OxCaml only |
| `odoc` | docs | not installed (`3.2.0+ox2` planned) | OxCaml |

From `exchange-core` the library uses only `Order_id`, `Account`, `Side`, `Price`, `Size`,
`Client_order_id`, `Symbol`, `Tif`, `Trade_id` and `L2.Level`.

## Package name

`order-book` (library `order-book`, module `Order_book`), as the plan keeps it. Free on
opam.ocaml.org and in the OxCaml repository on 2026-10-14.

## Open questions

- Publish all of `exchange-core` first, or split the ten primitive modules above into a
  small package that both `exchange-core` and `order-book` depend on? `exchange-core` is
  large and simulator-shaped, and its second package `exchange-core-engine` depends on
  `order-book`, so the two repositories release in lockstep today.
- Add `Or_error`-returning variants of `add_limit` and `market`, or keep documented
  exceptions for invalid input that callers validate anyway?
- Switch client order ids in `Fill.t` and `Resting_order.t` to `or_null` before 0.1.0,
  while breaking the record types costs nothing outside the organization?
- Self-trade prevention and amend policies differ per venue; should `amend` arrive with a
  priority policy type alongside `Stp.t`?

## Top blockers

1. `exchange-core` is unpublished, large and tied to `order-book` through
   `exchange-core-engine`; `order-book` cannot be released until it is, or until the
   primitives it uses become their own package.
2. `fixed-decimal` must be released first (tier 1), after which `order-book` needs real
   lower bounds on both sibling packages.
3. There is no opam repository to release into yet (`winterchill-trading/opam-repository`
   is planned, not created), and the docs build is unverified because `odoc` is not
   installed on the switch.
