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
| `Follower_core` | Pure state around `Mirror`: pause, resume and stop, a leverage cap after an insufficient-margin reject, a pause after an agent reject; `Input.Stable.V1` (`Configure`, `Mirror` events, `Order_rejected`, `Pause`, `Resume`, `Stop`), `apply`, `replay` |
| `Journal` | Per-follow Bin_prot journal of inputs and outputs in `Market_data.Framed` day files, `<root>/<follower>-<leader>/<YYYY-MM-DD>.journal`, headed by the entry digest; `verify` replays and compares every output |
| `Leader_hub` | One `Hl_client.User_feed` websocket with one `userFills` subscription per leader, fanned out to its followers; leaders past `max_ws_users` (10) polled with `clearinghouseState` |
| `Rate_limit` | Token bucket for the 1200 weight per minute REST budget, shared by every call of the engine |
| `Follower` | The actor: `meta` specs, journal replay on restart, resync of both accounts (`clearinghouseState`, `allMids`) before trading and every 30 s, IOC execution through `Client.trading_with_agent` (or a signing hook), order responses as fills and rejects, one sequencer per follow; with a configured builder fee, reads `maxBuilderFee` at start and on resyncs (each resync until approved, then every 5 minutes or after an order refused over the fee) and sends `builder {b, f}` only while approved |
| `Engine` | Follow files (`Hl_copy_core.Follower_config` sexps) rescanned every second: start, reconfigure in place, stop; each scan pauses a follower whose agent was revoked and restarts one whose agent was rotated; HTTP `/metrics` (Prometheus), `/status` (JSON: per follower `follower`, `leader`, `state`, `pnl`, `positions` with `coin`, `size`, `entry_px`, `unrealized_pnl`, `leverage`, and `last_error`, as hl-copy-api's `/me` reads it, plus `builder` with `approved` and a `note`), `/healthz`; `run -builder ADDRESS -builder-fee-tenths-bp N` |
| `Key_source` | Opens the follower's agent from `Hl_copy_core.Key_store` (`<state-dir>/agents/<account>.key`, the API's state directory mounted read-only) under `HL_COPY_MASTER_KEY` |
| `Metrics`, `Reject`, `Safety` | Counters and summaries (orders, fills, rejects by reason, lag, slippage, pnl, resyncs, `hl_copy_builder_fee_orders_total` and `hl_copy_builder_fee_skipped_total`); reject classification from the exchange's error text; the mainnet guard |

`scripts/e2e-sim.sh` runs `hl-sim -leaders 3 -strict-signatures`, approves an agent with
throwaway keys, and runs the engine on one follow for 60 s, printing both positions,
the metrics, and the journal replay check. One run: lag from the leader's fill to the
follower's order 1 to 3 ms, slippage p50 4.8 bps, the journal replayed identically.

## Dependencies

- Depends on: `hl-copy-core`, `hl-client`, `hl-protocol`, `market-data`,
  `exchange-core`, `fixed-decimal`.
- Test-only: `hl-sim`, `exchange-core-engine`.
- Used by: [hl-copy-api](hl-copy-api.md) (writes the follow files and the key store,
  reads `/status`), [infra](infra.md) (runs `run -base-url -configs-dir -journal-dir
  -port 9930 -state-dir`).

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`, `venue-net`,
`hl-client`, `hl-copy-core`, `mm-core`, `binance-protocol`, `binance-client`, `order-book`, `exchange-core-engine`
(exchange-core repository), `price-anchor`, `hl-sim`.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
