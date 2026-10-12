# Roadmap

Status as of the repositories' current `main` branches. Move items between sections in
the same change that finishes or starts them.

## Done

- Primitives: `fixed-decimal`, `exchange-core` (types and engine), `order-book`.
- Protocols for Hyperliquid, Binance USD-M and Bybit v5 linear.
- Simulators: `hl-sim`, `binance-sim`, `bybit-sim` over one engine, with seeded noise
  traders.
- Transport and clients: `venue-net`, `hl-client`, `binance-client`, `bybit-client`,
  each with a normalized `Live_feed`.
- Market making: `mm-core`, the three `Venue.S` adapters, `hl-mm`, the multi-venue
  `market-maker` binary and per-venue end-to-end scripts.
- Data: `parquet` writer, `market-data` (event logs, Parquet sink, day close, DuckDB
  views, replay feed, candles).
- Agent tooling: `oxcaml-claude-skills` (skills and gotchas log).
- Read-only feeds: `okx-feed`, `coinbase-feed`, `kraken-feed`, `deribit-feed`,
  `bitget-feed`, each a `Market_data.Feed.t` verified against the live venue.
- `equities-core`: US equities, options and futures semantics for the equities
  simulators.
- `nyse-sim`, `cboe-sim`, `cme-sim`: equities and futures simulators speaking NYSE
  Pillar and XDP, Cboe BOE and PITCH, and CME iLink 3 and MDP 3.0 over the engine, each
  with a CLI and an end-to-end script. See
  [design/simulators.md](design/simulators.md#tradfi-simulators).
- `market-recorder`: raw minute files, event logs, uploader, `/healthz` and `/metrics`
  for eight venues. See [repos/market-recorder.md](repos/market-recorder.md).
- `infra`: base and service images, compose stack, Helm chart, `check-pins.sh` in CI.
  See [repos/infra.md](repos/infra.md).
- `specs` research actions: replication gap detection and failure table, client pitfalls
  checklist, example queries, `Kind:` headers, postmortem template, simulator TIF table,
  [CHANGELOG.md](CHANGELOG.md).
- CI pins: every repository pins its sibling dependencies in dependency order
  (`infra/scripts/check-pins.sh -a` passes; `hl-mm` and `market-maker` now pin
  `parquet` and `market-data`).

### Wave 1 from research

The first batch of [research](research/README.md) actions, one line per repository; the
repository pages hold the details and measured numbers.

- `exchange-core`: `Input`, `Journal` and replay with event-stream diff, numbered events
  and `Book_replay`, `Stepped` harness, text trace, random-flow property with steps and
  marks, `Market_sim.Config.randomize` and inside-touch orders.
  [Page](repos/exchange-core.md).
- `order-book`: core_bench on a 1000-level book, release and `-O3` comparison, minor
  words per operation and a best-level cache, bisimulation against a naive matcher, fuzz
  property, pinned `~examples`, `or_null` and unboxing candidates.
  [Page](repos/order-book.md).
- `mm-core`: `?time_source` in `Live.Make`, seeded bugify venue, live-loop property test,
  stepped harness, tick-to-order stats, `soft_max_position` and `bump_budget`,
  `max_actions_per_sec`, typed unquoted reasons and `explain`, preset quotes, NaN checks
  in `validate`, quoter benchmarks. [Page](repos/mm-core.md).
- `market-data`: `check`, `catalog`, `dump -book-at`, day-close manifests and per-table
  stats, derived views, `Event_log` digest header, checked-in event log fixture, replay
  order and `Merge` properties, quickcheck on stable types, allocation-free `Framed`,
  query log, Python example. [Page](repos/market-data.md).
- `fixed-decimal`: `[@@immediate]` `t`, `lossy` alert on `of_float`, zarith property
  tests, must-fail type test, zero-allocation test, benchmarks, README examples checked
  by tests (mdx is not available). [Page](repos/fixed-decimal.md).
- `venue-net`: `?time_source`, reconnect jitter, handshake timeout, `Http.Record`,
  `with_timeout` audit. [Page](repos/venue-net.md).
- `infra`: commit-labelled and commit-tagged images, `make ps`, Helm defaults without
  `latest`, node-exporter and cAdvisor, test actions, recorder upgrade runbook,
  troubleshooting notes, `OCAMLRUNPARAM` comparison, memtrace on the base image.
  [Page](repos/infra.md).
- `oxcaml-claude-skills`: `check-obj-magic.sh`, agent workflow rules, `oxcaml-modes`
  examples built in CI, outcomes and exercises per skill, gotchas (dune cache, `X_unix`,
  `Bigstring_unix.write`, perf tooling). [Page](repos/oxcaml-claude-skills.md).
- `hl-sim`: request journal and replay, `-response-delay-ms`, `activeAssetCtx`,
  disconnecting slow websocket subscribers, `dune-cache` in CI.
  [Page](repos/hl-sim.md).
- `specs`: dune cache claim corrected, repository pages and this roadmap updated.

Real bugs found by the new tests:

- `fixed-decimal`: `div_units` overflowed in its long division for divisors above
  `max_value / 10` and returned wrong quotients; found by the zarith property, fixed in
  `016ab09`.
- `mm-core`: the reconciler could keep a resting order at the next ladder level's price,
  leaving two orders on one price level; found by the live-loop property, fixed in
  `c7697d9`.

## In progress

- `specs`: this repository.
- Wave 2 from research: every CI workflow pins the `ox` opam repository to the base
  image commit; `market-data` adds compatible `Event_log` digests and an
  `Instrument_info` catalogue (see [design/data-platform.md](design/data-platform.md)).

## Next

- **price-anchor**: anchor simulator markets to real venues: mark price via `set_mark`,
  shadow top-N levels, trade-replay fills. See
  [design/simulators.md](design/simulators.md#planned-price-anchor).
- **Replay server**: a `tardis-machine` style server that replays recorded raw minute
  files over HTTP and websocket in each venue's native format, so clients and the market
  maker can run against history.
- **Raw-to-norm tool**: drive the venue normalizers over stored raw files to rebuild
  `norm/` (the missing half of [ADR 0002](adr/0002-raw-first-storage.md)).
- **Native cloud sinks** when the conditions in
  [design/cloud-sinks-and-replication.md](design/cloud-sinks-and-replication.md#when-a-native-sink-is-justified)
  hold.
- **Replication**: two collectors per exchange in two regions, cross-region
  replication, merge by earliest `recv_ts` with gap fill.
- **AWS deployment**: k3s on EC2 in ap-northeast-1 (Binance, Hyperliquid) and
  ap-southeast-1 (Bybit). See [design/deployment.md](design/deployment.md).
- **Hyperliquid signing**: EIP-712 signing in `hl-client` so the market maker can trade
  on Hyperliquid testnet and mainnet.
- **specs upkeep**: every new repository and architecture change updates these pages
  (see [CLAUDE.md](CLAUDE.md)); refresh the `oxcaml-claude-skills` ecosystem map from
  [overview.md](overview.md).

### From research

Proposed actions from the [research notes](research/README.md), one line each, deduplicated
across themes. Each theme document orders its own list by value and links the sources.

#### State machines and logs ([theme](research/themes/state-machines-and-logs.md))

- `market-data`, clients: emit a gap event on `Live_feed` resync; document reconnect frame loss.
- `market-recorder`, clients: count per-stream parse errors on `/metrics`; test a malformed frame.
- `market-recorder`, `market-data`: log per-minute L2 snapshots; start `Replay_feed` from the last.
- `market-maker`: add a debug log of each `Strategy` input and plan; test replaying it.
- `market-recorder`: clamp `recv_ts` to non-decreasing per stream and count clamped frames.
- `market-recorder`: test subscribe frame counts at connect and reconnect for three symbols.
- `market-recorder`: report the last `Raw_writer` flush error and its age in `/healthz`.
- `market-recorder`: log repeated warnings once a minute per stream with a suppressed count.

#### Data platform ([theme](research/themes/data-platform.md))

- `infra`: run `market-data check` after the day-close job (the command exists).
- `market-data`: refine raw-to-norm with a one-day rebuild diffed against `norm/` and a skip-list.
- `market-recorder`: add a clock-error gauge sampled from `chronyc` to `/metrics`.
- `market-data`, `hl-client`: add `Funding.Stable.V2` with an optional `exch_ts` and a converter.
- `market-data`: have day close write a daily `instruments` table for point-in-time universes.
- `market-recorder`: add a latest `recv_ts - exch_ts` gauge (the `lag` view exists).
- `market-recorder`: test a stalled `Norm_writer` and print buffered events to check backpressure.
- `market-data`: write day-close Parquet in smaller row groups; confirm with `EXPLAIN ANALYZE`.
- `market-recorder`: add a `Venue_source.S` module type and register the clients as modules.
- `market-recorder`: export the `Parquet_sink` dropped count on `/metrics` if it adopts the sink.

#### OCaml and OxCaml practices ([theme](research/themes/ocaml-practices.md))

- all repos: add the `check-obj-magic.sh` job from `oxcaml-claude-skills` to CI.
- `mm-core`: use `Time_ns.Span.t` for the `_ms` fields of `Params.t`.
- `binance-client`, `hl-client`: add a key-less read-only config; type handles by trading access.
- `market-recorder`: tag `check-config` errors with the venue index; log `[%here]` in errors.
- `market-recorder`: test that 100 minute rolls keep the FD count flat; list C-backed handles.

#### Performance ([theme](research/themes/performance.md))

- `market-maker`: print `mm-core`'s tick-to-order p50/p99/max in `e2e-all.sh`.
- `market-recorder`, `mm-core`: export GC stats and RSS on `/metrics`; add GC counts to reports.
- `market-recorder`, `infra`: wire memtrace (confirmed on the ox base image) into recorder and Helm.
- `market-recorder`, `market-maker`: count Async cycles over 50 ms; warn on cycles over 20 ms.
- clients, `mm-core`: audit `with_timeout` for abandoned work, as `venue-net` did.
- `market-recorder`: bench one raw minute through normalizer and writer; record msgs/s and bytes.
- `binance-client`: bench `Feed_normalizer` per frame; print minor words per `Live_feed` message.
- `market-data`: prototype a day-close `-jobs` flag writing tables on domains.

#### Testing and simulation ([theme](research/themes/testing-and-simulation.md))

- protocol repos: check in a trimmed raw minute per venue; test decoding every frame.
- clients: feed recorded fixtures through each `Live_feed` normalizer; print per-stream counts.
- `market-recorder`: make `e2e-sims.sh` fail on missing files or alert conditions; run it in CI.
- `market-maker`: add a fault phase to `e2e-all.sh` restarting a simulator mid-run.
- `hl-mm`: run the live-loop test against `hl-sim -response-delay-ms` for double placement.
- simulators: pin each row of the
  [TIF and market order table](design/simulators.md#time-in-force-and-market-orders) in a test.
- `market-maker`: script one order sequence against `hl-sim` and `binance-sim`; diff fills.
- `hl-client`: record `l2Book` fixtures with `venue-net`'s record mode and decode them.
- `market-data`, `hl-sim`: compare trade share and BBO inter-arrival with live data.
- `market-data`: add a day-close diff script across revisions and a day-close cram test.
- `market-recorder`: test parsing every `examples/` config; add a replay load test.
- `hl-client`: refine signing with a test against an official SDK signature vector.

#### Research tooling ([theme](research/themes/research-tooling.md))

- `mm-core`: drive `Strategy` from `Replay_feed` over a fixture event log and print the quotes.
- `market-data`: test candles against DuckDB row for row on the event log fixture.
- `market-data`: run a pyarrow type test of `examples/query.py` in CI.
- `market-recorder`: add a `status -url` command printing `/metrics` as dense tables.
- `market-data`, `market-maker`: prototype Bonsai_term viewers for event logs and status.

#### Build and deploy ([theme](research/themes/build-and-deploy.md))

- `market-maker`: add nightly builds against upstream `main` and a weekly `e2e-all.sh` run.
- `market-maker`: print resolved pins in CI and every sibling's HEAD in `e2e-all.sh`.
- `order-book`, all repos: enable `dune-cache` in setup-ocaml after comparing `hl-sim` job times.
- `market-recorder`: add a `build_info` gauge (version, executable hash) to `/metrics`.
- `market-recorder`: export the open FD count; log `RLIMIT_NOFILE` limits at startup.
- `market-maker`, `hl-mm`, `market-recorder`: run shellcheck on `scripts/*.sh` in CI.
- `market-recorder`: export each `Recorder` to `Norm_writer` pipe length as a gauge.
- `market-recorder`: count `/healthz` flaps per stream as `healthz_flaps_total`.
- `market-recorder`: add a `GET /status` sexp of open minute files and pending uploads.
- `specs`, `infra`: refine AWS deployment with host checks and a chrony check in node bootstrap.
- `infra`: try proctopus for the local stack and note the result beside the compose stack.

#### Market making and trading systems ([theme](research/themes/market-making-and-trading-systems.md))

- `market-maker`, `mm-core`: add `-shadow-params` and a test printing differing plans.
- `market-maker`, `mm-core`: add `-params FILE` reloaded on SIGHUP after `Params.validate`.
- `market-maker`, `market-data`: log order lifecycle events; join fills to public trades.
- `hl-protocol`, `hl-mm`: decode `liquidationPx` as an option, `None` when out of range.
- `market-data`, `mm-core`: add a lead-lag query; record median lag per venue pair.
