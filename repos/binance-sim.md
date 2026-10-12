# binance-sim

Binance USD-M Futures simulator: REST under `/fapi`, market streams on `/ws` and
`/stream`, and the listen-key user data stream, over `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/binance-sim` |
| opam package | `binance-sim` |
| Library | `binance-sim` (module `Binance_sim`) |
| Binary | `binance-sim` (`-port` 3300, `-seed`, `-vol-bps`, `-symbols`, `-noise-traders`, `-initial-balance`, `-log-level`) |
| Status | done |

## Key modules

- `Adapt`: universe and trading rules (BTCUSDT, ETHUSDT, SOLUSDT), validation with
  Binance error codes, order objects, `User_trade`, `Account` (v2), `Position_risk`,
  `Depth`, `Book_ticker`, `Premium_index`, `Exchange_info`, stream payloads, per-order
  state behind `ORDER_TRADE_UPDATE`.
- `Params`: query-string and form parameters to typed requests, with Binance's
  parameter errors.
- `Server`: cohttp-async server, depth sequencing (`U`/`u`/`pu`), listen keys, market
  simulation timer.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`,
  `binance-protocol`, `order-book`.
- Used by: `binance-client` (tests); built as an image by `infra`; target of
  `market-maker -venue binance -network local`.

## CI pin order

`fixed-decimal`, `exchange-core`, `binance-protocol`, `order-book`,
`exchange-core-engine`.

## Behaviour

Described in [design/simulators.md](../design/simulators.md). The `X-MBX-APIKEY` header
is the account; signed endpoints need the header and a `timestamp`; `signature` and
`recvWindow` are accepted and ignored. Fees are taker 5 bps, maker 2 bps; funding every
8 hours at 0.01%.

## Known gaps

- No signature, `recvWindow`, rate-limit or ban checks; listen keys never expire.
- Only `LIMIT` and `MARKET`; `GTD`, `RPI`, hedge mode, modify/amend, leverage and margin
  type endpoints are absent.
- FOK is checked against depth then sent as IOC; self-trade prevention is "expire
  taker".
- Insufficient margin answers `-2010`; live USD-M may answer `-2019`.
- `PRICE_FILTER` min/max and `PERCENT_PRICE` are published but not enforced.
- Index price equals mark price; funding uses the configured rate.
- `ACCOUNT_UPDATE` reflects the end of the request, not each fill; one trade per
  `aggTrade`.
