# hl-protocol

Hyperliquid wire types and JSON codecs for the public HTTP (`/info`, `/exchange`) and
websocket API. Types and codecs only, no I/O.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-protocol` |
| opam package | `hl-protocol` |
| Library | `hl-protocol` (module `Hl_protocol`) |
| Binaries | none |
| Status | done |

## Key modules

- Primitives re-exported from `exchange-core` with type equalities and Hyperliquid
  encodings: `Price`, `Size`, `Usd`, `Coin` (= `Symbol`), `Address` (= `Account`,
  lowercased), `Side` (`"B"`/`"A"`), `Tif`, `Order_id`, `Cloid` (`0x` + 32 hex digits).
  Venue-specific: `Asset`, `Tpsl`, `Order_type`, `Json`, `Codec` (`module type S`).
- Exchange endpoint: `Order_request`, `Cancel_request`, `Cancel_by_cloid`,
  `Modify_request`, `Grouping`, `Exchange_action`, `Exchange_request`, `Order_status`,
  `Cancel_status`, `Exchange_response`.
- Info endpoint: `Info_request` (`l2Book`, `allMids`, `openOrders`, `userFills`,
  `clearinghouseState`, `meta`), `Info_response`, `L2_book`, `All_mids`, `Open_order`,
  `User_fill`, `Clearinghouse_state`, `Meta`.
- Websocket: `Subscription`, `Ws_request`, `Trade`, `Order_update`, `Ws_message`, and
  `Asset_ctx` for the `activeAssetCtx` channel (funding, mark, oracle, volumes):
  `Asset_ctx.Request` builds its (un)subscribe requests and `Asset_ctx.of_ws_message`
  reads it from `Ws_message.Unknown`, so the exhaustively matched variants stay as they
  are. `subscriptionResponse` echoes of unmodelled subscriptions also stay `Unknown`.
- `Clearinghouse_state`: `liquidationPx` is an option, `None` when absent, `null` or
  outside the fixed-point range (about 4.6e10).

## Coverage

`test/fixtures/mainnet-info-ws-2026-10-12` (trimmed info responses and websocket frames
of one account) and `test/fixtures/hyperliquid-BTC-2026-10-12T13-35` (a recorded raw
minute) are decoded and re-encoded by tests. Verified against these mainnet samples: the
six info responses (including large and `null` `liquidationPx`), the websocket requests,
`subscriptionResponse`, `trades`, `l2Book`, `allMids`, `userFills`, `orderUpdates`,
`activeAssetCtx` (perps), `pong` and `error`. The exchange requests and responses are
checked against hand-written samples and the simulator only.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`.
- Used by: `hl-sim`, `hl-client`, `hl-mm`, `market-maker`.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Known gaps

- Signatures are opaque JSON here; `hl-client`'s `Signing` produces them.
- Numbers are re-encoded in shortest form; digits past the 8th decimal are dropped.
- Only the listed fields are kept. Unknown channels decode to `Ws_message.Unknown`,
  unknown order statuses to `Order_update.Status.Other`.
- `Subscription` and `Ws_message` have no `activeAssetCtx` constructor; it is reached
  through `Asset_ctx` and `Unknown`. The spot shape of `activeAssetCtx` comes from a
  sample only.
