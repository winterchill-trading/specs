# fixed-decimal: opam readiness

Kind: reference.

Audit of `fixed-decimal` against the checklist in [README.md](README.md), done on
2026-10-14 at commit `7efc3ae` of `winterchill-trading/fixed-decimal`.

## Purpose

Exact fixed-point decimals with 8 fractional digits, stored as an immediate `int`, with a
generative functor that gives prices, sizes and amounts distinct types.

## Readiness

| # | Item | Status | Notes |
| --- | --- | --- | --- |
| 1 | Purpose and wording | done | README rewritten for outside readers; consumers appear once under "Used by". The mli and opam text name no internal project. |
| 2 | opam metadata | done | Generated from `dune-project`: MIT, authors, maintainers, source, homepage, bug reports, documentation, tags, description; `oxcaml`, `ocaml >= 5.2.0 < 5.3~`, Jane Street `>= v0.18~preview.130.106+341 < v0.19~`, `:with-test`, `odoc :with-doc`, `x-maintenance-intent` from a template. `opam lint` passes. |
| 3 | Versioning | done | `CHANGES.md` with `Unreleased` and `0.1.0`; README "Releasing" describes the dune-release flow. No tags. |
| 4 | API surface | done | One module with an `.mli`; odoc on every public value; module doc carries a worked example that `examples/notional.ml` builds and `dune test` checks. New `of_string_or_error`, `of_string_exact`, `div_or_error` give `Or_error` forms of the raising functions. |
| 5 | Portability | documented | OxCaml-only constructs listed below and in the README; no shim written. |
| 6 | Docs build | open | `odoc` is not on the switch; the dry run plans `odoc.3.2.0+ox2`, `crunch`, `ptime` and removes the `oxcaml-odoc` guard. Not installed. Warning 50 (misplaced docstrings) is clean. |
| 7 | Tests and CI | done | `dune test` green; CI gained one step that runs the example. Allocation pins and benches untouched. |
| 8 | Known gaps | done | Exact parsing and round-to-nearest `mul`/`div` added with zarith property tests; the range and the fixed scale stay open as design decisions. |

## OxCaml-only constructs

| Construct | Where | Upstream spelling |
| --- | --- | --- |
| `type t : immediate` | `S.t` in the interface | `type t [@@immediate]` |
| `[@@zero_alloc]`, `[@zero_alloc]` | interface and hot functions | ignored upstream; no shim |
| `let mutable` | parser, printer, long division | local `ref` |
| unboxed tuple `#(n, f)` | `frac_digits` (printer) | boxed pair or two functions |
| `[@cold]` | error paths | ignored upstream |

No `or_null`, `float#`, modes, `local_` or stack allocation. A plain OCaml 5 build would
need the five rewrites above and a Core v0.17 port; the public interface itself only
needs the layout annotation spelled `[@@immediate]`.

## Dependencies

| Package | Kind | Repository |
| --- | --- | --- |
| `oxcaml` | build | OxCaml (upstream has `action-required` only) |
| `ocaml` 5.2 (`ocaml-variants.5.2.0+ox`) | build | OxCaml |
| `dune` >= 3.17 | build | upstream (OxCaml ships `3.22.2+ox`) |
| `core`, `ppx_jane` | build | OxCaml (`v0.18~preview`) |
| `ppx_yojson_conv`, `ppx_yojson_conv_lib` | build | OxCaml (`v0.18~preview`) |
| `yojson` >= 2.0.0 | build | upstream (OxCaml ships `2.2.2+ox`) |
| `zarith` >= 1.12 | test | upstream (OxCaml ships `1.12+ox3`) |
| `core_bench`, `core_unix` | test (benchmark) | OxCaml (`v0.18~preview`) |
| `odoc` | doc | OxCaml (`3.2.0+ox2`) |

## Package name

`fixed-decimal` (library `fixed-decimal`, module `Fixed_decimal`). The name is free on
opam.ocaml.org and in the OxCaml repository; the nearest neighbours are `decimal`
(arbitrary precision, upstream) and `bigdecimal` (OxCaml repository).

## Open questions

- Should the yojson converters move to a separate `fixed-decimal.yojson` sub-library, so a
  user who only wants sexp does not pull yojson and its ppx?
- Is 8 fractional digits the right fixed scale for a public library, or should a
  per-instance scale come before 1.0?
- `of_int` and `+` wrap around on overflow like `int`; a checked variant may be expected by
  outside users.

## Top blockers to publishing

1. There is no venue yet: upstream opam CI has no OxCaml compiler, and our own opam
   repository (design/opam-publishing.md) does not exist.
2. `odoc` is not installed on the switch, so `dune build @doc` has never run and the
   package cannot be released `--with-doc`.
3. Core and the ppx stack are `v0.18~preview` packages from the OxCaml repository, so the
   package is OxCaml-only until a Core v0.17 port and syntax shims exist.
