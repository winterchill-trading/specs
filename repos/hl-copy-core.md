# hl-copy-core

Pure copy-trading logic for the [copy-trading platform](../design/copytrading.md): position
scaling, risk caps, rounding to Hyperliquid lots and ticks, the mirroring state machine
that turns leader and follower state into order plans, leader scoring and per-leader pnl
attribution. No network, no clock and no mutable state: every function maps a state and
an event to a new state and a plan.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-core` |
| opam package | `hl-copy-core` |
| Library | `hl-copy-core` (module `Hl_copy_core`) |
| Binary | none (`bench/main.exe` benchmarks `Mirror`) |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Scale` | `Mode.t = Equity_ratio \| Multiplier of float \| Fixed_notional of Usd.t`; `target_size ~leader_size ~leader_equity ~follower_equity ~mark ~mode` |
| `Caps` | `max_leverage`, `max_notional_per_symbol`, `max_daily_loss`, `allowlist`, `min_order_notional`; `clamp`, `order` and `apply` return the capped target, the lot-rounded order and a `Reason.t` per clamp |
| `Rounding` | `Spec.t` (lot, tick, significant figures), `Spec.hyperliquid_perp ~sz_decimals`, `Spec.of_asset_meta`; sizes toward zero to the lot, `delta` drops orders under one lot, `ioc_limit` rounds toward the reference price |
| `Plan` | `{ actions; notes }`: `Place` of an IOC `Order.t` (cloid, symbol, side, size, limit, reduce-only) or `Cancel`, and notes (`Capped`, `No_mark`, `No_spec`, `No_leader_equity`) |
| `Mirror` | Per-follower state; `on_leader_position_change`, `on_follower_fill`, `on_order_closed`, `on_resync ~leader_state ~follower_state ~marks`, `rebalance`, `start_day`; `Event.t` and `apply` for journals |
| `Score` | Leader score from fills and an equity curve: pnl, return, maximum drawdown, win rate and average hold over round trips, trade count, consistency across windows |
| `Pnl` | Follower pnl per leader with average-entry books; `on_fill ~leader`, `summary ~marks` |
| `Follower_config` | One follow (follower, leader, mode, caps, slippage, paused) as a sexp file, validated; `mirror_config ~specs` builds `Mirror.Config.t` |
| `Fill`, `Usd`, `Cloid`, `Address` | Shared fill record and binable wrappers of the `hl-protocol` and `exchange-core` types |

Persisted types have a `Stable.V1` deriving `sexp` and `bin_io`, for journals and config
files. The formulas are in the repository README.

## Mirroring

Targets are absolute: for each symbol the capped target minus the follower's position and
the in-flight orders still moving toward it is ordered as one IOC; in-flight orders that
point the wrong way or overshoot are cancelled. A duplicated leader update plans nothing
new, a replayed journal gives the same plans and client order ids
(`Cloid.create ~follower ~seq`), and after every order fills a rebalance plans nothing;
the three are quickcheck properties in `test/test_mirror.ml`. Only symbols the leader
has held are traded. The daily loss cap flattens the follower until `start_day`; the
other caps only limit growth.

`bench/main.exe` (one leader update, M-series laptop): 186 ns and 89 words with one
symbol, 1.3 us with 20, 7.3 us with 100 when the plan is empty; placing an order adds
about 300 ns and 102 words. `test/test_mirror_alloc.ml` pins the words.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `hl-protocol`, `market-data`.
- Used by (in progress): `hl-copy-engine`, `hl-leaderboard`, `hl-copy-api`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `hl-protocol`, `market-data`.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
