# cboe-sim

A simulator of Cboe US equities and options matching units speaking BOE v2 order entry
and Multicast PITCH 2.X market data over TCP, on the venue-neutral
`exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/cboe-sim` |
| opam package | `cboe-sim` |
| Libraries | `cboe-sim` (module `Cboe_sim`), `cboe-sim.wire` (module `Cboe_wire`) |
| Binaries | none yet |
| Status | in progress |

## Key modules

| Module | Purpose |
| --- | --- |
| `Cboe_wire.Boe` | BOE v2 framing, session and in-scope application messages; prices with 4 implied decimals (`Price4`) |
| `Cboe_wire.Pitch` | Multicast PITCH 2.X messages and the Sequenced Unit Header over a TCP stream |
| `Cboe_wire.Pitch_book` | Order-by-order book rebuilt from PITCH (spin, then live), also used to serve spins |
| `Clock` | Session clock: real New York time, accelerated replay of a whole day, always open, or manual for tests |
| `Instruments` | A few US equities on unit 1 and SPY option series (OSI symbols) on unit 2 |
| `Venue` | BOE semantics over the engine: FOK, hidden and reserve orders, on-open and on-close orders uncrossed in auctions, and the PITCH events they produce |

## Dependencies

- Depends on: `equities-core`, `exchange-core-engine`, `order-book`, `exchange-core`,
  `fixed-decimal`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`,
`equities-core`.

## Known gaps

- No server binary and no README yet.
