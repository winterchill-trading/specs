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
- Websocket: `Subscription`, `Ws_request`, `Trade`, `Order_update`, `Ws_message`.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`.
- Used by: `hl-sim`, `hl-client`, `hl-mm`, `market-maker`.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Known gaps

- Signatures are opaque JSON, never produced or checked; signing for the real
  `/exchange` endpoint is out of scope.
- Numbers are re-encoded in shortest form; digits past the 8th decimal are dropped.
- Only the listed fields are kept. Unknown channels decode to `Ws_message.Unknown`,
  unknown order statuses to `Order_update.Status.Other`.
- `Subscription` has no `activeAssetCtx`; `hl-client`'s `Live_feed` builds that
  subscription by hand and decodes it from `Ws_message.Unknown`.
