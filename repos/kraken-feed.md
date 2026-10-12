# kraken-feed

Read-only public market data from Kraken as a `Market_data.Feed.t`: trades, best bid and
offer and the L2 book from the spot websocket v2, and funding, mark and index from the
futures websocket. No API keys, no order entry.

| | |
| --- | --- |
| Repository | `winterchill-trading/kraken-feed` |
| opam package | `kraken-feed` |
| Library | `kraken-feed` (module `Kraken_feed`) |
| Binary | `kraken-feed feed -symbol SYM -streams ... [-count N] [-l2-depth D] [-raw]` |
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
| `Live_feed` | One socket per stream; JSON ping on spot, websocket ping on futures; reconnect and resync |

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
