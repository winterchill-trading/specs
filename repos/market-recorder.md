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
| Binary | `market-recorder run -config FILE`, `market-recorder check-config -config FILE`, `market-recorder status [-url URL]` |
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

`Config.Endpoint.problem` rejects a venue and endpoint pair that cannot work (a venue
without a simulator on `Local`, funding on a spot-only venue) at `check-config` time.
`examples/sims.sexp` records the three simulators; `scripts/e2e-sims.sh` runs them,
records for a given time and exits 1 on a missing file, a stale stream, a raw writer
failure or a failed or pending upload. CI runs `shellcheck` on the scripts. Tests cover
every example config, 100 minute rolls keeping the descriptor count flat, and a close
right after the first write (the Linux flake of `test_raw_writer`, fixed by writing
buffered lines only once the minute file is open).

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
- One collector per venue; no replication yet.
- Minute files are compressed whole in memory on roll.
