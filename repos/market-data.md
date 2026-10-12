# market-data

Normalized market data types, append-only raw and normalized logs, a live Parquet sink,
the day-close batch that rebuilds Parquet from the event log, DuckDB views, candles and
replay.

| | |
| --- | --- |
| Repository | `winterchill-trading/market-data` |
| opam package | `market-data` |
| Library | `market-data` (module `Market_data`) |
| Binary | `market-data` (`day-close`, `views`, `query`, `dump`, `check`, `catalog`) |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Venue`, `Stream`, `Instrument` | Eleven venues (the three simulated crypto venues, five read-only feeds, NYSE, Cboe, CME); `Trades \| Bbo \| L2 \| Funding \| Private`; `binance:BTCUSDT` |
| `Price`, `Size`, `Side`, `Symbol` | `exchange-core` types with bin_io |
| `Trade`, `Bbo`, `L2_update`, `Funding`, `Candle` | Normalized records, each with a `Stable.V1` whose bin shape is pinned by a test and with derived `quickcheck` generators |
| `Event` | `Trade \| Bbo \| L2 \| Funding` |
| `Framed` | Length-prefixed framing, optional `MDFRAME1` digest header, tail-tolerant reader, buffered daily-rotating writer; reused encode and decode buffers |
| `Frame_log` | Raw `{ recv_ts; stream_id; payload }` records |
| `Event_log` | Normalized events routed to per-stream daily files; `digest` of `Event.Stable.V1.t` written in each file header and checked by readers |
| `Merge` | Deterministic k-way merge of sorted pipes |
| `Candle_agg` | Trades to aligned candles |
| `Feed` | `module type S` of a source: one pipe per stream plus `close`; implemented by each client's `Live_feed` |
| `Replay_feed` | A `Feed.t` replaying `Event_log` files paced by `recv_ts`; `of_range` fails on a range with no files |
| `Store` | Paths, listing, file selection by date range |
| `Parquet_kind`, `Parquet_schemas`, `Parquet_file` | Table kinds, schemas, atomic file writes through `In_thread` |
| `Parquet_sink` | Live batching writer, daily files, drops past `max_pending_rows` |
| `Day_close` | Rebuilds a day of `parquet/` from `norm/`; a manifest per table (`parquet/<kind>/_manifest/<date>.sexp`) skips tables whose inputs and code version match; per-table stats |
| `Parquet_views` | DuckDB `CREATE VIEW`s, derived views (`trades_with_bbo`, `lag`, `units_per_contract`, `token_bbo`) and a `duckdb` CLI runner |
| `Contract_units` | Token units per price and size unit of known listings (`1000PEPEUSDT`, `kPEPE`, OKX swaps) |
| `Quality_check` | DuckDB assertions (gaps, non-positive sizes, crossed BBO) and the `gaps` view, behind `check` |
| `Catalog` | Per table venues, symbols, first and last day, files and leftover parts |
| `L2_book`, `Event_dump` | Book rebuilt from snapshots and deltas; one-line event rendering, behind `dump` and `dump -book-at` |
| `Query_log` | Appends `{time, user, sql}` of each `query` to `query-log.ndjson` |

## Tests

Expect tests, a checked-in event log fixture (`test/fixtures/event-log-v1`, never
regenerated) that a test reads with today's code, an expect test pinning the global
replay order and a `Merge` order property, a `bin_io` round-trip property for every
stable type, a `Framed` round trip over random flush and buffer sizes with an allocation
check, quality checks and manifests over day-closed tables, and derived views comparing
per-token mids across venues.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `parquet` (and bin_prot).
- Used by: `hl-client`, `binance-client`, `bybit-client`, `market-recorder`; `infra`
  runs its binary as the day-close CronJob.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`. CI installs the DuckDB CLI (v1.5.6) because
the tests read Parquet back.

## Design

See [design/data-platform.md](../design/data-platform.md).

## Known gaps

- No tool regenerates `norm/` from raw frames yet: the pure normalizers exist
  (`Binance_client.Feed_normalizer`, `Bybit_client.Live_feed.Normalizer`), but nothing
  drives them over stored raw files.
- `Frame_log` (`<venue>/<symbol>/raw/<stream>/<date>.binlog`) and `market-recorder`'s
  raw minute files (`raw/<venue>/<stream>/<symbol>/...ndjson.zst`) are two different raw
  formats; the recorder uses only the latter.
- DuckDB multiplies two `DECIMAL(18,8)` without widening; cast first.
