# hl-copy-core

Pure copy-trading logic for the [copy-trading platform](../design/copytrading.md): position
scaling, risk caps, rounding to Hyperliquid lots and ticks, the mirroring state machine
that turns leader and follower state into order plans, leader scoring and per-leader pnl
attribution. No network, no clock and no mutable state: every function maps a state and
an event to a new state and a plan. The one exception is `Key_store`, the agent key
files the API writes and the engine reads.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-core` |
| opam packages | `hl-copy-core`, `hl-copy-backtest` |
| Libraries | `hl-copy-core` (module `Hl_copy_core`), `hl-copy-backtest` (module `Hl_copy_backtest`) |
| Binaries | `hl-copy-backtest`; `bench/main.exe` benchmarks `Mirror` |
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
| `Key_store` | Agent keys at rest: `<state_dir>/agents/<account>.key` (mode 0600, sexp of agent address, name, created, valid until, ciphertext, nonce, tag), sealed under `HL_COPY_MASTER_KEY` with ChaCha20 and HMAC-SHA256 (encrypt-then-MAC; cryptokit 1.16 has no AEAD, TODO); `create ~state_dir`, `put`, `find`, `get ~account` (decrypted key as hex), `list`, `revoke` |
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

## Backtest (`hl-copy-backtest`)

A second package in the repository (`backtest/`) estimates what a follower would have
earned copying a leader from an [hl-leaderboard](hl-leaderboard.md) collection directory
alone. It replays the leader's position changes through `Mirror` and fills each IOC order
at the leader's price moved by a configurable slippage, inside the order's IOC limit,
paying a 4.5 bp taker fee by default. Model, outputs and a mainnet run are in
[design/copytrading.md](../design/copytrading.md#backtest) and the repository README.

| Module | Purpose |
| --- | --- |
| `Leader_change` | Fills of one coin, side and millisecond grouped into one position change at their average price |
| `Input` | One leader's perpetual fills (synthetic opens included) and equity curve, as `hl-leaderboard rank` scores them |
| `Specs` | Lot and tick per coin from a saved `meta` response, else inferred from fill sizes |
| `Collection` | Loads every leader, or one, from a collection directory |
| `Backtest` | `Params.t` (follow, starting equity, slippage, fee, specs), `run`, `Result.t` (equity curve, pnl, drawdown, fees, turnover, orders, skipped changes by reason, the leader's marked pnl and curve over the same window) |
| `Ranking` | Every leader by follower pnl under one configuration |
| `Report` | `backtest.json`, `results.parquet`, `curves.parquet` and the text summary |

`hl-copy-backtest -dir DIR (-leader ADDRESS | -leaders N) [-config FOLLOW] [-equity USD]
[-slippage-bps F] [-fee-bps F] [-meta FILE] [-out DIR]`.

## Dependencies

- `hl-copy-core` depends on: `fixed-decimal`, `exchange-core`, `hl-protocol`,
  `market-data`; `cryptokit` and `core_unix` for `Key_store`.
- `hl-copy-backtest` depends on: `hl-copy-core`, `hl-leaderboard`, `parquet`,
  `market-data`, `hl-protocol`, `fixed-decimal`.
- Used by (in progress): `hl-copy-engine`, `hl-leaderboard`, `hl-copy-api`.

## CI pin order

Two jobs, because `hl-copy-backtest` needs `hl-leaderboard`, which needs `hl-copy-core`:

- `build` (`hl-copy-core` only): `fixed-decimal`, `exchange-core`, `parquet`,
  `hl-protocol`, `market-data`.
- `backtest`: `fixed-decimal`, `exchange-core`, `parquet`, `market-data`,
  `hl-protocol`, `venue-net`, `hl-client`, `hl-copy-core` (at the commit under test),
  `leader-scoring`, `leader-scoring-hl` (hl-leaderboard depends on them),
  `hl-leaderboard`; only `hl-copy-backtest` is built.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
