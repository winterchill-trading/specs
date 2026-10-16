# sim-scorecard

Scores how realistic a simulator run is: the same stylised facts of order flow computed on
the simulator's output and on recorded market data over a window, each reported with both
values, a distance and a pass band. Method and the first results are in the repository's
README; the design context is [design/simulators.md](../design/simulators.md#realism-scorecard).

| | |
| --- | --- |
| Repository | `winterchill-trading/sim-scorecard` |
| opam package | `sim-scorecard` |
| Library | `sim-scorecard` (module `Sim_scorecard`) |
| Binary | `sim-scorecard compare -sim (JOURNAL \| DATA_DIR) [-sim-symbol S] [-sim-journal FILE] [-sim-from T -sim-to T] -recorded DATA_DIR -instrument VENUE:SYMBOL [-from T -to T] [-interval-ms N] [-depth N] [-band FACT=MAX] [-json FILE] [-markdown FILE]`; `sim-scorecard facts` |
| Status | done (2026-10-16); first run on hl-sim, free and anchored, against a 90 s mainnet recording |

## Key modules

| Module | Purpose |
| --- | --- |
| `Stats` | Moments, excess kurtosis, autocorrelation, quantiles, two-sample KS, Wasserstein-1, variance ratio |
| `Series` | Trades, two-sided book samples, book level-change counts, optional exact order counts; `Builder` |
| `Norm_source` | A series from a recorder data directory (`market-data` `Event_log`: trades, L2 rebuilt with `L2_book`, or BBO), windowed by venue time; `available_window` |
| `Journal_source` | A series from an `exchange-core-engine` input journal by replay through `Exchange.Config.default`; `orders` counts placed, cancelled and modified requests from the inputs alone |
| `Fact` | Twelve facts: return kurtosis, return and absolute-return autocorrelation, volatility clustering, spread, depth, trade size, inter-trade time, variance ratios, aggressor imbalance autocorrelation, order-to-trade and cancel ratios (L2 proxies); metrics KS, Wasserstein-1, mean absolute difference of curves, absolute difference, absolute log ratio; default bands |
| `Scorecard` | Both sides' summaries and the facts; JSON and markdown |

## Dependencies

- Depends on `exchange-core`, `exchange-core-engine`, `market-data` (and through them
  `fixed-decimal`, `order-book`, `parquet`).
- A separate repository because `market-data` depends on `exchange-core`.
- Used by: nothing yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine` (same URL as
`exchange-core`), `parquet`, `market-data`.

## Known gaps

- Venue simulators' journals replay faithfully only with the simulator's own exchange
  configuration; score their recorded norm logs and pass the journal with `-sim-journal`
  for exact order counts.
- Order-to-trade and cancel ratios for recorded venues are L2 proxies (no order-level
  data is recorded).
- Bands are starting points, not calibrated on pairs of recorded days.
- The one real recording in the workspace is 90 s long; volatility clustering needs
  150 s at the default settings.
