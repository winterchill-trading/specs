# nyse-sim

A local simulator of an NYSE Pillar equities venue: Pillar Gateway binary order entry and
the XDP Integrated Feed over TCP, on the venue-neutral `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/nyse-sim` |
| opam package | `nyse-sim` |
| Libraries | `nyse-sim` (module `Nyse_sim`), `nyse-sim.wire` (module `Nyse_sim_wire`) |
| Binaries | none yet |
| Status | in progress |

## Key modules

| Module | Purpose |
| --- | --- |
| `Nyse_sim_wire.Pillar` | Pillar Stream Protocol session layer: framing, sequence numbers |
| `Nyse_sim_wire.Pillar_app` | Gateway application messages (orders, acks, execution reports, rejects); prices at scale 8, the units of `Exchange_core.Price` |
| `Nyse_sim_wire.Xdp` | XDP Integrated Feed packets and messages, little endian |
| `Listing` | Listed equities and their reference data |
| `Venue` | Pillar order semantics over `Exchange_core_engine.Exchange`: validation with `Equities_core.Order_types`, session, LULD bands and pauses, short sale restriction, opening and closing auctions |
| `Market_event` | What the venue publishes, in matching order |
| `Feed` | XDP publisher: sequence reset, time references, symbol mappings, heartbeats, refresh for late joiners; JSON subscribers get the same messages |

Multicast feeds are carried over TCP in the simulator.

## Dependencies

- Depends on: `equities-core`, `exchange-core-engine`, `order-book`, `exchange-core`,
  `fixed-decimal`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`,
`equities-core`.

## Known gaps

- No server binary yet: the venue, feed and codecs are libraries driven by tests.
- No JSON/HTTP and websocket surface for `market-data` live feeds and `market-maker` yet.
