# coinbase-feed

Read-only public market data for Coinbase spot over the Advanced Trade websocket,
normalized to `market-data` records as a `Market_data.Feed.t`. No API keys, no order
entry.

| | |
| --- | --- |
| Repository | `winterchill-trading/coinbase-feed` |
| opam package | `coinbase-feed` |
| Library | `coinbase-feed` (module `Coinbase_feed`) |
| Binary | `coinbase-feed feed -symbol SYMS -streams ... [-count N] [-seconds S] [-raw]` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | Mainnet endpoint (`wss://advanced-trade-ws.coinbase.com`) or a custom URL |
| `Wire` | Decoders for `market_trades`, `ticker`, `l2_data`, `subscriptions`, `heartbeats`, errors; subscribe requests |
| `Normalizer` | Pure frame to event conversion with per-connection state: sequence number, synced books, last trade id per product |
| `Live_feed` | One websocket per stream, each also subscribed to `heartbeats`; reconnect and resubscribe; `start` keeps a handle whose `stats` count frames, parse errors and reconnects; `?time_source` (default the wall clock) stamps `recv_ts` and drives keepalive and backoff |
| `Raw_normalizer` | `Normalizer` as a `Market_data.Normalizer.S`, for `Market_data.Rebuild_norm` over recorded raw minutes |

| Stream | Coinbase channel |
| --- | --- |
| `trades` | `market_trades`; taker side is the opposite of the wire's maker `side` |
| `bbo` | `ticker` (best bid and ask with quantities) |
| `l2` | `level2` (frames on `l2_data`): snapshot, then deltas |
| `funding` | none (spot); the pipe is closed at creation |

## Sequencing

`sequence_num` counts per connection across channels, so a gap cannot be attributed to
one product: every synced book on the `level2` connection is resubscribed. A new
connection unsyncs the books, and trades are de-duplicated by numeric `trade_id` per
product so the backlog resent on resubscribe is not emitted twice. Tests:
`test/test_normalizer.ml` ("l2: a sequence gap resubscribes every synced product", "l2: a
new connection unsyncs books; late duplicates are dropped", "error and undecodable
frames").

## Tests and benchmark

`test/fixtures/raw/coinbase/<stream>/BTC-USD/2026/10/12/16-54.ndjson` is a recorded
mainnet minute in the `market-recorder` raw layout, cut to stay under 300 KB, with the
`level2` snapshot trimmed to 50 levels a side. Tests normalize every frame (298 trades,
111 quotes, 1 snapshot and 113 deltas, no gap), run `Rebuild_norm` over it and read the
event logs back, pin minor words per message with a small tolerance, and drive
`Live_feed` against a scripted local websocket server (a malformed frame in `stats`, a
reconnect on a synthetic clock). `bench/main.exe` on an M-series Mac: trades 6.2 us and
865 words per frame, bbo 4.0 us and 611 words, a 122-frame book replay 1.73 ms.

## Dependencies

- Depends on: `market-data`, `venue-net`, `exchange-core`.
- Used by: `market-recorder`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `venue-net`.

## Known gaps

- Spot only: no funding, mark or index price.
- `ticker` is sent on matches, not on every top-of-book change, and has no per-ticker
  timestamp: `Bbo.exch_ts` is the frame's envelope time.
- The `level2` snapshot is the whole book in one frame (about 4.5 MB for BTC-USD).
- No book checksum; trades lost beyond the resent backlog after a disconnect are not
  recovered.
