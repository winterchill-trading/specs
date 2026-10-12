# cme-sim

A simulator of CME Globex futures speaking iLink 3 order entry and MDP 3.0 market data
(SBE) over TCP, on the venue-neutral `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/cme-sim` |
| opam package | `cme-sim` |
| Libraries | `cme-sim` (module `Cme_sim`), `cme-sim.wire` (module `Cme_sim_wire`) |
| Binaries | `cme-sim` (`-gateway-port` 4300, `-feed-port` 4301, `-http-port` 4302, `-noise`, `-symbols`, `-clock`, `-seed`, `-no-cancel-on-disconnect`, `-log-level`, `-anchor-series`, `-anchor-fixed`, `-anchor-scaled`, `-anchor-norm`, `-anchor-from`, `-anchor-to`, `-anchor-half-life-ms`), `cme-sim-cli` |
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
| `Anchoring` | Thin wrapper over `price-anchor`'s `Anchor`, one per anchored product: series, fixed (with drift) or scaled recorded references as a `Path`, pulled on the venue clock (`step_clock:false`, `levels:0`, no mark interval) with `Market_sim.set_reference ~half_life` before each noise tick; `may_engage` is the product's `Open` phase (free walk in pre-open, limit halts and maintenance), `last_trade` the venue's last price (where the walk restarts at the open), `clamp` `Clamp.within_bands` on the daily price limits (30 bps inside) |
| `Server`, `Frame_io`, `Ilink_client` | Gateway, feed and HTTP listeners (`/`, `/ws`, `/anchors`, `/admin/halt`); SOFH framing; a minimal iLink 3 client |

MDP templates are checked against CME's public schema version 13; decoders skip appended
fields by `BlockLength`. Prices are synthetic. Fidelity against the iLink 3 and MDP 3.0
summary is summarised in [design/simulators.md](../design/simulators.md#tradfi-simulators).

## Dependencies

- Depends on: `price-anchor`, `market-data`, `equities-core`, `exchange-core-engine`,
  `order-book`, `exchange-core`, `fixed-decimal`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`,
`equities-core`, `parquet`, `market-data`, `price-anchor`.

## Known gaps

- No spreads, implied prices, options, mass quotes, stops or good-till-date orders.
- No MBOFD/MBOLD books, recovery or instrument channels, or primary/backup.
- HMAC credentials are not checked; no credit controls or self-match prevention IDs.
- Replaces always lose queue priority.
- The anchor's scaled reference reads normalized event logs, not raw minute files (a
  venue normalizer would link a venue client into the simulator).
- Auction trades are not cleared by the engine; holidays, trade date rolls and expiry are
  not modelled.
