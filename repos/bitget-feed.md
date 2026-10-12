# bitget-feed

Read-only public market data from Bitget's v2 websocket, normalized to `market-data`
records as a `Market_data.Feed.t`. No API keys, no order entry.

| | |
| --- | --- |
| Repository | `winterchill-trading/bitget-feed` |
| opam package | `bitget-feed` |
| Library | `bitget-feed` (module `Bitget_feed`) |
| Binary | `bitget-feed feed -symbol SYM -streams ... [-count N] [-seconds S] [-inst-type T] [-raw]` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | Endpoint (`wss://ws.bitget.com/v2/ws/public` or custom) and instrument type (`USDT-FUTURES` default) |
| `Wire` | Pushes, acks and errors |
| `Local_book` | Per-subscription `seq`/`pseq` continuity |
| `Checksum` | CRC32 over interleaved top levels, verified when the venue sends one |
| `Normalizer` | Pure frame to event conversion |
| `Live_feed` | One socket per stream, text `ping` every 30 s, reconnect and resubscribe |

| Stream | Bitget channel |
| --- | --- |
| `trades` | `trade`; the 50-trade backlog sent on subscribe is emitted too |
| `bbo` | `books1` |
| `l2` | `books`: snapshot, then deltas |
| `funding` | `ticker`, when rate, next time, mark or index changes |

Symbols are Bitget `instId`s (`bitget:BTCUSDT`); the market (spot or futures) is chosen by
`instType` in `Config`, not by the symbol.

## Sequencing

Deltas before a snapshot are dropped; a break in `seq`/`pseq` drops the book and
unsubscribes and resubscribes it. Tests: `test/test_normalizer.ml` ("books: update before
snapshot, snapshot, deltas, gap, resync", "books: checksum verified when present", "bad
frames and events"), `test/test_checksum.ml`.

## Dependencies

- Depends on: `market-data`, `venue-net`.
- Used by: `market-recorder`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `venue-net`.

## Known gaps

- The instrument does not record the instrument type, so spot and perpetual `BTCUSDT`
  look the same downstream.
- After a reconnect the subscribe backlog repeats recent trades; consumers de-duplicate
  by `trade_id`.
- The live `books` channel currently sends no checksum.
- No streams for open interest or liquidations.
