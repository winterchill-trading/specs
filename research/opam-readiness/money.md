# money: opam readiness

Kind: reference.

Audit of `money` against the checklist in [README.md](README.md), done on 2026-10-14 at
commit `53e2d0f` of `winterchill-trading/money`.

## Purpose

Currencies, exact amounts in integer minor units, exact-rational exchange rates and fee
schedules, with no floats, named rounding modes and allocation that never loses a minor
unit.

## Readiness

| # | Item | Status | Notes |
| --- | --- | --- | --- |
| 1 | Purpose and wording | done | README rewritten for outside readers; "we pay / we charge" wording in `Fee` and `Rounding` replaced; consumers appear once under "Used by". |
| 2 | opam metadata | done | Generated from `dune-project`: MIT, authors, maintainers, source, homepage, bug reports, documentation, tags, description; `oxcaml`, `ocaml >= 5.2.0 < 5.3~`, Jane Street `>= v0.18~preview.130.106+341 < v0.19~`, `odoc :with-doc`, `x-maintenance-intent` from templates. The CLI moved to its own `money-cli` package so the library no longer pulls `core_unix`. `opam lint` passes on both files. `fixed-decimal` is unbounded until it has a released version. |
| 3 | Versioning | done | `CHANGES.md` with `Unreleased` and `0.1.0`; README "Releasing" describes the dune-release flow for both packages. No tags. |
| 4 | API surface | done | `.mli` on every module, odoc on every public value; new main module `Money` with an overview and example; `examples/quickstart.ml` is built and its output diffed by `dune test`. Raising functions (`of_string`, `add_exn`, `t_of_yojson`) have `Or_error` twins and say that they raise. `Fee.bps` is deprecated in favour of `Fee.bps_q`. |
| 5 | Portability | documented | Constructs below and in the README; no shim written. |
| 6 | Docs build | open | `odoc` is not on the switch (`dune build @doc`: "Program odoc not found"). The dry run plans `odoc.3.2.0+ox2`, `crunch`, `ptime` and removes the `oxcaml-odoc` guard. Not installed. |
| 7 | Tests and CI | done | `dune test` green; CI gained one step, `dune build @examples/runtest`. Every `Stable` digest pin unchanged; `Fee.Stable.V2` pinned. |
| 8 | Known gaps | done | Fractional basis points, allocation and the registry fixed with tests; remaining gaps need a design decision (see below). |

## Known gaps fixed

| Gap | Fix |
| --- | --- |
| Whole-number basis points only | `Amount.mul_bps_q` and `Fee.create ~bps_q` take a rational number of basis points (`0.5`, `1/3`). Sexp and JSON write `bps` as `150`, `0.5` or `1/3`, so old whole-bps data reads unchanged. `Fee.Stable.V1` keeps its digest and refuses to write fractional schedules; `Fee.Stable.V2` carries bps as text. The CLI takes `-bps 0.5`. |
| No amount splitting | `Amount.allocate ~ratios` (largest remainder method, ties to the earlier part, negative amounts mirror positive ones) and `Amount.split ~parts`. Properties: parts sum to the input, each part within one minor unit of its exact share, zero ratios get zero, every bumped part's remainder is at least every unbumped one's. |
| Global registry without locking | The registry is an immutable map plus a frozen flag in one `Stdlib.Atomic.t`: lock-free reads, compare-and-set writes, safe across domains. `Currency.freeze` stops new registrations (identical re-registrations still succeed); tested in its own test library so the freeze does not leak into other tests. |

Left open, needing a design decision: rational ratios for `allocate`, a rate table with
cross rates and staleness, and an upstream-OCaml build.

## OxCaml-only constructs

| Construct | Where | Upstream spelling |
| --- | --- | --- |
| `('a : immediate).` layout-polymorphic signature | `Amount.to_fixed_decimal`, `Amount.of_fixed_decimal` (interface) | none: upstream rejects `with type t = 'a` against an `[@@immediate]` abstract type; move both functions to a sub-library |
| `(type a : immediate)` locally abstract type | same two functions (implementation) | as above |
| `fixed-decimal` dependency | those two functions only | itself OxCaml-only (`type t : immediate`, `let mutable`, unboxed tuples) |

No `[@zero_alloc]`, `or_null`, `float#`, modes, `local_`, stack allocation or
`let mutable`. `Stdlib.Atomic` carries mode annotations on OxCaml but has the same API on
OCaml 5. `Binable.Of_binable_without_uuid [@alert "-legacy"]` exists in Core v0.17 too.
With the two conversions in a `money.fixed_decimal` sub-library, the core library would
need only a Core v0.17 port.

## Dependencies

| Package | Kind | Repository |
| --- | --- | --- |
| `oxcaml` | build | OxCaml (upstream has `action-required` only) |
| `ocaml` 5.2 (`ocaml-variants.5.2.0+ox`) | build | OxCaml |
| `dune` >= 3.17 | build | upstream (OxCaml ships `3.22.2+ox`) |
| `core`, `ppx_jane` | build | OxCaml (`v0.18~preview`) |
| `ppx_yojson_conv`, `ppx_yojson_conv_lib` | build | OxCaml (`v0.18~preview`) |
| `yojson` >= 2.0.0 | build | upstream (OxCaml ships `2.2.2+ox`) |
| `zarith` >= 1.12 | build | upstream (OxCaml ships `1.12+ox3`) |
| `fixed-decimal` | build | not published (GitHub pin) |
| `core_unix` | build, `money-cli` only | OxCaml (`v0.18~preview`) |
| `odoc` | doc | OxCaml (`3.2.0+ox2`) |

## Package names

`money` (library `money`, module `Money`) and `money-cli` (executable `money`). Both
names are free on opam.ocaml.org and in the OxCaml repository on 2026-10-14. `money` is
a very generic name for a first claim; `money` plus a qualifier is the fallback if a
reviewer objects.

## Open questions

- Should `to_fixed_decimal`/`of_fixed_decimal` move to a `money.fixed_decimal`
  sub-library, so the main library drops its only non-opam and only OxCaml-only
  dependency? It would be a breaking move for callers that use them.
- Should the registry stay process-global, or should parsing take an explicit registry
  value so two components can disagree on extra currencies?
- `Decimal_text` is public only because modules share it; hide it before 1.0?
- `Fee.Stable.V1` raises when asked to write a fractional schedule; should writers that
  still use V1 get a typed error instead?

## Top blockers to publishing

1. `fixed-decimal` is not published, so `money` cannot be installed from any opam
   repository until it is (or until the conversions move to a sub-library).
2. There is no venue: upstream opam CI has no OxCaml compiler and our own opam repository
   (design/opam-publishing.md) does not exist yet.
3. `odoc` is not installed on the switch, so `dune build @doc` has never run and the
   package cannot be released `--with-doc`.
