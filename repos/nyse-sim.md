# nyse-sim

A local simulator of an NYSE Pillar equities venue: Pillar Gateway binary order entry and
the XDP Integrated Feed over TCP, on the venue-neutral `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/nyse-sim` |
| opam package | `nyse-sim` |
| Libraries | `nyse-sim` (module `Nyse_sim`), `nyse-sim.wire` (module `Nyse_sim_wire`) |
| Binaries | `nyse-sim` (`-gateway-port` 4100, `-feed-port` 4101, `-http-port` 4102, `-symbols`, `-noise`, `-clock`, `-start-time`, `-speed`, `-anchor-series`, `-anchor-fixed`, `-anchor-scaled` with `-anchor-norm`/`-anchor-from`/`-anchor-to`, `-anchor-half-life-ms`), `nyse-sim-cli` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Nyse_sim_wire.Pillar` | Pillar Stream Protocol session layer: framing, sequence numbers |
| `Nyse_sim_wire.Pillar_app` | Gateway application messages (orders, acks, execution reports, rejects); prices at scale 8, the units of `Exchange_core.Price` |
| `Nyse_sim_wire.Xdp` | XDP Integrated Feed packets and messages, little endian |
| `Listing` | Listed equities and their reference data |
| `Venue` | Pillar order semantics over `Exchange_core_engine.Exchange`: validation with `Equities_core.Order_types`, session, LULD bands and pauses, short sale restriction, opening and closing auctions |
| `Anchoring` | Price anchor for the noise traders: series, fixed (with drift) or scaled recorded crypto references; `Market_sim.set_reference ~half_life` while the symbol trades continuously in the core session, target held inside the LULD bands, free walk in auctions, pauses and extended hours |
| `Market_event` | What the venue publishes, in matching order |
| `Feed` | XDP publisher: sequence reset, time references, symbol mappings, heartbeats, refresh for late joiners; JSON subscribers get the same messages |
| `Gateway`, `Session_handler`, `Framing` | Per-user Pillar streams (TG, GT, REF), one TCP session's state machine, stream framing |
| `Server` | Gateway and feed TCP listeners, `GET /` venue summary and the `/ws` JSON feed on the HTTP port |
| `Pillar_client` | Client used by `nyse-sim-cli` and the end-to-end script |

Multicast feeds are carried over TCP in the simulator. Listed: AAPL, MSFT, IBM, JPM, KO,
XOM, BRK B and the test symbol ZVZZT. The clock is `always-open` (core session),
`real` (New York time, 2026 holiday calendar) or `accelerated`. Prices are synthetic:
noise traders around a random walk, optionally anchored to a reference price
([design/price-anchor.md](../design/price-anchor.md#tradfi-simulators)). Fidelity against the Pillar and XDP summaries is
summarised in [design/simulators.md](../design/simulators.md#tradfi-simulators).

## Dependencies

- Depends on: `price-anchor`, `market-data`, `equities-core`, `exchange-core-engine`,
  `order-book`, `exchange-core`, `fixed-decimal`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`, `parquet`,
`market-data`, `price-anchor`, `equities-core`.

## Known gaps

- No multicast, A/B lines or retransmission server; one XDP channel, one gateway.
- Auction-only and reserve orders live in the venue, not the engine: auction fills do not
  move engine positions.
- Modify loses time priority (the engine has no in-place reduction).
- No market-wide circuit breakers, fees on execution reports, or real prices (the anchor
  follows a chosen reference; there is no NYSE data source).
- Noise orders bypass the venue's LULD price checks; the anchor keeps its target inside
  the bands, the free walk can still trade through one before the pause.
- `-anchor-scaled` reads normalized event logs only; raw minute files need the venue
  client's normalizer.
- No `Market_data.Feed.t` over the JSON feed, and no `Venue.S` adapter for
  `market-maker`.
