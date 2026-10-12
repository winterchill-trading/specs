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
  `Config.Read_only` has no keys and reaches public endpoints only: everything that sends
  a key (orders, account, listen keys, `User_ws`, `Venue`) takes `Config.t`, so passing a
  read-only config is a compile error (`test/must_fail` pins the message).
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
  `@markPrice@1s`). `Live_feed.start` keeps a handle whose `stats` count frames, parse
  errors and reconnects; `?time_source` stamps `recv_ts` and drives backoff.
- `Venue`: `Mm_core.Venue.S` with `config = Config.t`.

## Tests and benchmark

`test/fixtures/*.jsonl` hold BTCUSDT mainnet frames per stream (2026-10-12); every frame
normalizes (150 trades, 200 BBOs, 59 funding records, one L2 snapshot and 40 deltas) and
minor words per message are printed. `Live_feed` runs against a scripted local server (a
malformed frame in `stats`, a reconnect on a synthetic clock). Test pipes are read with
`Pipe_read` instead of `with_timeout` around `Pipe.read`, which left a read pending that
swallowed the next value. `bench/main.exe`: about 2.5 us and 480 minor words per trades,
bbo or funding frame.

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
