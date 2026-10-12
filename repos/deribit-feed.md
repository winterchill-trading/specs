# deribit-feed

Read-only public market data from Deribit over its JSON-RPC websocket API, as a
`Market_data.Feed.t`: trades, best bid and offer, L2 snapshots and deltas, and perpetual
funding. No API keys, no order entry.

| | |
| --- | --- |
| Repository | `winterchill-trading/deribit-feed` |
| opam package | `deribit-feed` |
| Library | `deribit-feed` (module `Deribit_feed`) |
| Binary | `deribit-feed feed -symbol SYMS -streams ... [-count N] [-testnet] [-interval I] [-raw]` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | Mainnet, testnet or custom endpoint, and the notification interval (`100ms` default) |
| `Wire` | JSON-RPC messages and channel names |
| `Normalizer` | Pure frame to event conversion with per-instrument book sequencing |
| `Live_feed` | One socket per stream; `public/test` keepalive and `public/set_heartbeat`; reconnect and resubscribe |

| Stream | Deribit channel |
| --- | --- |
| `trades` | `trades.<symbol>.100ms`; side is the taker `direction` |
| `bbo` | `quote.<symbol>` (not sequenced) |
| `l2` | `book.<symbol>.100ms`: full snapshot, then deltas chained by `prev_change_id` |
| `funding` | `ticker.<symbol>.100ms`, `rate = funding_8h`; perpetuals only |

Symbols are Deribit instrument names (`deribit:BTC-PERPETUAL`), case sensitive.

## Sequencing

Changes before the snapshot are dropped. A `prev_change_id` that does not match the last
`change_id` unsubscribes and resubscribes the channel once and drops changes until the new
snapshot; a reconnect drops the stream's book state. Tests: `test/test_book.ml`
("deltas before the snapshot are dropped", "a gap resubscribes once, then waits for a new
snapshot", "a change without prev_change_id after a snapshot is a gap", "reset forgets
the book"), `test/test_bad_frames.ml`.

## Dependencies

- Depends on: `market-data`, `venue-net`, `exchange-core`.
- Used by: `market-recorder`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `venue-net`.

## Known gaps

- Sizes are Deribit amounts: USD for perpetuals and futures, coin for options;
  `market-data` has no unit field.
- `next_funding_time` is synthetic (the next 8-hour boundary): Deribit funding accrues
  continuously.
- The unaggregated `raw` interval needs authentication, so all channels are 100 ms
  aggregates; the nanosecond `starbase_timestamp` on trades is ignored.
- `public/subscribe` is rate limited (about 3 per second); a resubscribe storm across
  many books could hit it.
