# hl-copy-core

Pure copy-trading logic for the [copy-trading platform](../design/copytrading.md): position
scaling, risk caps, rounding to Hyperliquid lots and ticks, the mirroring state machine
that turns leader and follower state into order plans, leader scoring and per-leader pnl
attribution. No network and no clock of its own.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-core` |
| opam package | `hl-copy-core` |
| Library | `hl-copy-core` (module `Hl_copy_core`) |
| Binary | none |
| Status | in progress |

## Key modules (planned)

| Module | Purpose |
| --- | --- |
| `Scale` | `Equity_ratio`, `Multiplier`, `Fixed_notional` modes; `target_size ~leader_size ~leader_equity ~follower_equity ~mode` |
| `Caps` | Maximum leverage, maximum notional per symbol, maximum daily loss, symbol allowlist, minimum order notional; `apply` clamps and explains |
| `Rounding` | Size to lot, price to tick per instrument; drops orders below the minimum |
| `Mirror` | Per-follower state; `on_leader_position_change`, `on_follower_fill`, `on_resync`; emits a `Plan.t` of IOC places and cancels within a slippage bound; idempotent |
| `Score` | Leader score from fills and an equity curve: pnl, maximum drawdown, win rate, trade count, average hold, consistency across windows |
| `Pnl` | Follower pnl attribution per leader |
| `Follower_config` | Stable config type shared by the API and the engine |

Types derive `sexp` and `bin_io` with stable versions, for journals and config files.

## Dependencies

- Depends on (planned): `fixed-decimal`, `hl-protocol`, `market-data`.
- Used by (planned): `hl-copy-engine`, `hl-leaderboard`, `hl-copy-api`.

## CI pin order

Planned: `fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
