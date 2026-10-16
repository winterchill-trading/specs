# hl-copy-engine

The mirroring service of the [copy-trading platform](../design/copytrading.md): one
`Follower` actor per follow subscribes to its leader through a shared hub, keeps
`Hl_copy_core.Mirror` state in a pure core, and sends IOC orders signed by the follower's
agent key; an `Engine` supervises the followers from a watched directory of follow files
and serves `/metrics` and `/status`. Refuses mainnet URLs (hl-sim and testnet only).

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-engine` |
| opam package | `hl-copy-engine` |
| Library | `hl-copy-engine` (module `Hl_copy_engine`) |
| Binary | `hl-copy-engine` (`run`, `approve-agent`, `replay`) |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Follower_core` | Pure state around `Mirror`: pause, resume and stop, a leverage cap after an insufficient-margin reject, a pause after an agent reject; every planned place is a parent (`Exec`) worked by an [execution-algos](execution-algos.md) `Scheduler` with the follow's algorithm (`Immediate` sends the mirror's order unchanged; child `k` carries the parent's client order id with `k` in bits 40 and up); open parents stay in flight across resyncs; a follow's no-trade band holds back rebalances as `Within_band` plan notes, and a band with `Impact` slippage gets its estimate from each `Market` tick (`Execution_algos.Impact.estimate` of the order closing the gap), so a replay sets the same one; `Input.Stable.V3` (`Configure` with `Follower_config.Stable.V3`, `Mirror` events, `Order_rejected`, `Pause`, `Resume`, `Stop`, `Market` ticks; `V1` and `V2` still read), `Output.Stable.V3` with `Plan.Stable.V2`, post-only ids and cost reports, `apply`, `replay` |
| `Journal` | Per-follow Bin_prot journal of inputs and outputs in `Market_data.Framed` day files, `<root>/<follower>-<leader>/<YYYY-MM-DD>.v3.journal` (entries version 3), headed by the entry digest; version 1 (`<YYYY-MM-DD>.journal`) and 2 (`.v2.journal`) files still load; `verify` replays and compares every output (plan and notices only for version 1 outputs) |
| `Leader_hub` | One `Hl_client.User_feed` websocket with one `userFills` subscription per leader, fanned out to its followers; leaders past `max_ws_users` (10) polled with `clearinghouseState` |
| `Rate_limit` | Token bucket for the 1200 weight per minute REST budget, shared by every call of the engine |
| `Follower` | The actor: `meta` specs, journal replay on restart, resync of both accounts (`clearinghouseState`, `allMids`) before trading and every 30 s, IOC execution through `Client.trading_with_agent` (or a signing hook), order responses as fills and rejects, one sequencer per follow; with a configured builder fee, reads `maxBuilderFee` at start and on resyncs (each resync until approved, then every 5 minutes or after an order refused over the fee) and sends `builder {b, f}` only while approved |
| `Engine` | Follow files (`Hl_copy_core.Follower_config` sexps) rescanned every second: start, reconfigure in place, stop; each scan pauses a follower whose agent was revoked and restarts one whose agent was rotated; HTTP `/metrics` (Prometheus), `/status` (JSON: per follower `follower`, `leader`, `state`, `pnl`, `positions` with `coin`, `size`, `entry_px`, `unrealized_pnl`, `leverage`, and `last_error`, as hl-copy-api's `/me` reads it, plus `builder` with `approved` and a `note`), `/healthz`; `run -builder ADDRESS -builder-fee-tenths-bp N` |
| `Key_source` | Opens the follower's agent from `Hl_copy_core.Key_store` (`<state-dir>/agents/<account>.key`, the API's state directory mounted read-only) under `HL_COPY_MASTER_KEY` |
| `Metrics`, `Reject`, `Safety` | Counters and summaries (orders, fills, rejects by reason, lag, slippage, pnl, resyncs, `hl_copy_builder_fee_orders_total` and `hl_copy_builder_fee_skipped_total`, `hl_copy_parents_total{algo,outcome}`, `hl_copy_arrival_slippage_bps`, `hl_copy_shortfall_usd`, `hl_copy_exec_fees_usd`, `hl_copy_band_skips_total`, `hl_copy_band_saved_usd`); reject classification from the exchange's error text; the mainnet guard |
| `Algo_bridge` | The follow's `Hl_copy_core.Exec_algo` to `Execution_algos.Algo` (same shape, checked by digest) |

`scripts/e2e-sim.sh` runs `hl-sim -leaders 3 -strict-signatures`, approves an agent with
throwaway keys, and runs the engine on one follow for 60 s, printing both positions,
the metrics, and the journal replay check. One run: lag from the leader's fill to the
follower's order 1 to 3 ms, slippage p50 4.8 bps, the journal replayed identically.
With `ALGO` set (2026-10-16, 60 s runs): `Immediate` filled 27.6% of the parents'
notional on the thin simulated book (shortfall 5.0 bps of target), a 6 s three-slice TWAP
99.99% (5.8 bps), the default adaptive algorithm 99.93% (11.0 bps); every journal
replayed identically.

The `Follower` actor opens the public `l2Book` and `trades` feed of a coin
(`Hl_client.Live_feed`) when a parent with an algorithm other than `Immediate` needs it,
ticks parents every 500 ms, sends post-only children as `alo` and reads their fills from
the follower's own `userFills` (`Hl_client.User_feed`); `/status` lists active parents,
recent cost reports and totals under `execution`, and the follow's band (config,
half-width, skips, saved cost, slippage estimates, recent skips) under `band`.

With `BAND` set (2026-10-16, 60 s runs, a $1,000,000 follower): no band, 9 orders, 100.77
USD of fees, tracking error 611 bps; the default band (half-width about 52,800 USD), 7
orders, 79.75 USD, 2 skips saving an estimated 97.72 USD, tracking error 1,076 bps; every
journal replayed identically, including a run with `Impact` slippage that journaled the
BTC book ticks.

## Dependencies

- Depends on: `hl-copy-core`, `execution-algos`, `hl-client`, `hl-protocol`,
  `market-data`, `exchange-core`, `fixed-decimal`.
- Test-only: `hl-sim`, `exchange-core-engine`.
- Used by: [hl-copy-api](hl-copy-api.md) (writes the follow files and the key store,
  reads `/status`), [infra](infra.md) (runs `run -base-url -configs-dir -journal-dir
  -port 9930 -state-dir`).

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`, `venue-net`,
`hl-client`, `hl-copy-core`, `execution-algos`, `mm-core`, `binance-protocol`,
`binance-client`, `order-book`, `exchange-core-engine`
(exchange-core repository), `price-anchor`, `hl-sim`.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
