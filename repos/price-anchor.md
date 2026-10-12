# price-anchor

Ties a simulated exchange's market to a reference market, live or recorded: mark price and
funding, the reference's top levels resting in the simulated book, and trade-replay fills.
Every action goes through the engine's journaled calls, so an anchored run replays bit for
bit from its `Journal`. Design: [design/price-anchor.md](../design/price-anchor.md).

| | |
| --- | --- |
| Repository | `winterchill-trading/price-anchor` |
| opam package | `price-anchor` |
| Library | `price-anchor` (module `Price_anchor`) |
| Binary | `price-anchor replay -reference VENUE:SYMBOL (-norm DIR -from DATE -to DATE \| -series FILE) [-symbol SYM] [-journal FILE] [-anchor-speed X]` |
| Status | library done, TradFi controls included; `hl-sim`, `binance-sim` and `bybit-sim` run `Anchor`, the TradFi simulators still run their own `Anchoring` modules |

## Key modules

| Module | Purpose |
| --- | --- |
| `Anchor` | `create ?market_sim ?half_life ?may_engage ?last_trade ?step_clock ~exchange ~reference ~sim_symbol ()`; `apply` (a `Market_data.Event.t`), `gap`, `apply_price` (series point), `step ~now`, `stats`, `is_paused`. Time mapping `sim_time = recv_ts + offset`, mark precedence, funding conversion, staleness (none for a series alone by default), mean reversion and pausing for the TradFi venues |
| `Shadow` | Top-N reference levels as `Alo` orders of `anchor:<venue>:<symbol>`, reconciled keep / cancel / place; consumed size kept until the reference size changes |
| `Queue_ahead` | Reference size ahead of each simulated resting order, reduced by reference trades, capped by the reference size |
| `Source` | Items in `recv_ts` order: `of_feed`, `of_feed_with_gaps`, `of_raw` (`Market_data.Raw_reader` and a `Normalizer.S`), `of_norm` (event logs), `of_series` (an error, not an exception, for a missing or malformed file); `run ?speed ?time_source` paces recorded time |
| `Ref_book`, `Scale` | The reference book; price and size factors with tick and lot rounding |

Trade-replay IOCs come from a second account, `anchor-taker:<venue>:<symbol>`, because
self-trade prevention would stop them at the anchor's own shadow orders.

## Tests

Expect tests on the synthetic exchange clock: an anchored run with noise traders replays
bit for bit from its recorded inputs; mark precedence and the `mark_interval` throttle;
funding conversion; shadow levels, consumed size, crossing skip and `queue_ahead`;
trade replay through the price and at the price behind the queue; staleness before the
first snapshot, after silence and after a gap, with the hand-back to the noise traders'
walk; sources from raw minute files (with a disconnect), event logs, series files, and
paced replay on a synthetic `Time_source`; TradFi controls: half-life convergence,
a phase toggle that pauses and restarts the walk from the last trade, a venue-owned
clock, series without silence staleness. `bench/bench_anchor.exe`: 6.5 us per event
with an empty simulated book, 36 us with 500 resting client orders.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`, `order-book`,
  `market-data`.
- Used by: `hl-sim`, `binance-sim` (`binance-sim-anchor`), `bybit-sim`
  (`bybit-sim-anchor`), `nyse-sim`, `cboe-sim`, `cme-sim`.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`, `parquet`,
`market-data`.
