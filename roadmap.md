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

## In progress

- `market-recorder`: raw minute files, event logs, uploader, `/healthz` and `/metrics`,
  `market-recorder run -config`. See [repos/market-recorder.md](repos/market-recorder.md).
- `infra`: base and service images, compose stack, Helm chart, local and AWS notes. See
  [repos/infra.md](repos/infra.md).
- `specs`: this repository.
- CI pins: `hl-mm` and `market-maker` do not pin `parquet` and `market-data`, which
  their client dependencies now need.

## Next

- **price-anchor**: anchor simulator markets to real venues: mark price via `set_mark`,
  shadow top-N levels, trade-replay fills. See
  [design/simulators.md](design/simulators.md#planned-price-anchor).
- **Replay server**: a `tardis-machine` style server that replays recorded raw minute
  files over HTTP and websocket in each venue's native format, so clients and the market
  maker can run against history.
- **Raw-to-norm tool**: drive the venue normalizers over stored raw files to rebuild
  `norm/` (the missing half of [ADR 0002](adr/0002-raw-first-storage.md)).
- **More exchanges** as `*-feed` repositories (read-only market data: protocol types,
  `Live_feed`, no trading): OKX, Coinbase, Kraken, Deribit, Bitget.
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

- `exchange-core`: journal engine inputs, replay them into a fresh engine and diff event streams.
- `market-data`, clients: emit a gap event on `Live_feed` resync; document reconnect frame loss.
- `market-recorder`, clients: count per-stream parse errors on `/metrics`; test a malformed frame.
- `market-recorder`, `market-data`: log per-minute L2 snapshots; start `Replay_feed` from the last.
- `specs`: refine replication with sequence-gap detection, peer fill, clock bound and failure table.
- `market-data`: write a `bin_shape` digest header per `Event_log` file; fail readers on mismatch.
- `market-data`: check in an event log from today's code; test that later versions still read it.
- `exchange-core`: number engine events; replay drained events into a fresh book and compare L2.
- `hl-sim`: log accepted `/exchange` requests; test that replaying them gives identical fills.
- `market-data`: pin global replay order with an expect test and a `Merge` Quickcheck property.
- `market-maker`: add a debug log of each `Strategy` input and plan; test replaying it.
- `mm-core`, `exchange-core`: drive `Strategy` in a deterministic stepped harness; pin seeded fills.
- `market-recorder`: clamp `recv_ts` to non-decreasing per stream and count clamped frames.
- `market-data`: add a `dump` subcommand printing `Event_log` records, then a `-book-at` option.
- `market-data`: make `Replay_feed` fail explicitly on a date range with no event log files.
- `market-recorder`: test subscribe frame counts at connect and reconnect for three symbols.
- `market-recorder`: report the last `Raw_writer` flush error and its age in `/healthz`.
- `market-recorder`: log repeated warnings once a minute per stream with a suppressed count.

#### Data platform ([theme](research/themes/data-platform.md))

- `market-data`, `infra`: add a DuckDB `check` command with a gap view; run it after day close.
- `market-data`: add a `units_per_contract` view; test that per-token mids agree across venues.
- `market-data`: write a day-close manifest per table; skip days whose inputs match it.
- `market-data`: refine raw-to-norm with a one-day rebuild diffed against `norm/` and a skip-list.
- `market-data`: add a `catalog` command listing per-table venues, symbols, dates and parts.
- `market-recorder`: add a clock-error gauge sampled from `chronyc` to `/metrics`.
- `market-data`, `hl-client`: add `Funding.Stable.V2` with an optional `exch_ts` and a converter.
- `market-data`: have day close write a daily `instruments` table for point-in-time universes.
- `market-data`, `market-recorder`: add a `recv_ts - exch_ts` p50/p99 view and a latest-lag gauge.
- `market-recorder`: test a stalled `Norm_writer` and print buffered events to check backpressure.
- `market-data`: write day-close Parquet in smaller row groups; confirm with `EXPLAIN ANALYZE`.
- `market-recorder`: add a `Venue_source.S` module type and register the clients as modules.
- `specs`: add a client-pitfalls checklist to the data-platform design, each item tied to a test.
- `market-data`: log per-table input frames, replaced parts and output bytes in day close.
- `market-recorder`: export the `Parquet_sink` dropped count on `/metrics` if it adopts the sink.
- `specs`: state that raw zstd files serve sequential replay only; point queries use Parquet.

#### OCaml and OxCaml practices ([theme](research/themes/ocaml-practices.md))

- `oxcaml-claude-skills`: add a CI grep failing on `Obj.magic` outside an allowlist; roll it out.
- `fixed-decimal`: pin `of_float` on NaN, infinities and `-0.0`; add a `lossy` alert.
- `mm-core`: destructure `Params.t` in `validate` without a wildcard; use `Time_ns.Span.t` fields.
- `oxcaml-claude-skills`: add an agent workflow section: plan review, signatures and types first.
- `oxcaml-claude-skills`: add rules: failing test before fix, pin counterexamples, justify removals.
- `oxcaml-claude-skills`: extend `oxcaml-modes` with compiling local, unique and borrow examples.
- `fixed-decimal`: add a must-fail compile test passing a `Price.t` where `Size.t` is expected.
- `binance-client`, `hl-client`: add a key-less read-only config; type handles by trading access.
- `market-recorder`: tag `check-config` errors with the venue index; log `[%here]` in errors.
- `fixed-decimal`: run README examples with mdx and pilot `@doc` with warnings as errors.
- `market-data`: derive `quickcheck` on `Stable.V1` records; add a bin_io round-trip property.
- `market-recorder`: test that 100 minute rolls keep the FD count flat; list C-backed handles.
- `oxcaml-claude-skills`: add gotchas on `X_unix` renames, `Bigstring_unix.write` and strace-ui.
- `oxcaml-claude-skills`: give each skill 3-5 reference modules, outcomes and exercises.

#### Performance ([theme](research/themes/performance.md))

- `order-book`: add a core_bench for submit, cancel and match on a 1000-level book; record it.
- `order-book`: print minor words per operation; add `exclave_` variants if queries allocate.
- `mm-core`, `market-maker`: report tick-to-order latency p50/p99/max; print it in `e2e-all.sh`.
- `market-recorder`, `mm-core`: export GC stats and RSS on `/metrics`; add GC counts to reports.
- `market-recorder`, `infra`: confirm memtrace works on OxCaml; wire it into recorder and Helm.
- `market-recorder`, `market-maker`: count Async cycles over 50 ms; warn on cycles over 20 ms.
- clients, `mm-core`, `venue-net`: audit `with_timeout` for abandoned work; log gotchas.
- `market-recorder`: bench one raw minute through normalizer and writer; record msgs/s and bytes.
- `fixed-decimal`: mark `t` `[@@immediate]`; bench `mul`, `div` and `Product.mul` for zero words.
- `mm-core`: print minor words per `Quoter.quote` call and add a core_bench case for it.
- `binance-client`: bench `Feed_normalizer` per frame; print minor words per `Live_feed` message.
- `hl-sim`: test that a websocket subscriber that never reads does not delay other clients' acks.
- `infra`: document comparing `OCAMLRUNPARAM=o` settings by peak RSS and CPU time.
- `order-book`: compare the release build with `-O3` once benched; log the result as a gotcha.
- `order-book`: list hot-path records that would gain from unboxed fields or `or_null`.
- `market-data`: check whether `Framed` allocates per frame; decode into a caller buffer if so.
- `oxcaml-claude-skills`: add gotchas on perf and bpftrace uprobes and magic-trace limits.
- `market-data`: time day close per table; prototype a `-jobs` flag writing tables on domains.

#### Testing and simulation ([theme](research/themes/testing-and-simulation.md))

- `mm-core`: add a seeded bugify mode to the `Venue.S` test fake; test adopting a late place.
- `mm-core`: thread `Time_source.t` through `Live.Make`; property-test quotes and position limit.
- `venue-net`: add `?time_source` to `Ws_client` timers; test reconnect and a stalled handshake.
- `order-book`: add a bisimulation property against a naive sorted-list matcher.
- `exchange-core`: add `step` and `set_mark` to the random-flow property; assert zero net position.
- protocol repos: check in a trimmed raw minute per venue; test decoding every frame.
- clients: feed recorded fixtures through each `Live_feed` normalizer; print per-stream counts.
- `fixed-decimal`: property-test `mul_units`, `div_units` and `Product.mul` against Bigint.
- `market-recorder`: make `e2e-sims.sh` fail on missing files or alert conditions; run it in CI.
- `market-maker`: add a fault phase to `e2e-all.sh` restarting a simulator mid-run.
- `infra`: add `test-actions/` scripts (orders, recorder restart, network cut) for chaos tests.
- `order-book`: pin property counterexamples via `~examples`; add a byte-string fuzz property.
- `market-data`: property-test that random `Framed` buffer and flush sizes read back the same.
- `hl-sim`, `hl-mm`: add `-response-delay-ms`; run the live-loop test for double placement.
- simulators, `specs`: table each venue's `Tif` and slippage semantics; pin each in a test.
- `market-maker`: script one order sequence against `hl-sim` and `binance-sim`; diff fills.
- `venue-net`, `hl-client`: add HTTP record mode; check in and decode `l2Book` fixtures.
- `exchange-core`, `mm-core`: add text-trace expect tests of book, margin and quotes per step.
- `exchange-core`: add `Market_sim.Config.randomize ~seed` and inside-touch noise orders.
- `market-data`, `hl-sim`: compare trade share and BBO inter-arrival with live data.
- `market-data`: add a day-close diff script across revisions and a day-close cram test.
- `market-recorder`: test parsing every `examples/` config; add a replay load test.
- `hl-client`: refine signing with a test against an official SDK signature vector.

#### Research tooling ([theme](research/themes/research-tooling.md))

- `mm-core`: drive `Strategy` from `Replay_feed` over a fixture event log and print the quotes.
- `market-data`: check in a real event log fixture; test candles against DuckDB row for row.
- `market-data`: add a `trades_with_bbo` view joining each trade to the prevailing BBO.
- `market-data`: ship `examples/query.py`, a pyarrow type test and pandas timestamp docs.
- `specs`: add a page of example DuckDB queries with column notes and a replay sizing query.
- `market-data`: log each `query` call's time, user and SQL to `query-log.ndjson`.
- `market-recorder`: add a `status -url` command printing `/metrics` as dense tables.
- `market-data`, `market-maker`: prototype Bonsai_term viewers for event logs and status.
- `specs`: add a "Kind:" header convention to CLAUDE.md and apply it to `design/`.

#### Build and deploy ([theme](research/themes/build-and-deploy.md))

- `infra`, all repos: pin the `ox` opam repository to the base image commit in every CI workflow.
- `market-maker`: add nightly builds against upstream `main` and a weekly `e2e-all.sh` run.
- `infra`: derive CI pin order from `dune-project` files; fail on missing or misordered pins.
- `specs`: close the CI pins item; repository pages still report two unpinned dependencies.
- `infra`: label images with the built commit and each pinned sibling's commit; show in `make ps`.
- `infra`: tag images by commit; reference explicit tags in the Helm defaults, not `latest`.
- `market-maker`: print resolved pins in CI and every sibling's HEAD in `e2e-all.sh`.
- `hl-sim`, `order-book`: enable `dune-cache` in setup-ocaml, compare job times, then roll out.
- `market-recorder`: add a `build_info` gauge (version, executable hash) to `/metrics`.
- `market-recorder`: export the open FD count; log `RLIMIT_NOFILE` limits at startup.
- `market-maker`, `hl-mm`, `market-recorder`: run shellcheck on `scripts/*.sh` in CI.
- `market-recorder`: export each `Recorder` to `Norm_writer` pipe length as a gauge.
- `market-recorder`: count `/healthz` flaps per stream as `healthz_flaps_total`.
- `market-recorder`: add a `GET /status` sexp of open minute files and pending uploads.
- `infra`: write a runbook for upgrading the recorder Helm release.
- `specs`, `infra`: refine AWS deployment with host checks and a chrony check in node bootstrap.
- `infra`: add troubleshooting notes for `ss -tipn` and uploads during DNS outages.
- `infra`: add node-exporter or another socket and FD collector to compose and Helm.
- `specs`: add a postmortem template under `postmortems/`.
- `oxcaml-claude-skills`: document that dune's shared cache serves per-agent build directories.
- `infra`: try proctopus for the local stack and note the result beside the compose stack.

#### Market making and trading systems ([theme](research/themes/market-making-and-trading-systems.md))

- `mm-core`: property-test that reconciling after applying a plan yields only `Keep`.
- `mm-core`: add an actions-per-second cap to `Risk` that trips the kill switch.
- `venue-net`: add jitter to `Ws_client` backoff and log the chosen delay.
- `mm-core`: test `Params.for_instrument` and `max_position` on a 1000x-contract instrument.
- `mm-core`: property-test that `Risk.flatten` only places reduce-only orders.
- `market-maker`, `mm-core`: add `-shadow-params` and a test printing differing plans.
- `market-maker`, `mm-core`: add `-params FILE` reloaded on SIGHUP after `Params.validate`.
- `market-maker`, `market-data`: log order lifecycle events; join fills to public trades.
- `mm-core`: add `soft_max_position` with a bump budget pulling only the growing side.
- `mm-core`: add `Quoter.For_testing.explain` and typed reasons for unquoted sides.
- `mm-core`: print quotes for a fixed state and inventory under each `Params` preset.
- `hl-protocol`, `hl-mm`: decode `liquidationPx` as an option, `None` when out of range.
- `market-data`, `mm-core`: add a lead-lag query; record median lag per venue pair.
- `mm-core`: test that NaN in any float `Params` field fails `validate`.
