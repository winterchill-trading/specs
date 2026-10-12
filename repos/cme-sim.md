# cme-sim

A simulator of CME Globex futures speaking iLink 3 order entry and MDP 3.0 market data
(SBE) over TCP, on the venue-neutral `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/cme-sim` |
| opam package | `cme-sim` |
| Libraries | `cme-sim` (module `Cme_sim`), `cme-sim.wire` (module `Cme_sim_wire`) |
| Binaries | `cme-sim` (`-gateway-port` 4300, `-feed-port` 4301, `-http-port` 4302, `-noise`, `-symbols`, `-clock`, `-seed`, `-no-cancel-on-disconnect`, `-log-level`), `cme-sim-cli` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Cme_sim_wire.Sbe` | SBE primitives: little-endian fields, CME null values, `PRICE9`, message header, Simple Open Framing Header |
| `Cme_sim_wire.Ilink3` | iLink 3 (schema 8, version 5): FIXP session layer and in-scope application messages |
| `Cme_sim_wire.Mdp3` | MDP 3.0 (schema 1, version 13): packet header and in-scope templates; over TCP each packet is prefixed with a SOFH |
| `Cme_sim_wire.Mbp_book` | Market-by-price book as a consumer keeps it, and the incremental entries a publisher sends |
| `Products` | December 2026 ES, NQ, CL and GC futures with ticks and multipliers from `Equities_core.Tick_size` |
| `Venue` | CME order semantics over the engine: limit and protected market orders, Day, GTC, FAK, FOK, MinQty, DisplayQty, daily price limits, opening call auction, limit halts |
| `Session_handler` | Pure FIXP state machine per connection; sequencing kept per firm and session across reconnects |
| `Feed`, `Json_feed` | MDP 3.0 publisher (MBP 10 levels, trade summaries, snapshots on connect, settlement) and the same feed as JSON |
| `Session_clock` | `always-open`, `real` (the Globex week) or `accelerated` phases |
| `Server`, `Frame_io`, `Ilink_client` | Gateway, feed and HTTP listeners (`/`, `/ws`, `/admin/halt`); SOFH framing; a minimal iLink 3 client |

MDP templates are checked against CME's public schema version 13; decoders skip appended
fields by `BlockLength`. Prices are synthetic. Fidelity against the iLink 3 and MDP 3.0
summary is summarised in [design/simulators.md](../design/simulators.md#tradfi-simulators).

## Dependencies

- Depends on: `equities-core`, `exchange-core-engine`, `order-book`, `exchange-core`,
  `fixed-decimal`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`,
`equities-core`.

## Known gaps

- No spreads, implied prices, options, mass quotes, stops or good-till-date orders.
- No MBOFD/MBOLD books, recovery or instrument channels, or primary/backup.
- HMAC credentials are not checked; no credit controls or self-match prevention IDs.
- Replaces always lose queue priority.
- Auction trades are not cleared by the engine; holidays, trade date rolls and expiry are
  not modelled.
