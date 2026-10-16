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
| Binary | `copy-backtest run -leader-fills FILE -norm DIR [-from DATE -to DATE] [-algo ALGO] [-mode M] [-max-leverage X] ... [-out DIR]`, `sweep -algos A,.. -modes M,.. -max-leverages X,..`, `synthetic -seed N -out DIR`, `slice` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Backtest` | `run params source`: market events update the coin's book and paper venue; leader fills (seen after a copy delay) move the leader's position, and the mirror plans the follower's orders as the engine does; each planned order is a parent worked by the follow's algorithm; a grid adds algo ticks, curve samples, hourly funding and the UTC daily-loss window. Result: `Summary` (pnl, drawdown, fees, funding, turnover, fill rate, shortfall, slippage, maker share, tracking error, gap to the scaled leader), the curve and per-parent cost reports |
| `Source` | Market events (`load_norm` over `Market_data.Event_log` day files) and leader fills merged in time order |
| `Leader_fills` | `userFills` arrays, NDJSON or leaderboard raw pages; dedup by trade id |
| `Params`, `Specs`, `Copy_algo` | Run settings (follow config with mode, caps and algo; equities; copy delay, latency, tick, sample; fees; funding); lot and tick specs from a saved `meta` |
| `Output` | `summary.parquet`, `curve.parquet`, `parents.parquet`; `check_duckdb` recomputes parents, shortfall, fees, end equity and drawdown in SQL and compares |
| `Sweep` | Algorithms x scale modes x leverage and notional caps |
| `Synthetic` | A seeded market (random walk, L2 snapshots, trades, hourly funding) and leader |

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`,
  `hl-copy-core`, `execution-algos`.
- Test-only: the DuckDB CLI.
- Used by: nothing in the organization yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`,
`hl-copy-core`, `execution-algos`.
