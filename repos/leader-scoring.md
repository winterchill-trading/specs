# leader-scoring

Scores traders for the [copy-trading platform](../design/copytrading.md): rebuilds a track
record (round-trip trades and an equity curve) from a trader's fills, funding and account
snapshots, computes 34 documented metrics, ranks a universe with a transparent weighted
percentile score and a learned 30-day forecast, estimates a follower's copy cost and
capacity from order-book depth, raises behaviour alerts, tests whether a ranking persists
(against random picks), computes selection-bias statistics, and flags manipulated or
uncopyable leaders. The core is venue neutral;
the Hyperliquid source is read only.

| | |
| --- | --- |
| Repository | `winterchill-trading/leader-scoring` |
| opam packages | `leader-scoring` (venue neutral), `leader-scoring-hl` (Hyperliquid source and CLI) |
| Libraries | `leader-scoring` (module `Leader_scoring`), `leader-scoring-hl` (module `Leader_scoring_hl`) |
| Binary | `leader-scoring` (`record`, `score`, `portfolios`, `dataset`, `metrics`, `persistence`) |
| Python | `python/` (`train.py`, run with `uv`): walk-forward evaluation, fit, export |
| Status | done (2026-10-16): library, Hyperliquid source, model, bench, persistence, selection statistics, integrity; used by hl-leaderboard |

## Key modules

| Module | Purpose |
| --- | --- |
| `Fill`, `Funding`, `Snapshot`, `Equity_point`, `History` | Venue-neutral inputs, `Stable.V1` Bin_prot forms |
| `Source` | `Source.S` (fetch one account's history between two times) and an in-memory `Static` source |
| `Track_record` | Trades (average-entry books, flips split, funding per trade), the equity curve anchored on the latest snapshot or taken from a venue curve, exposure points, time windows |
| `Metric`, `Metrics` | The catalogue (snake-case name, label, formula, unit, direction) and its computation over day, hour or minute bars |
| `Score` | Weighted percentile composite, eligibility floors, per-component points |
| `Copyability` | Follower order cost from walking book depth (binary search over running totals), capacity by bisection on log size |
| `Alerts` | Drawdown breach, leverage spike, style drift, frequency change, liquidation; `scan` replays them along a record |
| `Synthetic`, `Dataset`, `Model` | Synthetic leaders with a drifting edge, training rows with the forward label, the exported gradient-boosted model (embedded as `Model.bundled`) |
| `Persistence` | Rank correlation of window `k` against `k + 1` with a bootstrap interval, quintile transitions, decay over horizons, top-K against random picks; `persistent` when the interval is above zero and the top K beat 95% of random draws |
| `Leader_stats` | backtest-stats `Report` per leader (PSR, DSR with the leaders as trials, minimum track record) and PBO, SPA and the reality check over a common window |
| `Integrity` | Typed flags with evidence: self and wash trades, counterparties among watched accounts, co-trading clusters (chance from circular time shifts), front-running of a trade flow, creation bursts, off-book fills; `Policy` decides exclusion |
| `Report` | Everything a leader page shows, and its JSON; `analyse` adds the universe checks, `rank` leaves excluded leaders unranked |
| `Leader_scoring_hl.Hl_source`, `Raw`, `Hl_decode`, `Hl_market` | `/info` requests only (`userFillsByTime`, `userFunding`, `clearinghouseState`, `portfolio`, `l2Book`, `metaAndAssetCtxs`), recordings, decoders |

## Formats

- Inputs: `History.Stable.V1` (account, venue, fetch time, fills, funding, snapshots, venue
  curve, `fills_truncated`), with every time as `Time_ns.Stable.Alternate_sexp.V1`.
- Recordings (`Raw`): a directory per account with `meta.sexp`, `fills-<i>.json`,
  `funding-<i>.json`, `state.json`, `portfolio.json`, the answers as received.
- Model (`models/leader-forward-sharpe-gbdt/model.json`, format 1): feature names (must
  equal `Dataset.feature_names`), `base_score`, scikit-learn trees as parallel arrays
  (`x <= threshold` goes left, NaN follows `missing_left`), the walk-forward evaluation.
- `Report.to_json`: account, equity source, period, score with components, forecast,
  metrics, thinned equity curve, capacity curve, alerts. hl-leaderboard writes it to
  `reports/<address>.json`.

## Learned score

Target: the Sharpe ratio of the 30 daily returns after a cutoff (not annualized, clipped
to [-5, 5]), from the 31 metrics of the 90 days before it. Trained on 1500 synthetic
leaders and the `portfolio` all-time curves of 287 mainnet accounts (read only). Walk-forward
rank correlation (IC): synthetic 0.061 (t 11.3) against 0.060 for past Sharpe alone and
0.031 for the composite; mainnet replay 0.026 (t 0.9, not significant) against 0.040 for past
Sharpe. The README has the full table and caveats; the forecast is shown next to the
transparent score, not instead of it.

## Cost

Apple M-series, dev profile, one leader with 2038 fills and 400 daily snapshots:
`Track_record.build` 1.5 ms, `Metrics.compute` 1.1 ms, `Score.rank` 10.6 us a leader (300
leaders), `Model.predict_metrics` 2.2 us, `Copyability.estimate` 4.5 ms, `Alerts.detect`
1.4 ms, a whole `Report.create` 241 ms (the alert scan over 400 days dominates).

## Tests

Expect tests of trades, seeding, repairs and venue curves; metrics pinned on a 60-day
curve; Quickcheck properties (scaling and time invariance, bounds, drawdown and win-rate
monotonicity, score order and monotonicity, cost growing with follower size); alerts on a
leader that turns reckless; model parity with scikit-learn (exact on 200 rows); decoding
of a recorded mainnet account and an hl-sim leader.

## CI

`ci.yml` runs the `ox-setup` action with pins fixed-decimal, exchange-core, parquet,
market-data, hl-protocol, venue-net, hl-client, then build, test and the odoc build
(warnings fail); `obj-magic` from infra.

## Dependencies

- Depends on: [market-data](market-data.md) and [backtest-stats](backtest-stats.md) (core package);
  [hl-client](hl-client.md) and [hl-protocol](hl-protocol.md) (the `-hl` package).
- Used by: [hl-leaderboard](hl-leaderboard.md) (`Scoring`), and through it
  [hl-copy-api](hl-copy-api.md) and [hl-copy-web](hl-copy-web.md). Repositories that build
  hl-leaderboard in CI pin `backtest-stats`, `leader-scoring` and `leader-scoring-hl`
  before it ([hl-copy-api](hl-copy-api.md), the backtest job of
  [hl-copy-core](hl-copy-core.md), which still needs the `backtest-stats` pin).
- External: `core`, `async`, `yojson`, `core_bench` (tests); Python `numpy`,
  `scikit-learn` 1.9.1 and `scipy` for training only.

## Known gaps

- The learned score is trained mostly on synthetic data; on mainnet it does not beat past
  Sharpe. It needs months of real fill histories.
- Copy cost uses the books at estimate time for past orders and leaves fees out.
- Annualized figures from minute bars (simulator runs) are only comparable among records
  with the same bar.
- The alert scan is the slow part of a report on long histories.
- Persistence on the 287 mainnet all-time curves (13-week windows of weekly bars): rank
  correlation 0.05 [-0.03, 0.12], top 10 at the 48th percentile of random picks: no
  ranking tried persists. The sample is itself selected by past pnl.
- Front-running needs a trade flow nobody collects yet; Hyperliquid publishes no account
  creation time (the portfolio curve's first point stands in).
