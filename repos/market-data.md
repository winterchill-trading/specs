# market-data

Normalized market data types, append-only raw and normalized logs, a live Parquet sink,
the day-close batch that rebuilds Parquet from the event log, DuckDB views, candles and
replay.

| | |
| --- | --- |
| Repository | `winterchill-trading/market-data` |
| opam package | `market-data` |
| Library | `market-data` (module `Market_data`) |
| Binary | `market-data` (`day-close`, `views`, `query`) |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Venue`, `Stream`, `Instrument` | `Hyperliquid \| Binance \| Bybit`; `Trades \| Bbo \| L2 \| Funding \| Private`; `binance:BTCUSDT` |
| `Price`, `Size`, `Side`, `Symbol` | `exchange-core` types with bin_io |
| `Trade`, `Bbo`, `L2_update`, `Funding`, `Candle` | Normalized records, each with a `Stable.V1` whose bin shape is pinned by a test |
| `Event` | `Trade \| Bbo \| L2 \| Funding` |
| `Framed` | Length-prefixed framing, tail-tolerant reader, buffered daily-rotating writer |
| `Frame_log` | Raw `{ recv_ts; stream_id; payload }` records |
| `Event_log` | Normalized events routed to per-stream daily files |
| `Merge` | Deterministic k-way merge of sorted pipes |
| `Candle_agg` | Trades to aligned candles |
| `Feed` | `module type S` of a source: one pipe per stream plus `close`; implemented by each client's `Live_feed` |
| `Replay_feed` | A `Feed.t` replaying `Event_log` files paced by `recv_ts` |
| `Store` | Paths, listing, file selection by date range |
| `Parquet_kind`, `Parquet_schemas`, `Parquet_file` | Table kinds, schemas, atomic file writes through `In_thread` |
| `Parquet_sink` | Live batching writer, daily files, drops past `max_pending_rows` |
| `Day_close` | Rebuilds a day of `parquet/` from `norm/`, idempotent |
| `Parquet_views` | DuckDB `CREATE VIEW`s and a `duckdb` CLI runner |

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

- The README's TODO still lists "live `Feed.S` implementations on top of the venue
  clients"; those now exist as `Live_feed` in the three clients.
- No tool regenerates `norm/` from raw frames yet: the pure normalizers exist
  (`Binance_client.Feed_normalizer`, `Bybit_client.Live_feed.Normalizer`), but nothing
  drives them over stored raw files.
- `Frame_log` (`<venue>/<symbol>/raw/<stream>/<date>.binlog`) and `market-recorder`'s
  raw minute files (`raw/<venue>/<stream>/<symbol>/...ndjson.zst`) are two different raw
  formats; the recorder uses only the latter.
- DuckDB multiplies two `DECIMAL(18,8)` without widening; cast first.
