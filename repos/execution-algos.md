# execution-algos

Venue-neutral execution algorithms: a pure scheduler that slices a parent order (a target
position change) into child orders, L2 impact estimates, a VWAP volume profile, cost
reports per parent and a paper venue. Used by [hl-copy-engine](hl-copy-engine.md) to work
the orders the copy mirror plans, and by [copy-backtest](copy-backtest.md). Design
context: [design/copytrading.md](../design/copytrading.md#execution-algorithms).

| | |
| --- | --- |
| Repository | `winterchill-trading/execution-algos` |
| opam package | `execution-algos` |
| Library | `execution-algos` (module `Execution_algos`) |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Algo` | `Immediate`, `Twap`, `Vwap`, `Pov`, `Passive` (pegged; an iceberg below a display of 1), `Adaptive` (passive while the parent is small against the depth near the mid and the follower is not far behind, taking otherwise, on adverse drift or at the timeout); `Stable.V1`, short CLI form (`twap:60s:6`), `validate`, `horizon` |
| `Scheduler` | The state machine: `create ?profile algo parent`, `apply` (`Tick` with time, book and cumulative market volume; child `Fill`; child `Closed`; `Cancel`), `tick` (unboxed pair, no allocation when idle), `step`, `replay`, `report`; no clock, no mutable fields, so a journal of events replays exactly |
| `Parent`, `Child`, `Fill` | The order types exchanged with the caller (`Stable.V1`); children are IOC or post-only, on the lot grid, never past the parent's limit |
| `Book`, `Impact` | Flat top-of-book snapshots (`of_l2_book`, `of_bbo`); `walk` (filled size and notional within a limit, `[@zero_alloc]`), `estimate` (average and worst price, slippage against mid and touch, exhaustion), `depth_within` |
| `Volume_profile` | Time-of-day volume shares from `Market_data.Trade.t`s, uniform without history; `fraction_done` for VWAP slices |
| `Cost_report` | Per parent: arrival slippage, implementation shortfall (execution, the missed move of the unfilled part, fees) in USD and bps, maker share, children, outcome; `Totals` |
| `Paper` | Paper venue for one instrument: book-walk IOC fills, post-only children behind the displayed queue (trades at the price eat the queue, a smaller displayed size caps it, a crossing book fills it), latency, fees |

## Invariants

Property-tested over 2,000 random cases through the paper venue (`test/test_invariants.ml`):
never more than the target (`filled + working <= size`), children on the lot grid and within
the limit, participation caps respected, nothing placed after the horizon but the single
final sweep of `Passive` and `Adaptive` (sent once the cancelled resting children are
closed), every parent done once the market outlives its horizon and two venue round trips,
journal replay identical, events round-trip through `bin_io`.

## Performance

Apple M-series (`bench/main.exe`), dev / release / release with `-O3`: an idle tick 9 /
8 / 7 ns (TWAP) and 0 words (pinned in `test/test_alloc.ml`), a tick placing a TWAP child
76 / 75 / 44 ns, `Impact.walk` over 10 levels 65 / 46 / 29 ns and 0 words, a whole 12-step
TWAP parent through the paper venue 1.7 / 1.6 / 1.3 us.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `market-data`.
- Used by: [hl-copy-engine](hl-copy-engine.md), [copy-backtest](copy-backtest.md).

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`.
