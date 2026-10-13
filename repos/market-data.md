# market-data

Normalized market data types, append-only raw and normalized logs, a live Parquet sink,
the day-close batch that rebuilds Parquet from the event log, DuckDB views, candles and
replay.

| | |
| --- | --- |
| Repository | `winterchill-trading/market-data` |
| opam package | `market-data` |
| Library | `market-data` (module `Market_data`) |
| Binary | `market-data` (`day-close`, `views`, `query`, `dump`, `check`, `catalog`, `rebuild-norm`) |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Venue`, `Stream`, `Instrument` | Eleven venues (the three simulated crypto venues, five read-only feeds, NYSE, Cboe, CME); `Trades \| Bbo \| L2 \| Funding \| Private`; `binance:BTCUSDT` |
| `Price`, `Size`, `Side`, `Symbol` | `exchange-core` types with bin_io |
| `Trade`, `Bbo`, `L2_update`, `Funding`, `Candle` | Normalized records, each with a `Stable.V1` whose bin shape is pinned by a test and with derived `quickcheck` generators; `Funding.Stable.V2` has an optional `exch_ts`, with `of_v1`/`to_v1` |
| `Event` | `Trade \| Bbo \| L2 \| Funding`; its binary shape is `Event.Stable.V1`, whose appended `Funding_v2` carries funding with no exchange timestamp (written when `exch_ts = recv_ts`) |
| `Framed` | Length-prefixed framing, optional `MDFRAME1` digest header, tail-tolerant reader, buffered daily-rotating writer; reused encode and decode buffers |
| `Frame_log` | Raw `{ recv_ts; stream_id; payload }` records |
| `Event_log` | Normalized events routed to per-stream daily files; `digest` of `Event.Stable.V1.t` written in each file header; readers accept any digest in the append-only `compatible_digests` list ([ADR 0006](../adr/0006-compatible-event-log-digests.md)); `Writer ~snapshot_interval` also keeps per-interval L2 snapshots |
| `Snapshot_index` | Periodic full L2 books in `norm/l2/_snapshots/<date>.bin`, looked up by time |
| `Instrument_info` | Catalogue per venue and symbol from `data/instruments.sexp`: kind (`Spot \| Perp \| Future \| Option`), base, quote, size unit (`Base \| Quote \| Contracts m`), funding interval, tick, lot |
| `Raw_minute` | Reads `market-recorder` minute files (path parsing, multi-frame zstd, `<recv_ts> <frame>` lines) |
| `Raw_reader` | Streams one symbol's raw minute files over a time range, all streams merged by `recv_ts`, one decompressed minute per stream in memory; empty lines become `Gap` items; unreadable lines go to `on_error`. About 2.7 M lines/s at 39 words per line after the batched merge and index-split lines |
| `Gap`, `Feed.With_gaps` | A gap record (`Disconnect`, `Resync`, `Damaged_log`) and a feed wrapper with a `gaps` pipe; `Feed.S` is unchanged, `of_feed`/`to_feed` convert |
| `Replay_feed.of_raw` | Replays raw files through a `Normalizer.S`, one state per stream, each disconnect line reported as a gap |
| `Normalizer`, `Rebuild_norm` | `Normalizer.S`, the raw-frame-to-events interface a feed library implements; `Rebuild_norm.run` and `command` rebuild a day of `norm/` from raw minutes through `Raw_reader` with the given normalizers; unparseable lines count as `frame_errors` instead of failing the run; `?snapshot_interval` (`-snapshot-interval`, one minute by default, `0s` off) writes the same `Snapshot_index` as the live writer |
| `Merge` | Deterministic k-way merge of sorted pipes |
| `Candle_agg` | Trades to aligned candles |
| `Feed` | `module type S` of a source: one pipe per stream plus `close`; implemented by each client's `Live_feed` |
| `Replay_feed` | A `Feed.t` replaying `Event_log` files paced by `recv_ts`; `of_range` fails on a range with no files and with `~start_at` starts each instrument from its last L2 snapshot |
| `Store` | Paths, listing, file selection by date range |
| `Parquet_kind`, `Parquet_schemas`, `Parquet_file` | Table kinds, schemas, atomic file writes through `In_thread` |
| `Parquet_sink` | Live batching writer, daily files, drops past `max_pending_rows` |
| `Instruments_table` | The point-in-time universe of a day (`<root>/instruments/<date>.parquet`): instruments with event logs that day and their catalogue facts; written by full `day-close` runs |
| `Day_close` | Rebuilds a day of `parquet/` from `norm/` in 64k-row row groups (`-row-group N`); a manifest per table (`parquet/<kind>/_manifest/<date>.sexp`) skips tables whose inputs and code version match; per-table stats; `-jobs N` tables at once in threads, `-processes N` instruments at once in child processes (a synthetic 3M-event day: 6.0 s sequential, 1.5 s with `-processes 4`) |
| `Parquet_views` | DuckDB `CREATE VIEW`s (including `instruments`), derived views (`trades_with_bbo`, `lag`, `units_per_contract`, `token_bbo`) and a `duckdb` CLI runner |
| `Contract_units` | Token units per price and size unit, derived from the `Instrument_info` catalogue |
| `Funding` | Besides the record, `normalized_8h` scales a rate to 8 hours by the catalogued funding interval |
| `Quality_check` | DuckDB assertions (gaps, non-positive sizes, crossed BBO) and the `gaps` view, behind `check` |
| `Catalog` | Per table venues, symbols, first and last day, files and leftover parts |
| `L2_book`, `Event_dump` | Book rebuilt from snapshots and deltas; one-line event rendering, behind `dump` and `dump -book-at` |
| `Query_log` | Appends `{time, user, sql}` of each `query` to `query-log.ndjson` |

## Tests

Expect tests, checked-in event log fixtures that tests read with today's code and never
regenerate (`test/fixtures/event-log-v1`, and `event-log-pre-venues` written before the
venue list grew from three to eleven), an expect test pinning the global
replay order and a `Merge` order property, candles compared row for row with a DuckDB
aggregation, the lead-lag query over a fixture with planted venue lags, a cram test of
`day-close` and `scripts/daycheck-diff.sh`, a pyarrow type test of `examples/query.py`
in CI (`scripts/pyarrow-check.sh`), a `bin_io` round-trip property for every
stable type, a `Framed` round trip over random flush and buffer sizes with an allocation
check, quality checks and manifests over day-closed tables, and derived views comparing
per-token mids across venues.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `parquet` (and bin_prot).
- Used by: `hl-client`, `binance-client`, `bybit-client`, the five read-only feeds,
  `market-recorder`; `infra`
  runs its binary as the day-close CronJob.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`. CI installs the DuckDB CLI (v1.5.6) because
the tests read Parquet back.

## Design

See [design/data-platform.md](../design/data-platform.md).

## Known gaps

- `market-data rebuild-norm` links no venue code and skips every file; a rebuild needs a
  binary that links the feed libraries' `Normalizer.S` modules (`kraken-feed` and
  `deribit-feed` ship one). The three trading clients have no adapter yet.
- The V2 type information (instrument kind, size unit, funding interval) lives in the
  `Instrument_info` catalogue, not in the event records. A missing funding `exch_ts`
  is recorded in event logs (`Funding_v2`) but not in Parquet, whose writer has no
  optional columns.
- `Frame_log` (`<venue>/<symbol>/raw/<stream>/<date>.binlog`) and `market-recorder`'s
  raw minute files (`raw/<venue>/<stream>/<symbol>/...ndjson.zst`) are two different raw
  formats; the recorder uses only the latter.
- DuckDB multiplies two `DECIMAL(18,8)` without widening; cast first.
