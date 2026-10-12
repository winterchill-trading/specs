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
| `Live_feed` | One websocket per stream, each also subscribed to `heartbeats`; reconnect and resubscribe |

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
