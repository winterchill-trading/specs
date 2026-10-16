# bybit-sim

Bybit v5 linear perpetual simulator: REST under `/v5`, public stream
`/v5/public/linear` and private stream `/v5/private`, over `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/bybit-sim` |
| opam packages | `bybit-sim` (library), `bybit-sim-anchor` (anchor library and binary) |
| Libraries | `bybit-sim` (module `Bybit_sim`), `bybit-sim-anchor` (module `Bybit_sim_anchor`) |
| Binary | `bybit-sim` (`-port` 3400, `-seed`, `-vol-bps`, `-symbols`, `-noise-traders`, `-initial-balance`, `-log-level`; `-anchor VENUE:SYMBOL=SIMSYM` (repeatable), `-anchor-levels`, `-anchor-mark-interval-ms`, `-anchor-max-staleness-ms`, `-anchor-noise`, `-anchor-price-factor`, `-anchor-size-factor`, `-anchor-raw DIR` / `-anchor-norm DIR` with `-anchor-from T -anchor-to T`, `-anchor-speed X`, `-anchor-status-interval-s`, `-input-journal FILE`; guards, off by default: `-collar-bps N` / `-collar-ticks N`, `-collar-reference last|mid|mark`, `-collar-action reject|reprice`, `-halt-levels PCT:DURATION,...`, `-halt-scope market|symbol`) |
| Status | done |

## Key modules

- `Adapt`: universe and Bybit trading rules, validation, engine rejection to `retCode`
  or `rejectReason`, conversions to `bybit-protocol` types.
- `Orders`: order registry: Bybit order ids stable across amends, cumulative fills,
  status, reject reason, closed history.
- `Venue`: the engine plus the registry: trading and account endpoints, event buffering
  for the streams.
- `Guard`: the price collar and halt rule flags, set through the engine's recorded calls
  (after `-input-journal` is attached); the `GET /sim/guard` status; tells a collar
  rejection from a tick error by the engine's `collar_rejected` counter.
- `Server`: cohttp-async server for REST and both websocket streams; drives the clock
  and the market simulation; clock step hooks and plain JSON routes for simulator
  endpoints, `POST /sim/reopen`. `Venue.sync` drains the guard log.
- `Bybit_sim_anchor.Spec`, `Reference`, `Anchors` (package `bybit-sim-anchor`): the
  `-anchor` argument, the reference venues' live feeds and raw normalizers (Bybit and
  Binance clients), and the anchors of a running server (sources, clock hook,
  `GET /sim/anchor` status, periodic summary). See
  [design/price-anchor.md](../design/price-anchor.md).

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`,
  `bybit-protocol`, `order-book`; `bybit-sim-anchor` also on `market-data`,
  `price-anchor`, `bybit-client` and `binance-client` (a separate package because
  `bybit-client`'s tests depend on the `bybit-sim` library).
- Used by: `bybit-client` (tests); built as an image by `infra`; target of
  `market-maker -venue bybit -network local`.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`, `parquet`,
`market-data`, `price-anchor`, `venue-net`, `bybit-protocol`, `binance-protocol`,
`mm-core`, `bybit-client`, `binance-client`.

## Behaviour

Described in [design/simulators.md](../design/simulators.md). `X-BAPI-API-KEY` is the
account; `X-BAPI-TIMESTAMP` must be within `X-BAPI-RECV-WINDOW` of the server clock;
`X-BAPI-SIGN` is ignored. Create returns only an acknowledgement; the order's fate is on
`/v5/order/realtime` and the `order` topic.

Price collar and halts are off unless their flags are given (collar reference: last
trade, or the mark when anchored). A limit order beyond the collar (create, batch item or
amend) gets retCode 110003 `Order price exceeds the allowable range: max buy price
<bound>.` (`min sell price` for a sell); an order that would trade during a halt gets
10001 `params error: symbol is halted` (simulator choice; Bybit publishes no perp halt
code). `GET /sim/guard` and `POST /sim/reopen` (`?symbol=`) are simulator endpoints.
`scripts/collar-e2e.sh` runs `market-maker` against a 50 bps collar.

## Known gaps

- `category=linear`, one-way mode, cross margin, 10x everywhere; no conditional, TP/SL,
  trailing or RPI orders, no SMP settings, no leverage endpoint, no `maxOrderQty`.
- Signatures, rate limits and key permissions are not checked.
- Amend is cancel and replace in the engine: the order keeps its id but loses queue
  position.
- Pagination cursors are always `""`; `execution/list` ignores time and type filters.
- Tickers lack 24h statistics and open interest; index equals mark.
- `cumRealisedPnl` is lost when a position is closed and reopened; the liquidation price
  is the engine's estimate.
