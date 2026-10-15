# backtest-stats

Statistics for deciding whether a backtest result is real, over plain return series and
strategy-by-period matrices: adjusted, probabilistic and deflated Sharpe ratios, the
reality check and SPA bootstrap tests, the probability of backtest overfitting, VaR
backtests with exact small-sample p-values, and an acceptance gate whose policy is a sexp.
Venue-neutral; nothing in it knows about orders or exchanges.

| | |
| --- | --- |
| Repository | `winterchill-trading/backtest-stats` |
| opam package | `backtest-stats` |
| Library | `backtest_stats` (module `Backtest_stats`) |
| Binary | `backtest-stats` (`report`, `gate`, `spa`, `pbo`, `var`, `adjust`) |
| Status | done: library, CLI over CSV and Parquet, tests and benchmarks |

## Key modules

| Module | Purpose |
| --- | --- |
| `Series` | Timestamped simple returns: validation, from prices or PnL, split, calendar resampling, excess returns, periods per year from the spacing |
| `Bootstrap` | Seeded i.i.d., circular block and stationary bootstrap indices (shared across the rows of a matrix), percentile intervals |
| `Metrics` | Moments, Sharpe and Sortino, autocorrelation-adjusted annualization, skew- and kurtosis-adjusted Sharpe, Sharpe standard error, PSR, expected maximum Sharpe of N trials, DSR, minimum track record length, drawdowns with bootstrap intervals |
| `Multiple_testing` | Reality check; SPA with lower, consistent and upper p-values; Bonferroni, Holm and Benjamini-Hochberg; PBO by combinatorially symmetric cross-validation |
| `Var_backtest` | Kupiec coverage, Christoffersen independence and conditional coverage (exact p-values by enumeration and dynamic programming up to 500 observations, asymptotic beyond), traffic-light zones and plus factor |
| `Gate` | `Policy` (sexp, every threshold optional), `Evidence`, typed `Reason`, `Verdict`; a threshold without evidence rejects as `Missing_evidence` |
| `Report` | One record per strategy with every statistic, the evidence and the verdict; sexp and JSON |
| `Json`, `Dist` | JSON encoders; normal, chi-square and binomial distributions |

## Conventions

- Sharpe ratios are per period unless a name says annualized; returns are simple fractions.
- Matrices are `float array array`, one row per strategy, one column per period.
- Every resampler takes an explicit `Random.State.t`; reports take a `seed`.

## Interface for consumers

`Report.create ?name ?out_of_sample_periods ?psr_benchmark_sharpe ?trials ?candidates
?benchmark ?pbo_splits ?bootstrap_samples ?seed ?policy ~periods_per_year series` returns a
`Report.t Or_error.t`. With a candidate matrix of every configuration tried, the report
includes the PBO, reality check and SPA p-values and the deflated Sharpe ratio over them.
`Report.t` derives sexp, compare and equal and has `to_json`; `Gate.Reason.to_string_hum`
renders a failed check for people. Planned consumers are the leader rankings and the copy
backtests; neither calls it yet.

## Verification

- 38 expect tests and 11 Quickcheck properties, plus a cram test that runs every CLI
  command on committed CSV and Parquet fixtures.
- Reference values from scipy, statsmodels and numpy to 1e-9 or better; the published
  deflated Sharpe example (0.9004); the Basel traffic-light table.
- Monte Carlo: reality check and SPA reject at their nominal rate under the null; PBO
  averages one half for strategies without edge and is near zero with a planted edge;
  the DSR decreases as trials grow; exact VaR p-values equal brute-force enumeration of
  every hit sequence up to length 12.

## Performance

Apple M-series, release build: Sharpe ratio of 2520 returns 6 us, PSR or DSR 11 us,
reality check or SPA over 20 strategies by 504 periods with 200 resamples 2.6 ms, PBO with
16 splits (12870 combinations) 13 ms, exact Christoffersen test on 250 observations 64 ms.
The metric loops keep their accumulators unboxed.

## CI

`ci.yml` runs the infra `ox-setup` action pinning `parquet`, builds, tests, builds odoc
with warnings failing, and calls the shared `obj-magic` workflow.

## Dependencies

- Depends on: [parquet](parquet.md) (binary only). External: `core`, `core_unix`,
  `yojson`, `ppx_jane`, `core_bench` (benchmarks).
- Used by: none yet.

## Known gaps

- SPA studentizes with the bootstrap variance, not a kernel estimator.
- PBO is limited to 24 contiguous blocks.
- Exact Christoffersen p-values cost about n^3 / 4 steps.
- Not yet wired into leader rankings, copy backtests or market-maker parameter changes.
