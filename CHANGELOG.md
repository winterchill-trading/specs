# Changelog

One line per architecture change across the organization: a new repository, a new
dependency edge between org packages, a public library or binary, an on-disk format, a
wire protocol, a deployment shape, or an ADR. Newest day first; within a day, in the
order the changes landed. Each line names the repositories and links the spec page that
describes the change. The line is added in the same piece of work that updates the spec
pages (see [CLAUDE.md](CLAUDE.md)). Bug fixes, tests and documentation-only changes do not
belong here.

## 2026-10-13

- `hl-copy-core`: library done (`Scale`, `Caps`, `Rounding`, `Plan`, `Mirror`, `Score`,
  `Pnl`, `Follower_config`), depending on `fixed-decimal`, `exchange-core`,
  `hl-protocol` and `market-data`. See [repos/hl-copy-core.md](repos/hl-copy-core.md).
- `market-recorder`: consumes `feed_with_gaps` of the OKX, Coinbase, Kraken, Deribit and
  Bitget feeds, so every venue's reconnects and book resyncs write disconnect lines. See
  [repos/market-recorder.md](repos/market-recorder.md).
- `market-maker`: order lifecycle log, Async cycle monitor, nightly workflow and the
  `market-maker-status` viewer. See [repos/market-maker.md](repos/market-maker.md).
- `price-anchor`: new public module `Eligible`, `Ref_book.mid_or_null` and
  `Scale.price_or_null`; `Queue_ahead` indexed by price. See
  [repos/price-anchor.md](repos/price-anchor.md).
- `hl-copy-core`, `hl-leaderboard`, `hl-copy-engine`, `hl-copy-api`, `hl-copy-web`:
  new repositories for the copy-trading platform (in progress), with ADR 0007 (agent
  keys instead of custody) and ADR 0008 (Bonsai frontend). See
  [design/copytrading.md](design/copytrading.md).
- `hl-protocol`: wire protocol additions for copy trading, `approveAgent` and
  `approveBuilderFee` (`User_signed_action`, `User_signed_request`), the order `builder`
  field (`Builder_fee`, `Order_action`, `Exchange_envelope`), `userFillsByTime`,
  `userEvents` and the stats-host leaderboard. See [repos/hl-protocol.md](repos/hl-protocol.md).
- `hl-client`: EIP-712 user-signed approvals, `Client.trading_with_agent`, builder-fee
  orders, `User_feed` (shared leader fill feeds), `Leaderboard` and `userFillsByTime`.
  See [repos/hl-client.md](repos/hl-client.md) and
  [design/copytrading.md](design/copytrading.md).
- `hl-sim`: copy-trading wire support (`approveAgent`, `approveBuilderFee`, agent-signed
  orders, builder codes, `maxBuilderFee`, `extraAgents`, `userFillsByTime`,
  `orderStatus`, the `leaderboard` info request and `GET /leaderboard`, `webData2` and
  `userEvents`), `updateLeverage`, `scheduleCancel` and `batchModify`, new JSON journal
  record kinds (`userAction`, `l1Action`), and the `-leaders`, `-strict-signatures`,
  `-mainnet-signatures`, `-taker-fee-bps`, `-maker-fee-bps` and `-l2-interval-ms` flags
  (fees now 4.5 / 1.5 bps, `l2Book` pushes 500 ms apart). See
  [repos/hl-sim.md](repos/hl-sim.md).
- `hl-copy-api`: the API server and binary (wallet login, agent key offers and
  approvals, builder fee, follows written as engine configs, leaders proxy, `/me`,
  `/ws`, CORS, rate limits, `/metrics`) and the `hl-copy-keystore` package with the
  sealed agent key file format the engine reads; depends on `hl-copy-api-types` from
  `hl-copy-web`. See [repos/hl-copy-api.md](repos/hl-copy-api.md) and
  [design/copytrading.md](design/copytrading.md).

## 2026-10-12

- `mm-core`: `mm-core-replay` package with a replay binary over event logs; GC counts in
  `Live.Report`. See [repos/mm-core.md](repos/mm-core.md).
- `market-recorder`: raw minute file names may carry a collector id
  (`<HH>-<MM>.<collector>.ndjson[.zst]`, `run -collector`), read by `merge -collector-a/-b`
  and `rebuild-norm -collector`; the `_merge/<date>.json` report gains `text_differs`,
  `previous_day`, `seq_gaps`, `seq_gaps_a`/`_b`, `median_interval_ms`,
  `suspected_gaps` and `clock_error_ms`; the recorder consumes the Hyperliquid, Binance
  and Bybit `feed_with_gaps` and writes a disconnect line per reported gap; new metrics
  `gaps_total`, `exchange_lag_seconds`, `clock_error_seconds`, `long_cycles_total`,
  `longest_cycle_seconds`, `max_fds`. See [repos/market-recorder.md](repos/market-recorder.md)
  and [design/cloud-sinks-and-replication.md](design/cloud-sinks-and-replication.md).
- `hl-client`, `binance-client`, `bybit-client`: `feed_with_gaps` reports resyncs as
  `Market_data.Gap` values. See the repository pages.
- `price-anchor`: `Anchor.create` gains `?half_life`, `?may_engage`, `?last_trade` and
  `?step_clock`; a series alone is no longer stale between points by default;
  `Source.of_series` returns an error for a missing file. These are the TradFi controls
  the `nyse-sim`, `cboe-sim` and `cme-sim` `Anchoring` modules implement locally. See
  [design/price-anchor.md](design/price-anchor.md#tradfi-simulators).
- `cboe-sim`: depends on `price-anchor` and `market-data`; `-anchor-series`,
  `-anchor-fixed` and `-anchor-scaled` pull a listing's noise traders towards a reference
  price in continuous core trading; the LULD reference is the mean of the venue's own
  prints over five minutes. See [repos/cboe-sim.md](repos/cboe-sim.md).
- `bybit-sim`: new `bybit-sim-anchor` package (library `Bybit_sim_anchor` and the
  `bybit-sim` binary) depending on `price-anchor`, `market-data`, `bybit-client` and
  `binance-client`; `-anchor VENUE:SYMBOL=SIMSYM` (live), `-anchor-raw` / `-anchor-norm`
  with `-anchor-speed`, `GET /sim/anchor`, `-input-journal`. The `bybit-sim` library
  package keeps its dependencies. See [repos/bybit-sim.md](repos/bybit-sim.md).
- `binance-sim`: new `binance-sim-anchor` package (library `Binance_sim_anchor` and the
  `binance-sim` binary) depending on `price-anchor`, `market-data` and `binance-client`;
  `-anchor VENUE:SYMBOL=SIM` (live), `-anchor-raw` / `-anchor-norm` with `-anchor-speed`,
  `GET /sim/anchor`. The `binance-sim` library package keeps its dependencies. See
  [repos/binance-sim.md](repos/binance-sim.md).
- `hl-sim`: depends on `price-anchor`, `market-data`, `hl-client` and `binance-client`;
  `-anchor VENUE:SYMBOL=COIN` (live), `-anchor-raw` / `-anchor-norm` (recorded) with
  `-anchor-speed`, `GET /status`, `-input-journal` (engine `Journal`). See
  [repos/hl-sim.md](repos/hl-sim.md).
- `nyse-sim`: depends on `price-anchor` and `market-data`; `-anchor-series`,
  `-anchor-fixed` and `-anchor-scaled` pull a symbol's noise traders towards a reference
  price in continuous core trading, anchor state and best bid/ask on `GET /`. See
  [repos/nyse-sim.md](repos/nyse-sim.md).
- `cme-sim`: depends on `price-anchor` and `market-data`; `-anchor-series`, `-anchor-fixed`
  and `-anchor-scaled` pull a product's noise traders towards a reference price while it
  is open, `/anchors` endpoint. See [repos/cme-sim.md](repos/cme-sim.md).
- `market-recorder`: `merge` subcommand and `scripts/replicate-day.sh`, two collectors'
  raw days into one canonical copy with a `_merge/<date>.json` report. See
  [design/cloud-sinks-and-replication.md](design/cloud-sinks-and-replication.md).
- `market-maker`: signs Hyperliquid orders through `Hl_venue.Trading` when
  `HL_PRIVATE_KEY` is set, `-i-understand-mainnet` guard, `hl-sim` as a test dependency.
  See [repos/market-maker.md](repos/market-maker.md).
- `price-anchor` (new): anchors a simulated market to a live or recorded reference (mark,
  funding, shadow top-N levels, trade-replay fills, staleness) over `exchange-core-engine`
  and `market-data`. See [repos/price-anchor.md](repos/price-anchor.md).
- `market-recorder`: `rebuild-norm` subcommand linking every venue's `Normalizer.S`
  adapter, with `-venue` and `-skip venue:stream`; completes ADR 0002. See
  [repos/market-recorder.md](repos/market-recorder.md).
- `market-replay` (new): replay server for recorded raw minute files, `GET /replay` and
  venue-native websockets for Hyperliquid, Binance and Bybit. See
  [repos/market-replay.md](repos/market-replay.md).
- `market-data`: `Raw_reader`, `Feed.With_gaps` and `Replay_feed.of_raw`, the shared raw-file
  reader for the replay server and the price anchor. See [repos/market-data.md](repos/market-data.md).
- `hl-client`, `binance-client`, `bybit-client`: `Raw_normalizer` adapters and `rebuild-norm`,
  so every recorded venue decodes offline. See the repository pages.
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
- `cboe-sim`: `Anchoring` is a thin wrapper over `price-anchor`'s `Anchor` (`path`,
  `may_engage`, `last_trade`, `clamp` on the LULD bands); targets stay inside the bands.
  See [repos/cboe-sim.md](repos/cboe-sim.md).
- `cme-sim`: `Anchoring` is a thin wrapper over `price-anchor`'s `Anchor` (`path`,
  `may_engage` while open, `last_trade`, `clamp` on the daily price limits); targets now
  stay 30 bps inside the limits. See [repos/cme-sim.md](repos/cme-sim.md).
- `nyse-sim`: `Anchoring` is a thin wrapper over `price-anchor`'s `Anchor` (`path`,
  `may_engage`, `last_trade`, `clamp` on the LULD bands); `Venue.last_trade` is public and
  `GET /` adds `resumes` and `clamped` to each anchor. See
  [repos/nyse-sim.md](repos/nyse-sim.md).
- `market-replay`: websocket replay for `okx`, `coinbase`, `kraken` (spot and futures on
  one path), `deribit` and `bitget` in each venue's subscribe protocol, with Coinbase
  `sequence_num` renumbered per connection; speed 0 Binance replays wait at the diff a
  recorded depth snapshot joins at until it is served; tests depend on the five feed
  clients. See [repos/market-replay.md](repos/market-replay.md).
- `market-data`: event logs gain an appended `Funding_v2` constructor (new digest
  `cdf98830...` in `compatible_digests`) for funding without an exchange timestamp, and
  `Funding.Stable.V2`; day close writes `<root>/instruments/<date>.parquet`, the day's
  universe, and 64k-row row groups. See
  [design/data-platform.md](design/data-platform.md#funding-without-an-exchange-timestamp).
