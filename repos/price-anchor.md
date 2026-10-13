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
| Status | library done, TradFi controls included (half-life, `may_engage`, `last_trade`, `step_clock`, `clamp`, `path`); `hl-sim`, `binance-sim` and `bybit-sim` run `Anchor`; the TradFi simulators still run their own `Anchoring` modules, which now map one to one onto `Anchor` (README "TradFi migration") |

## Key modules

| Module | Purpose |
| --- | --- |
| `Anchor` | `create ?market_sim ?half_life ?may_engage ?last_trade ?step_clock ?clamp ?path ~exchange ~reference ~sim_symbol ()`; `apply` (a `Market_data.Event.t`), `gap`, `apply_price` (series point), `step ~now` (pulls `path` on the venue's clock), `stats` (with `pauses` and `clamped`), `is_paused`, `last_set`. Time mapping `sim_time = recv_ts + offset`, mark precedence, funding conversion, staleness (none for a series alone by default), mean reversion and pausing for the TradFi venues |
| `Shadow` | Top-N reference levels as `Alo` orders of `anchor:<venue>:<symbol>`, reconciled keep / cancel / place; consumed size kept until the reference size changes |
| `Queue_ahead` | Reference size ahead of each simulated resting order, reduced by reference trades, capped by the reference size; entries indexed by price in order id order, so a trade or cap touches one price and `refresh` walks each book level with a cursor |
| `Eligible` | `size`: the simulated size a reference trade reaches, in one walk of the book |
| `Source` | Items in `recv_ts` order: `of_feed`, `of_feed_with_gaps`, `of_raw` (`Market_data.Raw_reader` and a `Normalizer.S`), `of_norm` (event logs), `of_series` (an error, not an exception, for a missing or malformed file); `run ?speed ?time_source` paces recorded time; `to_path ?min_interval` reads a source into a `Path.t` (book mids, else trades) |
| `Path` | A reference price as a function of venue time: a series step function or a fixed price with a compounded daily drift (`fixed_of_string "PRICE[,DRIFT]"`) |
| `Clamp` | `within_bands`: keeps a target a margin (30 bps) inside LULD bands or daily limits |
| `Ref_book`, `Scale` | The reference book (best prices cached, `mid_or_null`); price and size factors with tick and lot rounding (`price_or_null`) |

Trade-replay IOCs come from a second account, `anchor-taker:<venue>:<symbol>`, because
self-trade prevention would stop them at the anchor's own shadow orders (or, on the
Hyperliquid simulator, cancel those orders).

## Tests

Expect tests on the synthetic exchange clock: an anchored run with noise traders replays bit
for bit from its recorded inputs; mark precedence and the `mark_interval` throttle; funding
conversion; shadow levels, consumed size, crossing skip and `queue_ahead`; trade replay
through the price and at the price behind the queue; staleness before the first snapshot,
after silence and after a gap, with the hand-back to the noise traders' walk; sources from
raw minute files (with a disconnect), event logs, series files, and paced replay on a
synthetic `Time_source`; TradFi controls: half-life convergence, a phase toggle that pauses
and restarts the walk from the last trade, a venue-owned clock, series without silence
staleness, a clamp following a moving band, a path pulled through a halt; `Path` step
function and drift, `Source.to_path`, `Clamp.within_bands`. Quickcheck bisimulations of `Queue_ahead`
and `Eligible.size` against the earlier implementations (kept in `test/`); minor words per
`apply` pinned in `test/test_alloc.ml` (569 for an unchanged BBO, 23 for a trade with no
eligible fills, independent of the number of resting orders).

## Performance

`bench/bench_anchor.exe`, dev build, arm64: 5.8 us per event with an empty simulated book
(was 5.9), 6.1 us with 50 resting client orders (was 8.5), 7.0 us with 500 (was 34.8). With
the client replacing an order before every event, 17.4 us at 500 (was 42.9). Release with
`-O3`: 5.5 us at 500 (was 25.6). The anchor skips its queue refresh while
`Exchange.next_event_seq` has not moved; marks and the reference mid are `or_null`. The
rest of an event is the engine (shadow place and cancel, `Exchange.step`). Full table in
the README.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`, `order-book`,
  `market-data`.
- Used by: `hl-sim`, `binance-sim` (`binance-sim-anchor`), `bybit-sim`
  (`bybit-sim-anchor`), `nyse-sim`, `cboe-sim`, `cme-sim`.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`, `parquet`,
`market-data`.
