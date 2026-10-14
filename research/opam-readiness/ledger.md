# ledger: opam readiness

Kind: reference.

Audit of `ledger` against the checklist in [README.md](README.md), done on 2026-10-14 at
commit `e2822f9` of `winterchill-trading/ledger`.

## Purpose

A double-entry ledger in exact integer minor units, with two-phase holds, reversals,
idempotency keys and business-day closes, kept in an append-only, checksummed and
hash-chained Bin_prot journal file.

## Readiness

| # | Item | Status | Notes |
| --- | --- | --- | --- |
| 1 | Purpose and wording | done | README intro rewritten for outside readers ("banking demo" and the clearinghouse plan removed); the CLI's `demo` command is now `example`; a reference to another repository in `record.mli` removed; consumers appear once under "Used by". |
| 2 | opam metadata | done | Generated from `dune-project`: MIT, authors, maintainers, source, homepage, bug reports, documentation, tags, description; `oxcaml`, `ocaml >= 5.2.0 < 5.3~`, Jane Street `>= v0.18~preview.130.106+341 < v0.19~`, `cryptokit >= 1.16`, `expect_test_helpers_core :with-test`, `odoc :with-doc`; `x-maintenance-intent` from a template. `opam lint` passes. `money` is unbounded until it has a released version. |
| 3 | Versioning | done | `CHANGES.md` with `Unreleased` and `0.1.0`; README "Releasing" describes the dune-release flow after `money` and `fixed-decimal`. No tags. |
| 4 | API surface | done | `.mli` on every module, odoc on every public value (25 were missing); `doc/index.mld` is the overview with a worked example; `examples/quickstart.ml` is built and run in CI. Errors are `Or_error` throughout; `Journal.records` with `~keep_records:false` says that it raises if the file was damaged after opening. Every change kept signatures source compatible (new optional arguments and new functions only). |
| 5 | Portability | documented | No OxCaml-only construct in the library; see below. |
| 6 | Docs build | open | `odoc` is not on the switch (`dune build @doc`: "Program odoc not found"). The dry run plans `odoc.3.2.0+ox2`, `crunch`, `ptime` and removes the `oxcaml-odoc` guard. Not installed. |
| 7 | Tests and CI | done | `dune test` green; CI gained one step, `dune exec ./examples/quickstart.exe`. The four dependents (`payments-core`, `card-core`, `banking-provider`, `neobank-api`) build and pass their tests against the new code. |
| 8 | Known gaps | done | Five gaps fixed with tests (below); the remaining ones need a format or design decision. |

## Known gaps fixed

| Gap | Fix |
| --- | --- |
| Journal read whole into memory on open | `Framing.fold`/`fold_file` decode one frame at a time from a channel (checked equal to the in-memory decoder on every truncation and every flipped byte of a sample file). Opening, `read`, `replay` and the snapshot prefix check stream the file. `~keep_records:false` keeps only the folded state, and `Journal.records` then reads the file. `Journal.fold` streams a journal for reports; `ledger trial-balance`, `statement` and `verify` use it. |
| Hold expiry needs a timer or a day close | `Journal.next_expiry` (and `Balances.next_expiry`) says when the next open hold expires; `Journal.expire_holds_at t time` books the expiries due at `time`, so a caller schedules it on any clock. No Async in the API. |
| Refused keys kept forever | `?refusal_retention` on `create` and `open_`: a request after the window drops the old refusal and is processed as new; `close_day` and `forget_expired_refusals` drop all refusals past the window. A new `Refusals_forgotten` record keeps replay deterministic; the record digest moved and the old one stays readable (a journal from the old code is checked in and read by a test). |
| Errors before an entry exists not recorded | Builder refusals (unknown hold, malformed entry) are written as `Rejected` records under their key, so a retry gets the same answer. |
| Chain head not published | `Journal.chain_head` and `Chain_head` (`to_string`/`of_string` as `ledger-head-v1:<seq>:<length>:<sha256>`, `of_snapshot`, `of_file`, `verify`); `ledger verify` prints it and checks `-head`. Truncation and a consistent rewrite of the same length are both detected. |

Also fixed on the way: `Journal.open_account` for an account opened before the snapshot a
journal was reopened from raised instead of returning `Duplicate`.

Left open: memory still grows with the number of booked entries (idempotency needs them;
segment files with an on-disk key index are a format decision), `ledger camt053` reads all
records, statement matching against provider files needs its own design, and macOS `fsync`
does not flush the drive cache.

## OxCaml-only constructs

None in the library or the CLI: no modes, `local_`, `exclave_`, unboxed types, `or_null`,
`[@zero_alloc]`, `let mutable` or stack allocation. The OxCaml requirement comes entirely
from dependencies: the Jane Street `v0.18~preview` packages, and `money`, which needs
`fixed-decimal`. An upstream OCaml 5 build would need a Core v0.17 port (untested: the
library uses `Time_ns`, `Async_kernel.Time_source`, `Core_unix.lockf` and
`Binable.Of_binable_without_uuid`, all present in v0.17) and a `money` build without its
`fixed-decimal` conversions.

## Dependencies

| Package | Kind | Repository |
| --- | --- | --- |
| `oxcaml` | build | OxCaml (upstream has `action-required` only) |
| `ocaml` 5.2 (`ocaml-variants.5.2.0+ox`) | build | OxCaml |
| `dune` >= 3.17 | build | upstream (OxCaml ships `3.22.2+ox`) |
| `core`, `core_unix`, `async_kernel`, `ppx_jane` | build | OxCaml (`v0.18~preview`) |
| `cryptokit` >= 1.16 | build | upstream (`1.16.1` on our switch) |
| `money` | build | not published (GitHub pin) |
| `expect_test_helpers_core` | test | OxCaml (`v0.18~preview`) |
| `odoc` | doc | OxCaml (`3.2.0+ox2`) |

## Package names

`ledger` (library `ledger`, module `Ledger`, executable `ledger`). Free on
opam.ocaml.org and in the OxCaml repository on 2026-10-14, but generic; `ledger-journal`
or a prefixed name is the fallback if a reviewer objects. The CLI could move to a
`ledger-cli` package, but the library itself needs `core_unix` for the journal file, so a
split would not drop a dependency.

## Open questions

- Should the journal file format get its own versioned spec page (header, frame layout,
  digest list, chain head text form) before a first release, so other readers can be
  written?
- Should `Journal.records` default to `keep_records:false` in 1.0? Today it defaults to
  keeping them because dependents call `records` on every relay tick.
- Should refusals covered by a snapshot carry their own times (a snapshot format change),
  instead of counting from the snapshot's close?
- Is `ledger` too generic a name to claim first?

## Top blockers to publishing

1. `money` (and through it `fixed-decimal`) is not published, so `ledger` cannot be
   installed from any opam repository until both are.
2. There is no venue: upstream opam CI has no OxCaml compiler and our own opam repository
   (design/opam-publishing.md) does not exist yet.
3. `odoc` is not installed on the switch, so `dune build @doc` (including the new index
   page) has never run and the package cannot be released `--with-doc`.
