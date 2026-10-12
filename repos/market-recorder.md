# market-recorder

Raw-first market data recorder for Hyperliquid, Binance USD-M, Bybit linear, OKX,
Coinbase, Kraken, Deribit and Bitget. Every
websocket frame is written exactly as received, with its receive time, into Tardis-style
minute files, compressed with zstd and handed to an upload command when the minute ends;
normalized events go to `Market_data.Event_log` daily files.

| | |
| --- | --- |
| Repository | `winterchill-trading/market-recorder` |
| opam package | `market-recorder` |
| Library | `market-recorder` (module `Market_recorder`) |
| Binary | `market-recorder run -config FILE [-collector ID]`, `market-recorder check-config -config FILE`, `market-recorder status [-url URL]`, `market-recorder rebuild-norm -data-dir DIR -out DIR -date DATE [-venue V] [-skip VENUE:STREAM]`, `market-recorder merge -a DIR -b DIR -out DIR -date DATE [-window SPAN] [-clock-error SPAN] [-silence SPAN] [-collector-a ID] [-collector-b ID]` (`rebuild-norm` also takes `-collector ID`) |
| Status | done (CI green; deployment through infra is on the roadmap) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | sexp config: `data_dir`, `http_port` (9100), venue entries (venue, symbols, streams, endpoint `Mainnet \| Testnet \| Local \| Custom`), optional upload command, `snapshot_interval` (1 minute by default, `0s` off) |
| `Raw_writer` | Minute files `raw/<venue>/<stream>/<symbol>/<YYYY>/<MM>/<DD>/<HH>-<MM>.ndjson`, 250 ms flush, zstd roll, crash recovery, disconnect lines; `/`, `\` and space in a symbol become `_` in paths (`BTC/USD` is `BTC_USD`); open, write and compress failures are reported, not raised, and their lines dropped |
| `Norm_writer` | Normalized events into `Market_data.Event_log` (`<venue>/<symbol>/norm/<stream>/<date>.bin`), with per-minute L2 snapshots in `market-data`'s `Snapshot_index` |
| `Uploader` | Command per closed file (`{file}`, `{rel}`), backoff 1 s to 5 min, 4 concurrent, `upload-pending.sexp` |
| `Metrics` | Per venue, stream and symbol counters; `recv_ts` clamped to non-decreasing per stream with a clamped-frame count; health rule and `/healthz` flaps; Prometheus text |
| `Recorder` | One `Live_feed` per venue entry and symbol, `on_raw` to `Raw_writer`, pipes to `Norm_writer` |
| `Http_server` | `GET /healthz` (503 if any stream silent for 30 s or the raw writer failed in that time; the last failure and its age are shown), `GET /metrics`, `GET /status` (sexp of open minute files, pending uploads and counters) |
| `Warnings` | Per-stream warnings at most once a minute with a suppressed count |
| `Process_metrics` | `build_info` (`git describe` version, OCaml), open file descriptors, RSS (Linux), GC counters and heap words |
| `Status_table` | Parses `/metrics` text and prints the per-stream tables of `status` |
| `Raw_merge` | `merge`: two collectors' raw minute files of a day into one canonical copy in the same layout, with `_merge/<date>.json` per-series counts (`only_a`, `only_b`, `both`, `gaps_closed`, `gaps_kept`) |
| `Venue_seq` | Venue sequence numbers read from raw frames by substring scan: Binance `depthUpdate` `u`/`pu`, `aggTrade` `a`, Bybit book type and `u` |
| `Seq_gaps` | Exact sequence gaps with a reorder buffer (applies checks in sequence order once older than the window) |
| `Silence` | Suspected gaps: silences over a threshold on streams whose median interval (power-of-two histogram) is at most a tenth of it |
| `Raw_files` | Collector ids in minute file names (`<HH>-<MM>.<ID>.ndjson[.zst]`); lists one collector's files of a day |
| `Clock_error` | Clock error bound from `chronyc -c tracking` every 30 s, `market_recorder_clock_error_seconds` |
| `Cycle_monitor` | Async cycles over 50 ms counted (`long_cycles_total`), over 20 ms logged at most every 10 s |
| `Rebuild` | `rebuild-norm`: `Market_data.Rebuild_norm` over every venue's `Normalizer.S` adapter (`Hl_client`, `Binance_client`, `Bybit_client` `Raw_normalizer`, the five feeds' adapters); `-venue` filter; `-skip venue:stream` reads a temporary directory of symlinks without those raw streams |

`Config.Endpoint.problem` rejects a venue and endpoint pair that cannot work (a venue
without a simulator on `Local`, funding on a spot-only venue) at `check-config` time.
`examples/sims.sexp` records the three simulators; `scripts/e2e-sims.sh` runs them,
records for a given time and exits 1 on a missing file, a stale stream, a raw writer
failure or a failed or pending upload; CI runs it for 20 s in an `e2e-sims` job against
the three simulators checked out from `main`. CI runs `shellcheck` on the scripts. A
test against a local websocket server checks that three Binance symbols with two
streams subscribe once per connection at connect and again after every connection
drops. Tests cover
every example config, 100 minute rolls keeping the descriptor count flat, and a close
right after the first write (the Linux flake of `test_raw_writer`, fixed by writing
buffered lines only once the minute file is open).

`scripts/rebuild-day.sh DATA_DIR [DATE]` wraps `rebuild-norm` (default: yesterday into
`DATA_DIR/rebuilt/DATE`). `scripts/e2e-rebuild.sh` records the simulators, rebuilds the
day and compares every event log with its rebuilt copy (counts through `market-data
dump`, then bytes); a 20 s run rebuilt all 22 logs byte for byte. This completes
[ADR 0002](../adr/0002-raw-first-storage.md).

## Replication

`merge` implements the merge step of the
[replication design](../design/cloud-sinks-and-replication.md#replication-design-planned):
per venue, stream, symbol and minute, frames of the two copies with the same identity
(venue sequence number where the stream has one, else the text) and `recv_ts` at most
`-window` (default 5 s) plus `-clock-error` apart are one message, written once with the
earlier `recv_ts` (copy A's inside the clock bound); unmatched frames in a minute's last
window are matched against the next minute of the other copy, and the day's first
minute against the previous day's 23:59. A disconnect line is written only when the other copy has
an overlapping gap (its own disconnect span, or no file for that minute). Output goes
through `Raw_writer`, so files are compressed exactly as the recorder writes them; the
output directory must hold no raw files of the day. `scripts/replicate-day.sh REMOTE_A
REMOTE_B [DATE]` fetches both days with `rclone copy --include`, merges, and copies the
result to `$DEST`; `scripts/test-replicate-day.sh` runs it in CI with a stand-in rclone.
The bench merges about 0.36 to 0.42 M input lines/s from compressed files to compressed
files (1.0 to 1.5 M in memory) on one core.

The report adds per series `text_differs` (sequence matches whose texts differ),
`previous_day`, `seq_gaps` (exact missing ranges in the merged output) with
`seq_gaps_a`/`seq_gaps_b` (each copy's own gaps), and `median_interval_ms` with
`suspected_gaps` (silences over `-silence`, default 10 s, on streams that normally
tick). `-collector-a`/`-collector-b` select collectors' files in one tree. The bench
still merges about 0.38 M input lines/s from compressed files (1.4 M in memory).

Planned: ordering inside the clock bound by sequence, the L2 snapshot rule, and the
infra side (second collector with `-collector`, cross-region replication, a daily merge
job before day close).

## Metrics added in wave 6

`market_recorder_gaps_total` per venue, stream and symbol (client-reported gaps, each
also writing a disconnect line into the open minute file);
`market_recorder_exchange_lag_seconds` per venue (latest `recv_ts - exch_ts`, funding
excluded); `market_recorder_clock_error_seconds`; `market_recorder_long_cycles_total`
and `_longest_cycle_seconds`; `market_recorder_max_fds` (soft `RLIMIT_NOFILE`, also
logged at startup with the hard limit). `MEMTRACE=FILE` starts memtrace before Async
(`Memtrace.trace_if_requested`, `MEMTRACE_RATE`), as infra's compose and Helm pass it;
CI checks that a trace is written. `check-config` errors name the entry as
`venues[i] <venue>: ...`.

## Metrics added in wave 2

`market_recorder_clamped_frames_total`, `_norm_pipe_length` and `_healthz_flaps_total`
per venue, stream and symbol; `market_recorder_build_info`, `_open_fds`,
`_resident_memory_bytes` and the GC counters and heap gauges per process.

## Throughput

`bench/bench.exe` pushes one synthetic minute of Binance `BTCUSDT` frames through the
normalizer, the raw writer with its zstd roll and the event log writer. On one core of an
M-series Mac (dev profile) all three run at about 250k frames/s (45 MB/s); JSON decoding
in the normalizer is about 60% of the cost. The busiest mainnet stream seen (Binance
`BTCUSDT` bbo, about 1000 frames/s) uses under 0.5% of that.

## Dependencies

- Depends on: `market-data`, `hl-client`, `binance-client`, `bybit-client`, `okx-feed`,
  `coinbase-feed`, `kraken-feed`, `deribit-feed`, `bitget-feed` (and zstd, cohttp-async).
- Used by: `infra` (service image with rclone, compose service, Helm Deployment per
  venue).

## CI pin order

`fixed-decimal`, `exchange-core`, `hl-protocol`, `parquet`, `market-data`, `venue-net`,
`hl-client`, `binance-protocol`, `mm-core`, `binance-client`, `bybit-protocol`,
`bybit-client`, `okx-feed`, `coinbase-feed`, `kraken-feed`, `deribit-feed`,
`bitget-feed` (`order-book` and `exchange-core-engine` were dropped as unneeded).

## Design

See [design/data-platform.md](../design/data-platform.md),
[ADR 0004](../adr/0004-tardis-compatible-raw-format.md) and
[ADR 0005](../adr/0005-command-based-uploader.md).

## Known gaps

- Hyperliquid, Binance and Bybit reconnects write a disconnect line (from the clients'
  `feed_with_gaps`); OKX, Coinbase, Kraken, Deribit and Bitget report no gaps, so their
  reconnects write none. Parse errors and reconnects
  are read from each client's `stats` and exported per venue as
  `market_recorder_client_frames_total`, `market_recorder_parse_errors_total` and
  `market_recorder_reconnects_total`; `deploy/prometheus/alerts.yml` alerts on them.
- Hyperliquid `bbo` gets no raw frames when `l2` is also subscribed (the client writes
  each `l2Book` frame once), so that stream is excluded from the health check.
- Event logs are not uploaded.
- `hl-sim` serves no `activeAssetCtx`, so a Hyperliquid `Funding` stream against the
  simulator never delivers and keeps `/healthz` at 503.
- One collector per venue is deployed; `merge` exists but no second collector or merge job runs yet.
- A stalled event log does not push back on the feeds: events wait in `Norm_writer`'s
  memory and `norm_pipe_length` stays at zero (pinned by a test with a FIFO as the log).
- Minute files are compressed whole in memory on roll.
