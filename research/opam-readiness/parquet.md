# parquet: opam readiness

Kind: reference.

Audit of `parquet` against the checklist in [README.md](README.md), done on 2026-10-14 at
commit `b3141c1` of `winterchill-trading/parquet`.

## Purpose

Write and read Apache Parquet files from OCaml with no Arrow or C++ dependency: typed column
combinators over a row type, a streaming writer and a reader for flat schemas.

## Readiness

| # | Item | Status | Notes |
| --- | --- | --- | --- |
| 1 | Purpose and wording | done | README rewritten for outside readers; consumers appear once under "Used by". mli and opam text name no internal project. |
| 2 | opam metadata | done | Generated from `dune-project`: MIT, authors, maintainers, source, homepage, bug reports, documentation, tags, description; `oxcaml`, `ocaml >= 5.2.0 < 5.3~`, Jane Street `>= v0.18~preview.130.106+341 < v0.19~`, `zstd >= 0.4`, `:with-test`, `odoc :with-doc`, `x-maintenance-intent` from a template. `opam lint` passes. |
| 3 | Versioning | done | `CHANGES.md` with `Unreleased` and `0.1.0`; README "Releasing" describes the dune-release flow. The footer's `created_by` takes its version from `dune subst`. No tags. |
| 4 | API surface | done | `.mli` on every module; odoc on every public value; a hand-written `Parquet` main module carries the module doc and worked example, which `examples/trades.ml` builds and CI runs. Reader errors are `Or_error`; writer errors raise and are documented with `@raise`. |
| 5 | Portability | documented | Two `float#` entry points; listed below and in the README. No shim written. |
| 6 | Docs build | open | `odoc` is not on the switch; the dry run plans `odoc.3.2.0+ox2`, `crunch`, `ptime`, `oxcaml-odoc-patches` and removes the `oxcaml-odoc` guard. Not installed, so `dune build @doc` has not run. |
| 7 | Tests and CI | done | `dune test` green; DuckDB-oracle tests, allocation pins and benches kept. CI gained one step that runs the example. |
| 8 | Known gaps | done | Optional columns, dictionary encoding, key-value metadata and a reader (v1/v2 pages, DELTA, BYTE_STREAM_SPLIT, snappy, lz4_raw) added, each checked against DuckDB. Left open with reasons: nested columns, multi-page chunks, writer-side format 2 features, gzip/brotli, encryption. |

## OxCaml-only constructs

| Construct | Where | Upstream spelling |
| --- | --- | --- |
| `float#` | `Writer.Direct.add_float_u`, `Byte_buf.add_double_u_le` | none; drop the two functions |
| `%box_float` / `%unbox_float` externals | `lib/writer.ml`, `lib/byte_buf.ml` | not needed without the above |
| `[@cold]`, `[@inline]`, `[@inline never]` | error paths, hot appends | accepted upstream |

No modes, `local_`, `or_null`, `[@zero_alloc]`, `let mutable` or unboxed records. A
plain OCaml 5 build needs the two `_u` functions behind a dune `select` on
`stdlib_upstream_compatible` and a Core v0.17 port.

## Dependencies

| Package | Kind | Repository |
| --- | --- | --- |
| `oxcaml` | build | OxCaml (upstream has `action-required` only) |
| `ocaml` 5.2 (`ocaml-variants.5.2.0+ox`) | build | OxCaml |
| `dune` >= 3.17 | build | upstream (OxCaml ships `3.22.2+ox`) |
| `core`, `ppx_jane` | build | OxCaml (`v0.18~preview`) |
| `zstd` >= 0.4 (ctypes, libzstd) | build | upstream |
| `core_unix` | test | OxCaml (`v0.18~preview`) |
| DuckDB CLI 1.5.6 | test | not an opam package; tests fail without it |
| `odoc` | doc | OxCaml (`3.2.0+ox2`) |

## Package name

`parquet` (library `parquet`, module `Parquet`). No package of that name in the
upstream or OxCaml repositories on our switch; the nearest neighbour upstream is `arrow`,
which binds the C++ Arrow library.

## Open questions

- The tests need the DuckDB CLI, which opam cannot install. Should the oracle tests move to
  a separate alias (run in CI, skipped by `opam install --with-test`), with only the
  self-contained round trips in `@runtest`?
- Should the low-level modules (`Metadata`, `Thrift_compact`, `Rle_hybrid`, `Delta`,
  `Decompress`, `Byte_buf`, `Zstd_bytes`) stay public? Their records grow with the
  format, which makes every addition a breaking change; a `parquet.format` sub-library
  would separate them from the stable `Schema`/`Writer`/`Reader` surface.
- `Reader.Value.Int` rejects INT64 values outside the 63-bit `int` range; an `Int64`
  constructor may be expected by outside users.

## Top blockers to publishing

1. There is no venue yet: upstream opam CI has no OxCaml compiler, and our own opam
   repository (design/opam-publishing.md) does not exist.
2. `dune test` depends on the DuckDB CLI, which is not an opam package, so
   `opam install --with-test` fails on a clean machine.
3. `odoc` is not installed on the switch, so `dune build @doc` has never run; and Core,
   `ppx_jane` and `core_unix` are `v0.18~preview` packages from the OxCaml repository,
   so the package is OxCaml-only until a Core v0.17 port and the `float#` shim exist.
