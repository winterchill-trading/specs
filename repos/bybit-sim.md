# bybit-sim

Bybit v5 linear perpetual simulator: REST under `/v5`, public stream
`/v5/public/linear` and private stream `/v5/private`, over `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/bybit-sim` |
| opam package | `bybit-sim` |
| Library | `bybit-sim` (module `Bybit_sim`) |
| Binary | `bybit-sim` (`-port` 3400, `-seed`, `-vol-bps`, `-symbols`, `-noise-traders`, `-initial-balance`, `-log-level`) |
| Status | done |

## Key modules

- `Adapt`: universe and Bybit trading rules, validation, engine rejection to `retCode`
  or `rejectReason`, conversions to `bybit-protocol` types.
- `Orders`: order registry: Bybit order ids stable across amends, cumulative fills,
  status, reject reason, closed history.
- `Venue`: the engine plus the registry: trading and account endpoints, event buffering
  for the streams.
- `Server`: cohttp-async server for REST and both websocket streams; drives the clock
  and the market simulation.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`,
  `bybit-protocol`, `order-book`.
- Used by: `bybit-client` (tests); built as an image by `infra`; target of
  `market-maker -venue bybit -network local`.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`,
`bybit-protocol`.

## Behaviour

Described in [design/simulators.md](../design/simulators.md). `X-BAPI-API-KEY` is the
account; `X-BAPI-TIMESTAMP` must be within `X-BAPI-RECV-WINDOW` of the server clock;
`X-BAPI-SIGN` is ignored. Create returns only an acknowledgement; the order's fate is on
`/v5/order/realtime` and the `order` topic.

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
