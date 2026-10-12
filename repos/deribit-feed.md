# deribit-feed

Read-only public market data from Deribit over its JSON-RPC websocket API, as a
`Market_data.Feed.t`: trades, best bid and offer, L2 snapshots and deltas, and perpetual
funding. No API keys, no order entry.

| | |
| --- | --- |
| Repository | `winterchill-trading/deribit-feed` |
| opam package | `deribit-feed` |
| Library | `deribit-feed` (module `Deribit_feed`) |
| Binary | `deribit-feed feed -symbol SYMS -streams ... [-count N] [-testnet] [-interval I] [-raw]`, `deribit-feed rebuild-norm -data-dir DIR -out NEW_DIR -date YYYY-MM-DD` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | Mainnet, testnet or custom endpoint, and the notification interval (`100ms` default) |
| `Wire` | JSON-RPC messages and channel names |
| `Normalizer` | Pure frame to event conversion with per-instrument book sequencing |
| `Live_feed` | One socket per stream; `public/test` keepalive and `public/set_heartbeat`; reconnect and resubscribe; `start` returns a handle whose `stats` count frames, parse errors and reconnects; `?time_source` (default the wall clock) stamps `recv_ts` and drives keepalive and backoff |
| `Rebuild_normalizer` | `Normalizer` as a `Market_data.Normalizer.S` (several outputs per frame concatenated), behind `rebuild-norm` |

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

## Tests and benchmark

`test/fixtures/raw/deribit/<stream>/BTC-PERPETUAL/2026/10/12/16-54.ndjson` holds the
first 20 to 200 frames per stream of a mainnet `market-recorder` minute (240 KB): 98
trades, 198 BBOs, a full-depth snapshot and 37 deltas, 36 funding records, no errors.
`rebuild-norm` over it writes 370 events from 320 frames; over the untrimmed three-minute
recording (3311 frames, 4 disconnects) it wrote 3613 events with no rejected frame.
`Live_feed` is tested against a scripted local server (malformed frame in `stats`; no
reconnect before 0.39 s, reconnected and resubscribed by 0.6 s on a synthetic clock).
Minor words are pinned within 8 words or 3%. `bench/main.exe` on an M-series Mac:
trades 15.0 us per frame (1660 bytes, several prints), bbo 2.3 us, funding 6.2 us, a
40-frame book replay with a full-depth snapshot 1.54 ms.

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
