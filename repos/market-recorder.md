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
| Binary | `market-recorder run -config FILE`, `market-recorder check-config -config FILE` |
| Status | done (CI green; deployment through infra is on the roadmap) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | sexp config: `data_dir`, `http_port` (9100), venue entries (venue, symbols, streams, endpoint `Mainnet \| Testnet \| Local \| Custom`), optional upload command |
| `Raw_writer` | Minute files `raw/<venue>/<stream>/<symbol>/<YYYY>/<MM>/<DD>/<HH>-<MM>.ndjson`, 250 ms flush, zstd roll, crash recovery, disconnect lines; `/`, `\` and space in a symbol become `_` in paths (`BTC/USD` is `BTC_USD`) |
| `Norm_writer` | Normalized events into `Market_data.Event_log` (`<venue>/<symbol>/norm/<stream>/<date>.bin`) |
| `Uploader` | Command per closed file (`{file}`, `{rel}`), backoff 1 s to 5 min, 4 concurrent, `upload-pending.sexp` |
| `Metrics` | Per venue, stream and symbol counters; health rule; Prometheus text |
| `Recorder` | One `Live_feed` per venue entry and symbol, `on_raw` to `Raw_writer`, pipes to `Norm_writer` |
| `Http_server` | `GET /healthz` (503 if any stream silent for 30 s), `GET /metrics` |

`Config.Endpoint.problem` rejects a venue and endpoint pair that cannot work (a venue
without a simulator on `Local`, funding on a spot-only venue) at `check-config` time.
`examples/sims.sexp` records the three simulators; `scripts/e2e-sims.sh` runs them,
records for a given time and checks files, `/healthz` and `/metrics`.

## Dependencies

- Depends on: `market-data`, `hl-client`, `binance-client`, `bybit-client`, `okx-feed`,
  `coinbase-feed`, `kraken-feed`, `deribit-feed`, `bitget-feed` (and zstd, cohttp-async).
- Used by: `infra` (service image with rclone, compose service, Helm Deployment per
  venue).

## CI pin order

`fixed-decimal`, `exchange-core`, `hl-protocol`, `order-book`, `exchange-core-engine`,
`parquet`, `market-data`, `venue-net`, `hl-client`, `binance-protocol`, `mm-core`,
`binance-client`, `bybit-protocol`, `bybit-client`, `okx-feed`, `coinbase-feed`,
`kraken-feed`, `deribit-feed`, `bitget-feed`.

## Design

See [design/data-platform.md](../design/data-platform.md),
[ADR 0004](../adr/0004-tardis-compatible-raw-format.md) and
[ADR 0005](../adr/0005-command-based-uploader.md).

## Known gaps

- Parse errors and reconnects happen inside the clients and are invisible through
  `Market_data.Feed.t`: they are not counted, and reconnects write no disconnect line
  (only shutdown does).
- Event logs are not uploaded.
- `hl-sim` serves no `activeAssetCtx`, so a Hyperliquid `Funding` stream against the
  simulator never delivers and keeps `/healthz` at 503.
- One collector per venue; no replication yet.
- Minute files are compressed whole in memory on roll.
