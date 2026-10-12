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
| Binary | `market-recorder run -config FILE`, `market-recorder check-config -config FILE`, `market-recorder status [-url URL]`, `market-recorder rebuild-norm -data-dir DIR -out DIR -date DATE [-venue V] [-skip VENUE:STREAM]`, `market-recorder merge -a DIR -b DIR -out DIR -date DATE [-window SPAN]` |
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
| `Rebuild` | `rebuild-norm`: `Market_data.Rebuild_norm` over every venue's `Normalizer.S` adapter (`Hl_client`, `Binance_client`, `Bybit_client` `Raw_normalizer`, the five feeds' adapters); `-venue` filter; `-skip venue:stream` reads a temporary directory of symlinks without those raw streams |

`Config.Endpoint.problem` rejects a venue and endpoint pair that cannot work (a venue
without a simulator on `Local`, funding on a spot-only venue) at `check-config` time.
`examples/sims.sexp` records the three simulators; `scripts/e2e-sims.sh` runs them,
records for a given time and exits 1 on a missing file, a stale stream, a raw writer
failure or a failed or pending upload. CI runs `shellcheck` on the scripts. Tests cover
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
per venue, stream, symbol and minute, frames of the two copies with the same text and
`recv_ts` at most `-window` (default 5 s) apart are one message, written once with the
earlier `recv_ts`; unmatched frames in a minute's last window are matched against the
next minute of the other copy. A disconnect line is written only when the other copy has
an overlapping gap (its own disconnect span, or no file for that minute). Output goes
through `Raw_writer`, so files are compressed exactly as the recorder writes them; the
output directory must hold no raw files of the day. `scripts/replicate-day.sh REMOTE_A
REMOTE_B [DATE]` fetches both days with `rclone copy --include`, merges, and copies the
result to `$DEST`; `scripts/test-replicate-day.sh` runs it in CI with a stand-in rclone.
The bench merges about 0.36 to 0.42 M input lines/s from compressed files to compressed
files (1.0 to 1.5 M in memory) on one core.

Planned: sequence-number identity and exact gap lists, silence-based suspected gaps, the
clock bound, the L2 snapshot rule, matching across the day boundary, and the infra side
(per-collector upload prefixes, a daily merge job before day close).

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

- Reconnects write no disconnect line (only shutdown does). Parse errors and reconnects
  are read from each client's `stats` and exported per venue as
  `market_recorder_client_frames_total`, `market_recorder_parse_errors_total` and
  `market_recorder_reconnects_total`; `deploy/prometheus/alerts.yml` alerts on them.
- Hyperliquid `bbo` gets no raw frames when `l2` is also subscribed (the client writes
  each `l2Book` frame once), so that stream is excluded from the health check.
- Event logs are not uploaded.
- `hl-sim` serves no `activeAssetCtx`, so a Hyperliquid `Funding` stream against the
  simulator never delivers and keeps `/healthz` at 503.
- One collector per venue is deployed; `merge` exists but no second collector or merge job runs yet.
- Minute files are compressed whole in memory on roll.
