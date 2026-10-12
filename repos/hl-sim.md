# hl-sim

Hyperliquid exchange simulator: an HTTP and websocket server speaking Hyperliquid's
public API over `exchange-core-engine`, with the engine's market simulation.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-sim` |
| opam package | `hl-sim` |
| Library | `hl-sim` (module `Hl_sim`) |
| Binary | `hl-sim` (`-port` 3000, `-seed`, `-vol-bps`, `-coins`, `-noise-traders`, `-initial-balance`, `-response-delay-ms`, `-journal`, `-log-level`) |
| Status | done |

## Key modules

- `Adapt`: the Hyperliquid view of the engine: universe (BTC, ETH, SOL at asset indices
  0, 1, 2), price and size rules, asset index mapping, both endpoints in `hl-protocol`
  types, error wording, `User_fill` `dir` labels, `Trade`, `Order_update`,
  `Clearinghouse_state`.
- `Active_asset_ctx`: the `activeAssetCtx` channel (funding, mark, oracle, mid, impact
  prices, premium, open interest, day volumes) built from the engine; `oraclePx` equals
  `markPx`, and day volumes cover the current UTC day of the exchange clock.
- `Journal`: JSON-lines journal of accepted `/exchange` requests (`-journal FILE`);
  `Server.replay` applies one to a fresh exchange and reproduces responses, fills and
  account state when nothing else trades (`-noise-traders 0`).
- `Server`: cohttp-async server for `POST /info`, `POST /exchange` and the `/ws`
  websocket on the same port; owns the engine and its timers. `-response-delay-ms`
  delays every `/exchange` response while the order and its websocket events take effect
  at once, for double-placement tests. Each connection may queue at most 10,000 messages
  (`Config.max_ws_queue`); a subscriber that stops reading is disconnected and counted,
  without delaying other clients' acks.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`, `hl-protocol`,
  `order-book`.
- Used by: `hl-mm` (tests); built as an image by `infra`; target of `market-maker
  -venue hyperliquid -network local`.

## CI pin order

`fixed-decimal`, `exchange-core`, `hl-protocol`, `order-book`, `exchange-core-engine`.
CI sets `dune-cache: true` on `ocaml/setup-ocaml@v3`.

## Behaviour

Described in [design/simulators.md](../design/simulators.md). In short: the acting
address is the `X-Address` header, else `vaultAddress`, else `0x...01`; every address
seen is credited `-initial-balance` USD; signatures are not verified.

## Known gaps

- `activeAssetCtx` is decoded by hl-sim's own module, not yet by `hl-protocol`.
- Trigger orders are rejected; `nSigFigs` and `mantissa` on `l2Book` are ignored.
- Fill hashes are placeholders derived from the trade id.
- Prices are a random walk, not anchored to Hyperliquid (`price-anchor` is planned).
