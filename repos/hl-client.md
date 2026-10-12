# hl-client

Async client for the Hyperliquid HTTP and websocket API, for `hl-sim` and the real API,
plus a normalized `Live_feed` for the data platform.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-client` |
| opam package | `hl-client` |
| Library | `hl-client` (module `Hl_client`) |
| Binary | `hl-cli` (`l2book`, `mids`, `watch`, `feed`) |
| Status | done |

## Key modules

- `Config`: `base_url`, `ws_url`, default `address`; `local` (`localhost:3000`),
  `mainnet`, `testnet`.
- `Info`: `POST /info` (`l2_book`, `all_mids`, `open_orders`, `user_fills`,
  `clearinghouse_state`, `meta`).
- `Exchange`: `POST /exchange` (`place_orders`, `cancel`, `cancel_by_cloid`, `modify`);
  nonce strictly increasing per process; `X-Address` header when an address is set;
  optional `~sign` hook.
- `Ws`: typed websocket over `Venue_net.Ws_client` with `{"method":"ping"}` keepalive,
  subscription set replayed on reconnect, `on_reconnect`.
- `Http`: JSON POST over `Venue_net.Http`.
- `Live_feed`: `create ?on_raw config ~symbols ~streams` returning `Market_data.Feed.t`;
  instruments are `hyperliquid:<coin>`. `Trades` from `trades`, `L2` from `l2Book`
  (always a `Snapshot`), `Bbo` from `l2Book` when the top changes, `Funding` from
  `activeAssetCtx`.

## Dependencies

- Depends on: `hl-protocol`, `market-data`, `venue-net`.
- Used by: `hl-mm`, `market-maker`, `market-recorder`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`,
`venue-net`.

## Known gaps

- Request signing is out of scope: `Exchange` sends unsigned requests unless a `~sign`
  hook is passed, so only the simulator accepts orders. `Info` and `Ws` work against
  Hyperliquid as is.
- `Funding` has no venue timestamp (`exch_ts` = `recv_ts`) and is not served by the
  simulator.
- Updates during a reconnect gap are lost; callers resync with `on_reconnect`.
- `opam` lists `async_websocket`, which the library does not use directly.
