# bybit-protocol

Bybit v5 wire types and JSON codecs for category `linear` (USDT perpetuals), plus
HMAC-SHA256 signing for REST and websocket auth. No I/O. Reference notes are in the
repository's `docs/bybit-v5-spec.md`.

| | |
| --- | --- |
| Repository | `winterchill-trading/bybit-protocol` |
| opam package | `bybit-protocol` |
| Library | `bybit-protocol` (module `Bybit_protocol`) |
| Binaries | none |
| Status | done |

## Key modules

- Primitives: `Price`, `Size`, `Usd` (with `Or_empty` for `""`), `Symbol`, `Side`,
  `Order_link_id` re-exported from `exchange-core`; `Decimal`, `Or_empty`, `Category`,
  `Order_type`, `Time_in_force`, `Order_status`, `Position_idx`, `Reject_reason`,
  `Exec_type`, `Timestamp_ms`, `Order_id` and `Exec_id` (strings: UUIDs or digits),
  `Book_level`, `Json`, `Codec`.
- REST: `Envelope` (`retCode` envelope, `Envelope.Error`), `Page`, `Instruments_info`,
  `Orderbook`, `Tickers`, `Create_order`, `Create_batch`, `Cancel_order`, `Cancel_all`,
  `Amend_order`, `Order_ack`, `Realtime_order`, `Execution`, `Position`,
  `Wallet_balance`, `Signature`.
- Websocket: `Topic`, `Ws_request`, `Op_response`, `Update_type`, `Ws_orderbook`,
  `Public_trade`, `Ws_ticker` (`Data.apply` merges deltas), `Private_push`, `Ws_message`.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core` (and cryptokit).
- Used by: `bybit-sim`, `bybit-client`, `market-maker`.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Known gaps

Marked `UNVERIFIED` in the source:

- Error envelope shape (`result` may be `{}` or `null`, so it is not decoded on errors).
- The GET signing string is the query string as sent.
- Linear examples for tickers, position list and create-batch (inverse/spot examples
  were used).
- Subscribe failure and auth ack shapes (`Op_response`).
- Ticker deltas always include `symbol`; `RPI` flag on public trades may be absent.
- No dedicated reduce-only retCode (110017 is used).
- Recv window maximum, rate limits and orderbook depth 500 are not modelled.

Not modelled: conditional orders, TP/SL, SMP, fee details, option fields. Coin wallet
amounts are typed `Usd.t` even for non-USD coins.
