# Changelog

One line per architecture change across the organization: a new repository, a new
dependency edge between org packages, a public library or binary, an on-disk format, a
wire protocol, a deployment shape, or an ADR. Newest day first; within a day, in the
order the changes landed. Each line names the repositories and links the spec page that
describes the change. The line is added in the same piece of work that updates the spec
pages (see [CLAUDE.md](CLAUDE.md)). Bug fixes, tests and documentation-only changes do not
belong here.

## 2026-10-12

- `exchange-core`: `Market_sim.set_reference` and `set_noise_traders` for the price anchor.
  See [repos/exchange-core.md](repos/exchange-core.md).
- all repositories: CI installs dependencies through `infra`'s `ox-setup` action with a
  cached switch. See [design/deployment.md](design/deployment.md#ci).
- `mm-core`: hot parameter updates and the rolling action-rate window (`Live.connect_and_start`,
  `Strategy.update_params`, `on_resync`). See [repos/mm-core.md](repos/mm-core.md).
- `market-recorder`: per-venue client counters on `/metrics` and `/status`, Prometheus alert
  rules in `deploy/prometheus/`. See [repos/market-recorder.md](repos/market-recorder.md).

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
- `exchange-core-engine` adds `Input`, `Journal` (on-disk format: magic `EXJRNL01`,
  then one `bin_prot` input per record), numbered events with `Book_replay`, and the
  `Stepped` harness. See [repos/exchange-core.md](repos/exchange-core.md).
- `fixed-decimal` declares `S.t` `[@@immediate]` and puts a `lossy` alert on
  `of_float`. See [repos/fixed-decimal.md](repos/fixed-decimal.md).
- `market-data`: `norm/` files start with an `MDFRAME1` header carrying the
  `Event.Stable.V1.t` digest; day close writes `parquet/<kind>/_manifest/<date>.sexp`;
  `query` appends to `query-log.ndjson`; new `dump`, `check` and `catalog` subcommands.
  See [design/data-platform.md](design/data-platform.md).
- `mm-core`: `Params.t` gains `max_actions_per_sec`, `soft_max_position` and
  `bump_budget` (defaulted when absent from a sexp); `Live.Make` takes an optional
  `?time_source` and reports tick-to-order latency. See [repos/mm-core.md](repos/mm-core.md).
- `venue-net`: `Ws_client.connect` takes `?backoff_jitter`, `?handshake_timeout` and
  `?time_source`; `Http.Record` writes JSON request and response fixtures. See
  [repos/venue-net.md](repos/venue-net.md).
- `hl-sim` serves the `activeAssetCtx` websocket channel, writes a JSON-lines request
  journal (`-journal`) and disconnects subscribers past 10,000 queued messages. See
  [repos/hl-sim.md](repos/hl-sim.md).
- `infra` tags service images by commit, labels them with sibling pins, rejects `latest`
  in the Helm defaults and adds an optional node-exporter DaemonSet and a compose
  `monitoring` profile. See [repos/infra.md](repos/infra.md).
- `oxcaml-claude-skills` provides `check-obj-magic.sh` for other repositories' CI. See
  [repos/oxcaml-claude-skills.md](repos/oxcaml-claude-skills.md).
- `nyse-sim`, `cboe-sim` and `cme-sim` are done: each ships a server and a `*-sim-cli`
  binary, with gateway, feed and HTTP ports. See
  [design/simulators.md](design/simulators.md#tradfi-simulators).
- `market-data`: `Event_log` readers accept an append-only list of compatible digests
  ([ADR 0006](adr/0006-compatible-event-log-digests.md)); new `Instrument_info`
  catalogue, `norm/l2/_snapshots/<date>.bin` snapshot files (`Snapshot_index`),
  `Raw_minute`, `Normalizer.S` and a `rebuild-norm` subcommand; `day-close` takes `-jobs`
  and `-processes`. See [design/data-platform.md](design/data-platform.md).
- `market-recorder`: `recv_ts` clamped per stream, `GET /status`, a `status` subcommand,
  new per-stream and process gauges on `/metrics`, raw writer failures on `/healthz`, and
  a `snapshot_interval` config writing L2 snapshots. See
  [repos/market-recorder.md](repos/market-recorder.md).
- `hl-client`: `Signing` (EIP-712 over a MessagePack action hash, secp256k1; new opam
  dependency `secp256k1`) and typed `Client` handles; `hl-cli` gains `address` and
  `cancel`. See [repos/hl-client.md](repos/hl-client.md).
- `binance-client` and `bybit-client`: key-less `Config.Read_only` configs; every
  client's and feed's `Live_feed` exposes `stats` and takes `?time_source`. See
  [repos/binance-client.md](repos/binance-client.md) and
  [repos/bybit-client.md](repos/bybit-client.md).
- `market-maker`: `-params FILE` reloaded on SIGHUP, `-shadow-params`, `-strategy-log`
  and `-max-actions-per-sec`; CI no longer pins the simulators. See
  [repos/market-maker.md](repos/market-maker.md).
- `hl-protocol`: `Asset_ctx` for `activeAssetCtx`; `Clearinghouse_state` decodes
  `liquidationPx` as an option. See [repos/hl-protocol.md](repos/hl-protocol.md).
- `hl-mm`: `Hl_venue.Trading` over a signing `hl-client` handle; the binary gains
  `-testnet`, `-params`, `-max-actions-per-sec` and `-soft-max-position`. See
  [repos/hl-mm.md](repos/hl-mm.md).
- `okx-feed`, `coinbase-feed`, `kraken-feed`, `deribit-feed`, `bitget-feed`: a
  `Market_data.Normalizer.S` adapter each; `kraken-feed` and `deribit-feed` add a
  `rebuild-norm` subcommand. See [repos/okx-feed.md](repos/okx-feed.md).
- `infra`: the `ox-setup` composite action builds and caches the OxCaml switch for every
  repository's CI; `hl-sim` uses it, and `check-pins.sh` reads its `pins:` block. See
  [design/deployment.md](design/deployment.md#ci).
