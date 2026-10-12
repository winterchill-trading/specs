# hl-client

Async client for the Hyperliquid HTTP and websocket API, for `hl-sim` and the real API,
plus a normalized `Live_feed` for the data platform.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-client` |
| opam package | `hl-client` |
| Library | `hl-client` (module `Hl_client`) |
| Binary | `hl-cli` (`l2book`, `mids`, `watch`, `feed`, `address`, `cancel`; `cancel` refuses mainnet without `-allow-mainnet`) |
| Status | done |

## Key modules

- `Config`: `base_url`, `ws_url`, default `address`; `local` (`localhost:3000`),
  `mainnet`, `testnet`.
- `Info`: `POST /info` (`l2_book`, `all_mids`, `open_orders`, `user_fills`,
  `clearinghouse_state`, `meta`).
- `Exchange`: `POST /exchange` (`place_orders`, `cancel`, `cancel_by_cloid`, `modify`);
  nonce strictly increasing per process; `X-Address` header when an address is set;
  optional `~sign` hook.
- `Signing`: L1 action signing as the official Python SDK does it: a pure OCaml
  Keccak-256 and MessagePack encoder hash the action, nonce and vault; the phantom agent
  is hashed as EIP-712 typed data (domain `Exchange`, chain id 1337) and signed with
  secp256k1 (RFC 6979, low s). `Private_key.of_env` reads `HL_PRIVATE_KEY`;
  `sign_request` is an `Exchange.sign` hook. Tests reproduce every L1 vector of the SDK's
  signing tests; a testnet request with a fresh key was attributed to that key's address.
- `Client`: typed handles, `read_only t` and `trading t`. Every `Info` helper takes any
  handle; `place_orders`, `cancel`, `cancel_by_cloid` and `modify` take only a
  `trading t`, which signs when it holds a key (`trading ?key`, `trading_of_env`) and
  sends unsigned requests otherwise (the simulator). `is_mainnet` defaults from the host.
- `Ws`: typed websocket over `Venue_net.Ws_client` with `{"method":"ping"}` keepalive,
  subscription set replayed on reconnect, `on_reconnect`, `?time_source`,
  `?backoff_jitter` and a `reconnects` count.
- `Http`: JSON POST over `Venue_net.Http`.
- `Live_feed`: `create ?on_raw config ~symbols ~streams` returning `Market_data.Feed.t`;
  instruments are `hyperliquid:<coin>`. `Trades` from `trades`, `L2` from `l2Book`
  (always a `Snapshot`), `Bbo` from `l2Book` when the top changes, `Funding` from
  `activeAssetCtx`. `on_raw` sees each `l2Book` frame once (under `L2` when requested,
  else `Bbo`), so a recorder stores it once; `create_with_stats` counts frames, parse
  errors, server error frames and reconnects; `?time_source` stamps `recv_ts`.
- `Normalizer`, `Raw_normalizer`: the pure frame-to-event conversion `Live_feed` runs,
  exposed as a `Market_data.Normalizer.S` adapter so recorded raw files decode offline;
  `hl-cli rebuild-norm` rebuilds event logs from raw minute files. `Live_feed` resets
  the normalizer on every connection, so a reconnect re-emits the top of book.

## Tests

Keccak-256 and MessagePack vectors, the SDK signing vectors, typed handles (a read-only
handle carries no key), loopback websocket tests, reconnects stepped on a synthetic
`Time_source` (none at 990 ms of a 1 s backoff, one at 1 s), and
`test/fixtures/hyperliquid-BTC-2026-10-12T13-35/`, a trimmed mainnet minute recorded by
`market-recorder` whose every frame decodes (40 trades, 6 L2 snapshots, 6 BBOs, 12
funding events).

## Dependencies

- Depends on: `hl-protocol`, `market-data`, `venue-net`, and the `secp256k1` opam
  binding (C library `libsecp256k1`; `digestif` does not build on OxCaml, hence the
  own Keccak).
- Used by: `hl-mm`, `market-maker`, `market-recorder`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`,
`venue-net`.

## Known gaps

- User-signed actions (transfers, withdrawals) are not implemented; only L1 actions are
  signed. No order was placed on testnet yet (the test key was unfunded).
- `Funding` has no venue timestamp (`exch_ts` = `recv_ts`) and is not served by the
  simulator.
- Updates during a reconnect gap are lost; callers resync with `on_reconnect`.
- `opam` lists `async_websocket`, which the library does not use directly.
