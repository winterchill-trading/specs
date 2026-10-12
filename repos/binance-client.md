# binance-client

Async client for the Binance USD-M Futures API (REST, local order book, market and user
streams), a normalized `Live_feed`, and the `Mm_core.Venue.S` adapter that runs the
market maker on Binance or `binance-sim`.

| | |
| --- | --- |
| Repository | `winterchill-trading/binance-client` |
| opam package | `binance-client` |
| Library | `binance-client` (module `Binance_client`) |
| Binary | `binance-cli` (`depth`, `book-ticker`, `watch`, `feed`) |
| Status | done |

## Key modules

- `Config`: `local` (`:3300`), `mainnet` (routed websocket paths `/public`, `/market`,
  `/private`), `testnet`; API key, optional secret and `recv_window`.
- `Rest`: every endpoint in `binance-protocol`; `Signed` requests append `timestamp` and,
  with a secret, the HMAC signature; `api_error` recovers `Api_error.t`.
- `Market_ws`: one combined-stream connection, acknowledged `SUBSCRIBE`, resubscribe on
  reconnect.
- `User_ws`: listen key creation, 30-minute keepalive, renewal on `-1125` or
  `listenKeyExpired`.
- `Local_book`, `Book_sync`: Binance's diff-depth procedure (`U`/`u`/`pu`) with gap
  detection and resync.
- `Feed_normalizer`, `Live_feed`: pure frame-to-event conversion and the
  `Market_data.Feed.t` (`@aggTrade`, `@bookTicker`, `@depth@100ms` plus snapshot,
  `@markPrice@1s`).
- `Venue`: `Mm_core.Venue.S` with `config = Config.t`.

## Dependencies

- Depends on: `venue-net`, `binance-protocol`, `exchange-core`, `mm-core`,
  `market-data`, `fixed-decimal`.
- Test-only: `binance-sim`, `exchange-core-engine`.
- Used by: `market-maker`, `market-recorder`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `order-book`,
`exchange-core-engine`, `venue-net`, `binance-protocol`, `mm-core`, `binance-sim`.

## Known gaps

- Unverified against live Binance: partial-depth payload shape, `ACCOUNT_UPDATE`
  position fields, `er`, filters other than `PRICE_FILTER`, `batchOrders` encoding,
  testnet routing and hosts.
- Not implemented: RSA/Ed25519 keys, server time synchronisation, rate-limit tracking,
  leverage brackets and commission endpoints.
- The README's opam pin list omits `parquet` and `market-data`, which CI pins.
