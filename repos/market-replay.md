# market-replay

A `tardis-machine` style replay server for the raw minute files `market-recorder` writes.
Recorded frames come back over HTTP as raw lines, or over websockets that speak each
venue's own subscribe protocol, so the venue clients and everything built on them run
against history unchanged.

| | |
| --- | --- |
| Repository | `winterchill-trading/market-replay` |
| opam package | `market-replay` |
| Library | `market-replay` (module `Market_replay`) |
| Binary | `market-replay -data-dir DIR [-port 8800] [-from TIME] [-to TIME] [-speed X]` |
| Status | done (HTTP replay, websocket replay for the eight crypto venues, monitoring, end-to-end script) |

## Endpoints

| Route | Behaviour |
| --- | --- |
| `GET /replay?venue=&symbol=&streams=&from=&to=` | Recorded `<recv_ts> <frame>` lines of the series, merged by `recv_ts`, chunked `application/x-ndjson`, as fast as the client reads; an empty line for a recorded disconnect. Any recorded venue. |
| `GET /ws/<venue>[/...]` | Websocket for `hyperliquid`, `binance`, `bybit`, `okx`, `coinbase`, `kraken` (spot v2 and futures v1 on one path), `deribit` and `bitget`: the client's real subscribe messages are acknowledged like the venue does, then the recorded data frames of the subscribed series are replayed from `-from`, paced by `-speed` (1 real time, 0 as fast as possible) with the recorded gaps kept. `from`, `to` and `speed` query parameters override the flags per connection. |
| `GET /fapi/v1/depth?symbol=` | The last recorded Binance depth snapshot body a websocket replay has passed, for binance-client's book sync (`503` before one has). At speed 0 the replay stops at the diff that snapshot joins at until it has been served and not asked for again for 300 ms (at most 3 s). |
| `GET /healthz`, `GET /metrics` | `ok`; Prometheus counters of HTTP requests and lines, and per venue websocket connections, open clients, frames, replies and skipped gaps. |

## Key modules

| Module | Purpose |
| --- | --- |
| `Raw_line` | The recorder's line format (`format_ts` matches `Raw_writer` and round-trips through `Market_data.Raw_minute.Line.parse`), `from`/`to` parsing |
| `Source` | Recorded items for a venue, symbols, streams and range, merged by `recv_ts`; `of_data_dir` reads with `Market_data.Raw_reader`, `of_items` for tests |
| `Replay_request` | The `/replay` query |
| `Venue_protocol` | Parses Binance `SUBSCRIBE`, Bybit `subscribe`/`ping` and Hyperliquid `subscribe`/`ping` with the protocol libraries' codecs, and OKX, Bitget (`op`/`args`, text `ping`), Coinbase (`type`/`channel`), Kraken (spot `method`/`params`, futures `event`/`feed`) and Deribit (JSON-RPC `public/subscribe`, `public/test`, `public/set_heartbeat`) with Yojson; builds the venue-shaped replies, maps subscriptions to recorded series, and tells data frames from recorded acknowledgements, pongs, heartbeats and REST bodies. `Session` keeps per-connection state: Coinbase's subscription list and its per-connection `sequence_num`, which replaces the recorded one on every frame sent |
| `Ws_replay` | One session: subscriptions, a k-way merge that accepts series added mid-replay (they join at the current position), pacing on a `Time_source`, 200 ms settle after the first subscribe, an optional `hold` after each item |
| `Metrics` | Counters and Prometheus text |
| `Server` | All routes on one port (`Cohttp_async.Server.create_expert` with same-port websocket upgrade) |

## Tests

- `test_clients.ml`: `hl-client`, `bybit-client` and `binance-client` `Live_feed`s
  connect to the server and receive normalized trades, BBOs, L2 updates and funding from
  recorded fixture minutes (Binance syncs its book from a replayed depth snapshot at
  speed 0 and then reports deltas).
- `test_feed_clients.ml`: the `okx-feed`, `coinbase-feed`, `kraken-feed`,
  `deribit-feed` and `bitget-feed` `Live_feed`s do the same over each feed's own fixture
  minute (copied under `test/fixtures/raw`), with no parse errors; Coinbase and Kraken
  books sync without a resubscribe.
- `test_ws_replay.ml`: pacing on a synthetic clock at speeds 1, 2 and 0, a late
  subscription joining mid-replay, gaps skipped.
- `scripts/e2e-replay.sh`: records the three simulators with `market-recorder`, checks
  that `/replay` serves every recorded line, then points a second `market-recorder` at
  the replay server through `Custom` endpoints and checks that every recorded data frame
  arrives and normalizes without parse errors. A 60 s run served all 3,297 recorded
  lines of the ten series over HTTP and delivered all 3,270 data frames over websockets.

## Dependencies

- Depends on: `market-data`, `hl-protocol`, `binance-protocol`, `bybit-protocol` (and
  cohttp-async, async_websocket); tests on `hl-client`, `binance-client`, `bybit-client`,
  `okx-feed`, `coinbase-feed`, `kraken-feed`, `deribit-feed`, `bitget-feed`.
- Used by: nothing yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `venue-net`, `okx-feed`,
`coinbase-feed`, `kraken-feed`, `deribit-feed`, `bitget-feed`, `hl-protocol`,
`binance-protocol`, `bybit-protocol`, `mm-core`, `hl-client`, `binance-client`,
`bybit-client`.

## Design

See [design/data-platform.md](../design/data-platform.md) and
[ADR 0004](../adr/0004-tardis-compatible-raw-format.md).

## Known gaps

- The TradFi venues are served over HTTP only.
- Filtering is per recorded series, not per channel: OKX funding files hold
  `funding-rate`, `mark-price` and `index-tickers`, and a subscriber to one gets all three.
- The server sends no heartbeats of its own (Deribit `public/set_heartbeat`, Kraken and
  Coinbase heartbeat channels); it answers client pings.
- Frames are sent as recorded: a subscription to a different variant of a stream than the
  recorded one (Bybit `orderbook.200` against `orderbook.50`) receives the recorded one.
- Recorded disconnects are skipped on websockets rather than replayed as a dropped
  connection.
