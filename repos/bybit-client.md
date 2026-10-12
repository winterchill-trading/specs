# bybit-client

Async client for the Bybit v5 HTTP and websocket API (category `linear`), a normalized
`Live_feed`, and the `Mm_core.Venue.S` adapter that runs the market maker on Bybit or
`bybit-sim`.

| | |
| --- | --- |
| Repository | `winterchill-trading/bybit-client` |
| opam package | `bybit-client` |
| Library | `bybit-client` (module `Bybit_client`) |
| Binary | `bybit-cli` (`orderbook`, `tickers`, `watch`, `feed`) |
| Status | done |

## Key modules

- `Config`: `local` (`:3400`), `mainnet`, `testnet`; secret redacted in sexp.
- `Rest`: every endpoint in `bybit-protocol`; `X-BAPI-*` signed headers; `Api_error`
  distinguishes venue rejections from transport failures.
- `Ws_stream`: shared websocket core: `{"op":"ping"}` keepalive, optional auth step,
  topic set replayed on every connection.
- `Public_ws`, `Private_ws`: the two streams; private auth waits for the ack before
  subscribing.
- `Local_book`: orderbook from snapshots and `u`-consecutive deltas; `Gap` resubscribes.
- `Live_feed` (with pure `Normalizer`): `publicTrade`, `orderbook.1` (BBO),
  `orderbook.<depth>` (L2), `tickers` (funding).
- `Id_map`: Bybit string ids to `int64` (decimal strings map to themselves, others to
  negative numbers).
- `Venue`: `Mm_core.Venue.S` with `config = Config.t`.

## Dependencies

- Depends on: `venue-net`, `bybit-protocol`, `exchange-core`, `mm-core`, `market-data`.
- Test-only: `bybit-sim`, `exchange-core-engine`.
- Used by: `market-maker`, `market-recorder`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `order-book`,
`exchange-core-engine`, `venue-net`, `bybit-protocol`, `mm-core`, `bybit-sim`.

## Known gaps

- Inherited `UNVERIFIED` items from `bybit-protocol`.
- Checked against the simulator only: private subscribe after auth ack, consecutive `u`
  on the real API, `GET /v5/order/realtime` by id returning recently closed orders,
  no snapshot on the `execution` topic, one `create-batch` item per request item.
- `Fill.closed_pnl` is `None` (Bybit reports closed PnL per order and position);
  `realized_pnl` is after fees and funding; negative `Id_map` ids are stable only per
  `Venue.t`.
- The README's opam pin list omits `parquet` and `market-data`, which CI pins.
