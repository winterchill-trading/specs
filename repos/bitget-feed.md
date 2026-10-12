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
| `Live_feed` | One socket per stream, text `ping` every 30 s, reconnect and resubscribe; `?time_source` (default the wall clock) stamps `recv_ts` and drives keepalive and backoff; `create_with_stats` also returns a reader of `Stats.t` (frames, parse errors, `error` events, reconnects) |
| `Raw_normalizer` | `Normalizer` as a `Market_data.Normalizer.S`, for `Market_data.Rebuild_norm` over recorded raw minutes |

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

## Tests and benchmark

`test/fixtures/bitget-BTCUSDT-2026-10-12T16-54` is a trimmed mainnet minute in the
`market-recorder` raw format (230 KB). Tests normalize every frame, run `Rebuild_norm`
over it and read the event logs back, pin minor words per message, and run `Live_feed`
against a loopback Bitget-like server, one test on a synthetic clock. `bench/main.exe`
on an M-series Mac:

| Stream | Frames | Bytes per frame | Time per frame | Minor words per frame |
| --- | --- | --- | --- | --- |
| trades | 150 | 383 | 4.2 us | 751 |
| bbo | 200 | 230 | 2.8 us | 565 |
| l2 | 40 | 2022 | 60.6 us | 15447 |
| funding | 60 | 581 | 5.4 us | 776 |

The l2 average is dominated by the 20 KB full-depth snapshot sent on subscribe.

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
