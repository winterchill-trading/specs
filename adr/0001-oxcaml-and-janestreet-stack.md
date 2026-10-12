# ADR 0001: OxCaml and the Jane Street stack

Status: accepted

## Context

The organization builds latency-sensitive trading components (matching, market data,
market making) and wants strong static types for money (prices, sizes and USD amounts
that cannot be mixed up), deterministic tests, and one language from wire codecs to
servers. OCaml gives the types; the Jane Street libraries give a consistent standard
library (Core), a concurrency model (Async), derivations (ppx_jane) and test tooling
(ppx_expect, Base_quickcheck). OxCaml, Jane Street's branch of the compiler, adds modes
(`local_`, `exclave_`, `global_`) for stack allocation in hot loops.

## Decision

Every OCaml repository builds with the OxCaml `5.2.0+ox` switch from the `ox` opam
repository, uses `open! Core`, Async for I/O, an `.mli` per module, labelled arguments,
ppx_jane derivations, ppx_expect tests and Base_quickcheck properties. CI uses
`ocaml/setup-ocaml@v3` with `ocaml-variants.5.2.0+ox`.

## Consequences

- `order-book`'s matching loop stack-allocates per-order temporaries with OxCaml modes.
- The compiler builds from source (15 to 30 minutes); the `oxcaml-base` container image
  in `infra` and the setup-ocaml cache absorb that cost.
- Some libraries need OxCaml preview versions (ppx_expect, async_websocket) with their
  own quirks; `oxcaml-claude-skills/GOTCHAS.md` records them.
- Packages from outside the Jane Street ecosystem (cohttp-async, yojson, cryptokit, zstd)
  are used where Jane Street has no equivalent.
