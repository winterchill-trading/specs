# mm-core

Venue-neutral market-making core: a pure quoting strategy, a reconciler, risk checks,
the `Venue.S` client signature and the `Live.Make` event loop that runs the strategy on
any venue implementing it.

| | |
| --- | --- |
| Repository | `winterchill-trading/mm-core` |
| opam package | `mm-core` |
| Library | `mm-core` (module `Mm_core`) |
| Binaries | none |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Fx` | Fixed-point helpers: notionals, bps shifts, tick and lot rounding |
| `Params` | Strategy parameters, `Params.btc` defaults, `for_instrument`, `validate` |
| `Fill`, `Order_update` | Account events as the strategy sees them |
| `Market_state` | Last book, mid, microprice, EWMA volatility |
| `Inventory` | Position, average entry, realized and unrealized PnL, fees |
| `Quote`, `Quoter` | Desired orders; `quote : Params.t -> Market_state.t -> Inventory.t -> Quote.t list` |
| `Action`, `Reconciler` | `Keep`/`Cancel`/`Place`; minimal plan from resting orders, deterministic client ids |
| `Risk` | Kill switch and flatten plan |
| `Strategy` | State machine: `on_book`, `on_fill`, `on_open_orders`, `on_account`, `tick ~now` |
| `Venue` | `module type S`, the Async venue client contract |
| `Live` | `Make (V : Venue.S)`: feeds, polls, sequenced plan execution, shutdown, `Report`, `stop_signal` |

## Dependencies

- Depends on: `exchange-core`, `fixed-decimal`.
- Used by: `hl-mm`, `binance-client`, `bybit-client`, `market-maker`.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Design

See [design/market-making.md](../design/market-making.md).

## Known gaps

- The position is not flattened on exit; `stop` only cancels resting orders.
- One symbol per `Live.Make` run.
- Strategy parameters are static for a run (no online tuning).
