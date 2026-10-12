# kraken-feed

Read-only public market data from Kraken as a `Market_data.Feed.t`: trades, best bid and
offer and the L2 book from the spot websocket v2, and funding, mark and index from the
futures websocket. No API keys, no order entry.

| | |
| --- | --- |
| Repository | `winterchill-trading/kraken-feed` |
| opam package | `kraken-feed` |
| Library | `kraken-feed` (module `Kraken_feed`) |
| Binary | `kraken-feed feed -symbol SYM -streams ... [-count N] [-l2-depth D] [-raw]`, `kraken-feed rebuild-norm -data-dir DIR -out NEW_DIR -date YYYY-MM-DD` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | Spot v2 (`wss://ws.kraken.com/v2`) and futures v1 (`wss://futures.kraken.com/ws/v1`) endpoints |
| `Wire` | Frame shapes; numbers kept as sent (`Yojson.Raw`) so checksums match |
| `Symbols` | Spot `BASE/QUOTE` (`BTC/USD`) and futures (`PF_XBTUSD`) names, mapped per stream |
| `Local_book` | Per-symbol book trimmed to the subscribed depth |
| `Checksum` | CRC32 of the top 10 levels, as Kraken computes it |
| `Normalizer` | Pure frame to event conversion with checksummed books |
| `Live_feed` | One socket per stream; JSON ping on spot, websocket ping on futures; reconnect and resync; `start` returns a handle whose `stats` count frames, parse errors and reconnects; `?time_source` (default the wall clock) stamps `recv_ts` and drives pings, the silence watchdog and backoff |
| `Raw_normalizer` | `Normalizer` as a `Market_data.Normalizer.S`, behind `rebuild-norm` |

| Stream | Kraken channel |
| --- | --- |
| `trades` | spot v2 `trade` |
| `bbo` | spot v2 `ticker` with `event_trigger: "bbo"` |
| `l2` | spot v2 `book` (depth 10, 25, 100, 500 or 1000), CRC32 checked on every message |
| `funding` | futures v1 `ticker` (`relative_funding_rate`, hourly) |

Instruments carry the name of the API that produced them: `kraken:BTC/USD` for trades,
BBO and L2, `kraken:PF_XBTUSD` for funding.

## Sequencing

Kraken spot has no sequence numbers; every book message carries a checksum. A mismatch
drops the book, resubscribes the symbol and waits for the new snapshot. Levels pushed
beyond the subscribed depth are removed locally and reported as zero-size levels. Tests:
`test/test_book_sequence.ml` ("updates before the snapshot are dropped", "a missed update
shows up as a checksum mismatch and a resubscribe", "reset clears books after a
reconnect"), `test/test_checksum.ml`.

## Tests and benchmark

`test/fixtures/raw/kraken/` is a trimmed mainnet recording (2026-10-12 13:34 to 13:35
UTC, `BTC/USD` and `PF_XBTUSD`, about 260 KB) in the `market-recorder` raw layout, so
`rebuild-norm` runs on it directly. Every frame decodes and the 544 book deltas pass
their checksums. Minor words are pinned within 10 per frame; `bench/main.exe` on an
M-series Mac, JSON decoding included:

| Stream | Frames | Events | Minor words per frame | Time per frame |
| --- | --- | --- | --- | --- |
| `trades` | 155 | 212 trades | 964 | 3.8 us |
| `bbo` | 158 | 148 BBOs | 789 | 3.9 us |
| `l2` | 553 | 1 snapshot, 544 deltas | 1294 | 6.0 us |
| `funding` | 64 | 19 funding | 868 | 6.3 us |

`test/test_reconnect_fake_clock.ml` steps a reconnect and resubscribe on a synthetic
clock against a scripted local server.

## Dependencies

- Depends on: `market-data`, `venue-net`, `fixed-decimal`, `exchange-core`.
- Used by: `market-recorder`, which escapes the `/` in spot symbols as `_` in raw paths.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `venue-net`.

## Known gaps

- Trades, BBO and L2 come from spot only; the futures `trade` and `book` feeds (which
  are sequenced) are not wired in.
- `Funding.rate` is the relative rate per hourly period; the absolute and predicted
  rates are not carried, and `Funding.t` has no period field.
- Mark prices beyond 8 decimals are truncated to the fixed-point precision.
