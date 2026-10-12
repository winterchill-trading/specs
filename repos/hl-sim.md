# hl-sim

Hyperliquid exchange simulator: an HTTP and websocket server speaking Hyperliquid's
public API over `exchange-core-engine`, with the engine's market simulation.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-sim` |
| opam package | `hl-sim` |
| Library | `hl-sim` (module `Hl_sim`) |
| Binary | `hl-sim` (`-port` 3000, `-seed`, `-vol-bps`, `-coins`, `-noise-traders`, `-initial-balance`, `-response-delay-ms`, `-journal`, `-input-journal`, `-log-level`; price anchor: `-anchor VENUE:SYMBOL=COIN` (repeatable), `-anchor-raw DIR` / `-anchor-norm DIR` with `-anchor-from`, `-anchor-to`, `-anchor-speed`, `-anchor-base-url`, `-anchor-levels`, `-anchor-mark-interval-ms`, `-anchor-max-staleness-ms`, `-anchor-noise`, `-anchor-price-factor`, `-anchor-size-factor`, `-anchor-status-interval-s`) |
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
- `Anchoring`: price anchors over `price-anchor`. Parses `-anchor` specs, builds the
  reference source (the `Live_feed` of `hl-client` or `binance-client`, raw minute files
  through their `Raw_normalizer`, or event logs), creates the anchor inside
  `Server.mutate`, runs its `step` from `Server.on_clock_step` and publishes the events
  of each reference item to websocket subscribers; `status` for `GET /status`.
- `Server`: cohttp-async server for `POST /info`, `POST /exchange`, `GET /status` and the `/ws`
  websocket on the same port; owns the engine and its timers. `-response-delay-ms`
  delays every `/exchange` response while the order and its websocket events take effect
  at once, for double-placement tests. Each connection may queue at most 10,000 messages
  (`Config.max_ws_queue`); a subscriber that stops reading is disconnected and counted,
  without delaying other clients' acks.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`, `hl-protocol`,
  `order-book`, `market-data`, `price-anchor`, `hl-client`, `binance-client`.
- Used by: `hl-mm` (tests); built as an image by `infra`; target of `market-maker
  -venue hyperliquid -network local`.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`, `hl-protocol`,
`parquet`, `market-data`, `price-anchor`, `venue-net`, `hl-client`, `binance-protocol`,
`mm-core`, `binance-client` (through the shared `ox-setup` action).

## Behaviour

Described in [design/simulators.md](../design/simulators.md). In short: the acting
address is the `X-Address` header, else `vaultAddress`, else `0x...01`; every address
seen is credited `-initial-balance` USD; signatures are not verified.

## Known gaps

- `activeAssetCtx` is decoded by hl-sim's own module, not yet by `hl-protocol`.
- Trigger orders are rejected; `nSigFigs` and `mantissa` on `l2Book` are ignored.
- Fill hashes are placeholders derived from the trade id.
- Without `-anchor`, prices are the market simulation's random walk. Live references
  exist for Hyperliquid and Binance only (the clients linked in); a Bybit or feed-repo
  reference needs its client added. `Server.replay` of the JSON `-journal` does not
  cover anchored runs; the binary `-input-journal` does.
