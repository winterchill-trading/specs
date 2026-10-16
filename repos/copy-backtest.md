# copy-backtest

A deterministic backtester for copy trading: recorded market data and a leader's
Hyperliquid fill history replayed through the copy mirror of
[hl-copy-core](hl-copy-core.md) and the schedulers of
[execution-algos](execution-algos.md), with child orders filled on paper venues against
the replayed book. Results go to Parquet (via [parquet](parquet.md)) and are checked with
DuckDB. Unlike `hl-copy-backtest` (in hl-copy-core), which fills each order at the
leader's own price from leaderboard collections, this one needs the market itself: book,
trades and funding from [market-recorder](market-recorder.md) event logs. Design context:
[design/copytrading.md](../design/copytrading.md#backtest).

| | |
| --- | --- |
| Repository | `winterchill-trading/copy-backtest` |
| opam package | `copy-backtest` |
| Library | `copy-backtest` (module `Copy_backtest`) |
| Binary | `copy-backtest run -leader-fills FILE -norm DIR [-from DATE -to DATE] [-algo ALGO] [-mode M] [-max-leverage X] [-band B] ... [-gate POLICY] [-oos-fraction F] [-out DIR]`, `sweep -algos A,.. -modes M,.. -max-leverages X,.. -bands B,..`, `synthetic -seed N -out DIR`, `slice`, `attribute -backtest DIR [-run N] -journal FILE` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Backtest` | `run params source`: market events update the coin's book and paper venue; leader fills (seen after a copy delay) move the leader's position, and the mirror plans the follower's orders as the engine does; each planned order is a parent worked by the follow's algorithm; a grid adds algo ticks, curve samples, hourly funding and the UTC daily-loss window. Result: `Summary` (pnl, drawdown, fees, funding, turnover, fill rate, shortfall, slippage, maker share, tracking error, gap to the scaled leader), the curve and per-parent cost reports |
| `Source` | Market events (`load_norm` over `Market_data.Event_log` day files) and leader fills merged in time order |
| `Leader_fills` | `userFills` arrays, NDJSON or leaderboard raw pages; dedup by trade id |
| `Params`, `Specs`, `Copy_algo` | Run settings (follow config with mode, caps and algo; equities; copy delay, latency, tick, sample; fees; funding); lot and tick specs from a saved `meta` |
| `Output` | `summary.parquet` (with band skips and saved cost), `curve.parquet`, `parents.parquet` (with the decision price), `stats.parquet`, `reports.json`, `summary.md`; `check_duckdb` recomputes parents, shortfall, fees, end equity and drawdown in SQL and compares |
| `Sweep` | Algorithms x scale modes x leverage and notional caps x no-trade bands |
| `Stats` | [backtest-stats](backtest-stats.md) `Report` per run (PSR, DSR with the sweep's configurations as trials) and for the sweep's pick (probability of backtest overfitting across the grid, reality check and SPA against the leader); `rejected` for `-gate` |
| `Attribution` | Costs per leg (fees, slippage against arrival, timing from the leader's fill price to arrival, partial fills, funding) and the live-minus-backtest return split into one term per cost and a residual; `backtest_leg` reads a `-out` directory |
| `Live_journal` | The live leg from an [hl-copy-engine](hl-copy-engine.md) journal, replayed through `Follower_core` to join each parent's start (coin, decision price) with its cost report |
| `Synthetic` | A seeded market (random walk, L2 snapshots, trades, hourly funding) and leader |

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `parquet`, `backtest-stats`,
  `market-data`, `hl-protocol`, `hl-copy-core`, `execution-algos`, `hl-copy-engine` (its
  journal format).
- `scripts/sim-vs-live.sh` also builds `hl-sim` and `market-recorder`.
- Test-only: the DuckDB CLI.
- Used by: nothing in the organization yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `backtest-stats`, `market-data`,
`hl-protocol`, `venue-net`, `hl-client`, `hl-copy-core`, `execution-algos`,
`hl-copy-engine`.

## Numbers

The 17-minute hl-sim recording (three leaders, five algorithms, band off and on;
2026-10-16): the default band held back 14 to 28 rebalances per run and cut 2 to 7% of
the fees for about 500 bps more mean gap. The sweep's pick has DSR 0.99 and PBO 0.04 or
less for the trend and mean-reversion leaders, DSR 0.81 and PBO 0.71 for the random
one. A 180 s sim-versus-live run (`scripts/sim-vs-live.sh`) trailed its backtest by 1.18
bps, almost all timing and slippage (the engine's `Immediate` parents measure arrival at
the leader's fill price), with fees within 0.12 USD and a residual of 0.09 bps.
