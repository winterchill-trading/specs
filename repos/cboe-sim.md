# cboe-sim

A simulator of Cboe US equities and options matching units speaking BOE v2 order entry
and Multicast PITCH 2.X market data over TCP, on the venue-neutral
`exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/cboe-sim` |
| opam package | `cboe-sim` |
| Libraries | `cboe-sim` (module `Cboe_sim`), `cboe-sim.wire` (module `Cboe_wire`) |
| Binaries | `cboe-sim` (`-gateway-port` 9300, `-feed-port` 9301, `-http-port` 9302, `-symbols`, `-no-options`, `-noise`, `-noise-traders`, `-seed`, `-clock`, `-anchor-series`, `-anchor-fixed`, `-anchor-scaled` with `-anchor-norm`/`-anchor-from`/`-anchor-to`, `-anchor-half-life-ms`), `cboe-sim-cli` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Cboe_wire.Boe` | BOE v2 framing, session and in-scope application messages; prices with 4 implied decimals (`Price4`) |
| `Cboe_wire.Pitch` | Multicast PITCH 2.X messages and the Sequenced Unit Header over a TCP stream |
| `Cboe_wire.Pitch_book` | Order-by-order book rebuilt from PITCH (spin, then live), also used to serve spins |
| `Clock` | Session clock: real New York time, accelerated replay of a whole day, always open, or manual for tests |
| `Instruments` | A few US equities on unit 1 and SPY option series (OSI symbols) on unit 2 |
| `Anchoring` | Thin wrapper over `price-anchor`'s `Anchor`, one per anchored listing: series, fixed (with drift) or scaled recorded crypto references as a `Path`, pulled on the exchange clock (`step_clock:false`, `levels:0`) with `Market_sim.set_reference ~half_life`; `may_engage` is continuous core trading (free walk in the auction windows, LULD pauses and outside core hours), `last_trade` the venue's last print, `clamp` `Clamp.within_bands` on the LULD bands |
| `Venue` | BOE semantics over the engine: FOK, hidden and reserve orders, on-open and on-close orders uncrossed in auctions, and the PITCH events they produce |
| `Boe_session` | Per-member outbound store (sequences per matching unit, kept for replay) and the per-connection state machine |
| `Feed` | PITCH sequencing per unit, Time messages, displayed book for spins, TCP and JSON fan-out |
| `Net`, `Server` | Frame readers; BOE gateway, PITCH feed (spin then live) and the HTTP port with the `/ws` JSON feed |

Listings: AAPL, MSFT, NVDA, AMZN, SPY and the test symbol ZVZZT on unit 1; SPY options
expiring 2026-12-18 (strikes 590, 600, 610) on unit 2. The clock is `always-open`,
`real` (New York time, NYSE calendar) or `accelerated` (a whole day in about 16 minutes
at speed 60). Prices are synthetic, optionally anchored to a reference price
([design/price-anchor.md](../design/price-anchor.md#tradfi-simulators)). Fidelity against the BOE and PITCH summaries is
summarised in [design/simulators.md](../design/simulators.md#tradfi-simulators).

## Dependencies

- Depends on: `price-anchor`, `market-data`, `equities-core`, `exchange-core-engine`,
  `order-book`, `exchange-core`, `fixed-decimal`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`,
`equities-core`, `parquet`, `market-data`, `price-anchor`.

## Known gaps

- No multicast, A/B feeds, gap request proxy or spin server; one TCP stream with the
  spin at the start.
- The engine always prevents self-matches; PreventMatch `D` and `S` behave like `N`.
- Modify loses priority in the engine although BOE and PITCH ids stay the same.
- Auction executions are not settled in the engine's clearinghouse; no LULD reopening
  auction; the LULD reference (mean of the venue's own prints over five minutes) is
  recomputed on every check, not only on 1% moves.
- `-anchor-scaled` reads normalized event logs only; raw minute files need the venue
  clients' normalizers, which are not linked.
- Options trade on their own random walk, not linked to SPY.
- Return bitfield bytes 4-5 and the Logout and Order Modified layouts are not verified
  against Cboe.
