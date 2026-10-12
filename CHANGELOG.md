# Changelog

One line per architecture change across the organization: a new repository, a new
dependency edge between org packages, a public library or binary, an on-disk format, a
wire protocol, a deployment shape, or an ADR. Newest day first; within a day, in the
order the changes landed. Each line names the repositories and links the spec page that
describes the change. The line is added in the same piece of work that updates the spec
pages (see [CLAUDE.md](CLAUDE.md)). Bug fixes, tests and documentation-only changes do not
belong here.

## 2026-10-12

- `exchange-core` holds two packages, `exchange-core` (types) and `exchange-core-engine`
  (matching, margin, funding, liquidation, noise traders), with `order-book` between
  them. See [repos/exchange-core.md](repos/exchange-core.md).
- `binance-protocol`, `binance-sim`, `bybit-protocol` and `bybit-sim` speak Binance USD-M
  and Bybit v5 over the shared engine. See [design/simulators.md](design/simulators.md).
- `venue-net` is the shared Async HTTP and reconnecting websocket transport of every
  client and feed. See [repos/venue-net.md](repos/venue-net.md).
- `mm-core` defines `Venue.S`; `binance-client` and `bybit-client` implement it, and the
  `market-maker` binary runs one strategy on three venues. See
  [design/market-making.md](design/market-making.md).
- `parquet` is a pure OCaml Parquet writer ([ADR 0003](adr/0003-parquet-pure-ocaml-writer.md));
  `market-data` adds event logs, the Parquet sink, day close, DuckDB views and replay.
  See [design/data-platform.md](design/data-platform.md).
- `hl-client`, `binance-client` and `bybit-client` expose `Live_feed` and depend on
  `market-data` (and through it `parquet`). See [overview.md](overview.md).
- `market-recorder` records raw-first minute files in a Tardis-compatible line format
  with a command-based uploader ([ADR 0002](adr/0002-raw-first-storage.md),
  [ADR 0004](adr/0004-tardis-compatible-raw-format.md),
  [ADR 0005](adr/0005-command-based-uploader.md)).
- `infra` builds a base image and service images, a compose stack and a Helm chart. See
  [design/deployment.md](design/deployment.md).
- `specs` documents the organization; `design/` pages carry a `Kind:` line.
- `okx-feed`, `coinbase-feed`, `kraken-feed`, `deribit-feed` and `bitget-feed`: read-only
  `Market_data.Feed.t` feeds over `market-data` and `venue-net`; `Market_data.Venue`
  gains their venues and `nyse`, `cboe`, `cme`. See [overview.md](overview.md).
- `market-recorder` depends on the five feeds and records eight venues; `/`, `\` and
  space in symbols become `_` in raw paths. See
  [repos/market-recorder.md](repos/market-recorder.md).
- `equities-core` holds US equities, options and futures semantics; `nyse-sim`,
  `cboe-sim` and `cme-sim` start on it and the engine, speaking binary protocols over
  TCP. See [repos/equities-core.md](repos/equities-core.md).
- `hl-mm` and `market-maker` CI pin `parquet` and `market-data`; `infra`'s
  `check-pins.sh` derives and checks every repository's pin order in CI. See
  [repos/infra.md](repos/infra.md).
- Replication design: gap detection from venue sequences, peer fill, a clock bound and a
  failure table (planned). See
  [design/cloud-sinks-and-replication.md](design/cloud-sinks-and-replication.md).
