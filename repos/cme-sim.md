# cme-sim

A simulator of CME Globex futures speaking iLink 3 order entry and MDP 3.0 market data
(SBE) over TCP, on the venue-neutral `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/cme-sim` |
| opam package | `cme-sim` |
| Libraries | `cme-sim` (module `Cme_sim`), `cme-sim.wire` (module `Cme_sim_wire`) |
| Binaries | none yet |
| Status | in progress |

## Key modules

| Module | Purpose |
| --- | --- |
| `Cme_sim_wire.Sbe` | SBE primitives: little-endian fields, CME null values, `PRICE9`, message header, Simple Open Framing Header |
| `Cme_sim_wire.Ilink3` | iLink 3 (schema 8, version 5): FIXP session layer and in-scope application messages |
| `Cme_sim_wire.Mdp3` | MDP 3.0 (schema 1, version 13): packet header and in-scope templates; over TCP each packet is prefixed with a SOFH |
| `Cme_sim_wire.Mbp_book` | Market-by-price book as a consumer keeps it, and the incremental entries a publisher sends |
| `Products` | December 2026 ES, NQ, CL and GC futures with ticks and multipliers from `Equities_core.Tick_size` |

## Dependencies

- Depends on: `equities-core`, `exchange-core-engine`, `order-book`, `exchange-core`,
  `fixed-decimal`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`,
`equities-core`.

## Known gaps

- Only the codecs and the product list exist: no venue module, server binary or README
  yet.
