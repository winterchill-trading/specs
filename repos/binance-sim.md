# binance-sim

Binance USD-M Futures simulator: REST under `/fapi`, market streams on `/ws` and
`/stream`, and the listen-key user data stream, over `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/binance-sim` |
| opam packages | `binance-sim` (library), `binance-sim-anchor` (anchor library and binary) |
| Libraries | `binance-sim` (module `Binance_sim`), `binance-sim-anchor` (module `Binance_sim_anchor`) |
| Binary | `binance-sim` (`-port` 3300, `-seed`, `-vol-bps`, `-symbols`, `-noise-traders`, `-initial-balance`, `-log-level`; `-anchor VENUE:SYMBOL=SIM` (repeatable), `-anchor-levels`, `-anchor-mark-interval-ms`, `-anchor-max-staleness-ms`, `-anchor-noise`, `-anchor-price-factor`, `-anchor-size-factor`, `-anchor-raw DIR` / `-anchor-norm DIR` with `-anchor-from T -anchor-to T`, `-anchor-speed X`; guards, off by default: `-collar-bps N` / `-collar-ticks N`, `-collar-reference last\|mid\|mark`, `-collar-action reject\|reprice`, `-halt-levels PCT:DURATION,...`, `-halt-scope market\|symbol`) |
| Status | done |

## Key modules

- `Adapt`: universe and trading rules (BTCUSDT, ETHUSDT, SOLUSDT), validation with
  Binance error codes, order objects, `User_trade`, `Account` (v2), `Position_risk`,
  `Depth`, `Book_ticker`, `Premium_index`, `Exchange_info`, stream payloads, per-order
  state behind `ORDER_TRADE_UPDATE`.
- `Params`: query-string and form parameters to typed requests, with Binance's
  parameter errors.
- `Guard`: the price collar and halt rule flags, set through the engine's recorded calls;
  the `GET /sim/guard` status; tells a collar rejection from a tick error by the engine's
  `collar_rejected` counter.
- `Server`: cohttp-async server, depth sequencing (`U`/`u`/`pu`), listen keys, market
  simulation timer; clock step hooks, extra `GET` routes and websocket `pushback`;
  drains the guard log after every mutation, `GET /sim/guard`, `POST /sim/reopen`.
- `Binance_sim_anchor.Spec`, `Reference`, `Anchored`: the `-anchor` flags, live
  (`binance-client` `Live_feed`), raw (`Raw_normalizer`) and norm sources, one
  `Price_anchor.Anchor.t` per flag stepped by the server clock, `GET /sim/anchor`.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`,
  `binance-protocol`, `order-book`; `binance-sim-anchor` also on `market-data`,
  `price-anchor` and `binance-client`. The split keeps `binance-sim` free of
  `binance-client`, whose tests depend on it.
- Used by: `binance-client` (tests); built as an image by `infra`; target of
  `market-maker -venue binance -network local`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `order-book`,
`exchange-core-engine`, `venue-net`, `binance-protocol`, `mm-core`, `price-anchor`,
`binance-client`.

## Behaviour

Described in [design/simulators.md](../design/simulators.md); anchoring in
[design/price-anchor.md](../design/price-anchor.md). A recorded source steps the server
clock at `-anchor-speed` times the wall clock (frozen at 0), so funding and staleness
stay in recorded time; at speed 0 each item waits for websocket clients to read the
previous one. The `X-MBX-APIKEY` header
is the account; signed endpoints need the header and a `timestamp`; `signature` and
`recvWindow` are accepted and ignored. Fees are taker 5 bps, maker 2 bps; funding every
8 hours at 0.01%.

Price collar and halts are off unless their flags are given (collar reference: last
trade, or the mark when anchored). A buy beyond the collar gets
`-4016 Limit price can't be higher than <bound>.`, a sell
`-4024 Limit price can't be lower than <bound>.` (Binance's PERCENT_PRICE errors); an
off-tick price stays `-4014`. A halt rejection gets `-2010 Trading is halted.` (simulator
choice; Binance publishes no USD-M halt code). With a bps collar, `exchangeInfo`'s
`PERCENT_PRICE` multipliers show the band. `GET /sim/guard` (camelCase counters
`collarRejected`, ...) and `POST /sim/reopen` (`?symbol=`) are simulator endpoints.
`scripts/collar-e2e.sh` runs `market-maker` against a 50 bps collar.

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
- Anchor references are Binance only (no other venue's client is linked); a slowed replay
  stamps data in recorded time, behind the wall clock.
