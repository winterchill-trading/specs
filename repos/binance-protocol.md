# binance-protocol

Binance USD-M Futures wire types, JSON codecs and HMAC-SHA256 request signing. No I/O.
The API reference the types follow is versioned in the repository's
`docs/binance-usdm-spec.md`.

| | |
| --- | --- |
| Repository | `winterchill-trading/binance-protocol` |
| opam package | `binance-protocol` |
| Library | `binance-protocol` (module `Binance_protocol`) |
| Binaries | none |
| Status | done |

## Key modules

- Primitives: `Price`, `Size`, `Usd`, `Symbol` (uppercased), `Side`, `Order_id`,
  `Trade_id`, `Client_order_id` re-exported from `exchange-core`; `Decimal`,
  `Order_type` (`LIMIT`, `MARKET`, `Other`), `Time_in_force` (with `Exchange_core.Tif`
  conversions), `Order_status`, `Execution_type`, `Position_side`, `Working_type`,
  `Timestamp_ms`, `Json`, `Codec`.
- REST: `Exchange_info` (filters, `to_instrument`), `Depth`, `Book_level`, `Book_ticker`,
  `Premium_index`, `Order`, `New_order`, `Batch_orders`, `Cancel_order`, `Cancel_all`,
  `Open_order`, `User_trade`, `Account`, `Position_risk`, `Listen_key`, `Api_error`
  (`to_reject_reason`), `Query` (form encoding in insertion order), `Signature`.
- Websocket: `Stream_name`, `Subscribe`, `Combined`, `Depth_update`, `Agg_trade`,
  `Book_ticker_event`, `Mark_price_update`, `Market_event`, `Order_trade_update`,
  `Account_update`, `Listen_key_expired`, `User_event`.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core` (and cryptokit for HMAC).
- Used by: `binance-sim`, `binance-client`, `market-maker`.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Known gaps

Marked `UNVERIFIED` in the source and implemented in their most common shape:

- Market stream payloads (`depthUpdate`, `aggTrade`, `bookTicker`, `markPriceUpdate`);
  binance-client has since decoded these on mainnet.
- Partial-depth streams (`@depth5/10/20`): assumed to send `depthUpdate`; the snapshot
  shape decodes as `Depth_snapshot`.
- `ACCOUNT_UPDATE` position fields and the `ORDER_TRADE_UPDATE` `er` field type.
- `exchangeInfo` filters other than `PRICE_FILTER`.
- `batchOrders` request encoding (a JSON array string with string values).
- The `GET /fapi/v2/account` test example, assembled from the field list.

Not modelled: order types other than `LIMIT`/`MARKET` (round-trip as `Other`), RSA and
Ed25519 keys. Digits past the 8th decimal are dropped.
