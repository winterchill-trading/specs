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
- Copy trading, each in its own module so the exhaustively matched `Exchange_action`,
  `Info_request` and `Subscription` keep their constructors:
  `User_signed_action` (`approveAgent`, `approveBuilderFee`, with the EIP-712 primary
  type and typed fields), `User_signed_request` (their `/exchange` body and
  `is_user_signed_body` for servers), `Builder_fee` (the order `builder: {b, f}` field,
  `f` in tenths of a basis point, and `maxFeeRate` percent strings), `Order_action` (an
  `order` action with the builder, keys in the SDK's order), `Exchange_envelope` (an
  `/exchange` body around raw action JSON, with `expiresAfter`), `User_fills_by_time`
  (`userFillsByTime`), `Max_builder_fee` (`maxBuilderFee`, the approved cap in tenths of
  a basis point), `User_event` (`userEvents` of any address, channel `user`, read
  from `Ws_message.Unknown`) and `Leaderboard` (rows of the stats host's leaderboard).
- `Clearinghouse_state`: `liquidationPx` is an option, `None` when absent, `null` or
  outside the fixed-point range (about 4.6e10).

## Coverage

`test/fixtures/mainnet-info-ws-2026-10-12` (trimmed info responses and websocket frames
of one account) and `test/fixtures/hyperliquid-BTC-2026-10-12T13-35` (a recorded raw
minute) are decoded and re-encoded by tests. Verified against these mainnet samples: the
six info responses (including large and `null` `liquidationPx`), the websocket requests,
`subscriptionResponse`, `trades`, `l2Book`, `allMids`, `userFills`, `orderUpdates`,
`activeAssetCtx` (perps), `pong` and `error`. The exchange requests and responses are
checked against hand-written samples and the simulator only. The approval actions, the
builder field and `userEvents` follow the documentation's examples;
`test/fixtures/testnet-leaderboard-2026-10-13` holds four rows of the testnet leaderboard.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`.
- Used by: `hl-sim`, `hl-client`, `hl-mm`, `market-maker`; planned: `hl-copy-core`,
  `hl-copy-engine`, `hl-copy-api`, `hl-copy-web`, `hl-leaderboard`.

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
- `User_fill.t` drops the `builderFee` and `liquidation` fields of fills, so code that
  builds fill records keeps compiling; `User_fill.Detailed` decodes the same object with
  both (`Liquidation`: `liquidatedUser`, `markPx` as a number or a string, `method`). A server that
  decodes `/exchange` with `Exchange_request` accepts a builder order but loses the
  builder.
