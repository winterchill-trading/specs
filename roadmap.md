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
- Raw-to-norm tool: `market-recorder rebuild-norm` links every venue's
  `Market_data.Normalizer.S` adapter, with `-venue` and a `-skip venue:stream` list
  [`5c13f5c`][market-recorder-5c13f5c] [`3d433dd`][market-recorder-3d433dd]; a 20 s
  recording of the three simulators rebuilds into 22 byte-identical event logs
  (`scripts/e2e-rebuild.sh`, [`119042c`][market-recorder-119042c]). Completes
  [ADR 0002](adr/0002-raw-first-storage.md); the L2 snapshot index is not rebuilt.
- `infra`: base and service images, compose stack, Helm chart, `check-pins.sh` in CI.
  See [repos/infra.md](repos/infra.md).
- `specs` research actions: replication gap detection and failure table, client pitfalls
  checklist, example queries, `Kind:` headers, postmortem template, simulator TIF table,
  [CHANGELOG.md](CHANGELOG.md).
- `price-anchor`: simulator markets tied to a reference venue, live or recorded (mark
  and funding, shadow top-N levels, trade-replay fills, staleness), and the TradFi path
  (half-life pull, venue phases, venue clock, `clamp`, `path`). Wired into
  [hl-sim](repos/hl-sim.md), [binance-sim](repos/binance-sim.md),
  [bybit-sim](repos/bybit-sim.md), [nyse-sim](repos/nyse-sim.md),
  [cboe-sim](repos/cboe-sim.md) and [cme-sim](repos/cme-sim.md); the TradFi three can
  replace their `Anchoring` modules with `Anchor` (mapping in the price-anchor README).
  See [repos/price-anchor.md](repos/price-anchor.md) and
  [design/price-anchor.md](design/price-anchor.md).
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

### Wave 2 from research

The second batch of research actions. Commit links point at the change that introduced
each feature; the repository pages hold the details and numbers.

- All repositories: every CI workflow pins the `ox` opam repository to the base image
  commit (for example [`a7fdae0`][market-data-a7fdae0], [`e91dc3e`][hl-client-e91dc3e]).
- `market-data`: append-only compatible `Event_log` digests
  [`73df673`][market-data-73df673] ([ADR
  0006](adr/0006-compatible-event-log-digests.md)) with a pre-extension fixture
  [`6c3fd6c`][market-data-6c3fd6c]; `Instrument_info` catalogue (kind, size unit,
  funding interval, tick, lot) [`31c5547`][market-data-31c5547] and
  `Funding.normalized_8h` [`f36a1a4`][market-data-f36a1a4]; per-minute L2
  `Snapshot_index` [`059c226`][market-data-059c226] and `Replay_feed` starting from a
  snapshot [`6bce54d`][market-data-6bce54d]; `day-close -jobs`
  [`7a22217`][market-data-7a22217] and `-processes` [`841347c`][market-data-841347c];
  `Raw_minute`, `Normalizer.S` and `rebuild-norm` [`41f0137`][market-data-41f0137]
  [`0b1e244`][market-data-0b1e244]. [Page](repos/market-data.md).
- `market-recorder`: `recv_ts` clamp with a clamped-frame count
  [`1b6231b`][market-recorder-1b6231b]; raw writer failures on `/healthz`
  [`d2c151e`][market-recorder-d2c151e]; rate-limited warnings
  [`d77e995`][market-recorder-d77e995]; `build_info`
  [`e5cabb5`][market-recorder-e5cabb5], open FD, RSS and GC gauges
  [`e93afcc`][market-recorder-e93afcc]; norm pipe length
  [`4cbfdf4`][market-recorder-4cbfdf4]; `healthz_flaps_total`
  [`86719f2`][market-recorder-86719f2]; `GET /status`
  [`5d0dd08`][market-recorder-5d0dd08] and `status -url`
  [`4522dcc`][market-recorder-4522dcc]; `e2e-sims.sh` failing on problems
  [`d426706`][market-recorder-d426706]; throughput bench
  [`081cbc8`][market-recorder-081cbc8]; flat FD count over 100 rolls
  [`8213d74`][market-recorder-8213d74]; every example config parsed
  [`d70a6a3`][market-recorder-d70a6a3]; shellcheck in CI
  [`0b0fcc2`][market-recorder-0b0fcc2]; per-minute L2 snapshots
  [`c67c662`][market-recorder-c67c662]. [Page](repos/market-recorder.md).
- `market-maker`: tick-to-order latency at exit and in `e2e-all.sh`
  [`4b71c76`][market-maker-4b71c76]; fault phase restarting a simulator
  [`405a79f`][market-maker-405a79f]; `-params FILE` reloaded on SIGHUP
  [`4647bc4`][market-maker-4647bc4]; `-shadow-params` [`62e8d18`][market-maker-62e8d18];
  strategy log and replay [`64e4bd8`][market-maker-64e4bd8]; `compare-venues.sh`
  [`6966e8a`][market-maker-6966e8a]; sibling commits in `e2e-all.sh`
  [`c4ab82d`][market-maker-c4ab82d]; shellcheck and resolved pins in CI
  [`de992b4`][market-maker-de992b4]. [Page](repos/market-maker.md).
- `hl-client`: pure OCaml Keccak-256 [`777e47c`][hl-client-777e47c] and MessagePack
  [`4df4fe3`][hl-client-4df4fe3]; EIP-712 secp256k1 signing
  [`89bd8a7`][hl-client-89bd8a7] matching the SDK vectors
  [`09e5292`][hl-client-09e5292]; typed read-only and trading handles
  [`31862fe`][hl-client-31862fe]; `Live_feed` stats [`189cc81`][hl-client-189cc81];
  recorded mainnet minute [`3b829cf`][hl-client-3b829cf]; `Ws` time source and jitter
  [`5e54d72`][hl-client-5e54d72]. [Page](repos/hl-client.md).
- `binance-client`: key-less `Config.Read_only` [`29860ab`][binance-client-29860ab];
  `Live_feed` stats [`7db5265`][binance-client-7db5265] and time source
  [`9eee6db`][binance-client-9eee6db]; recorded fixtures
  [`326c118`][binance-client-326c118]; normalizer bench
  [`7aac2b7`][binance-client-7aac2b7]. [Page](repos/binance-client.md).
- `bybit-client`: `Config.Read_only` [`3f443a6`][bybit-client-3f443a6]; `Live_feed`
  stats [`8cd80b9`][bybit-client-8cd80b9]; one decode per frame
  [`48ffe19`][bybit-client-48ffe19]; recorded fixtures
  [`8e58e31`][bybit-client-8e58e31]; bench [`a846534`][bybit-client-a846534].
  [Page](repos/bybit-client.md).
- `specs`: compatible digests and the instrument catalogue in the data platform design
  [`44de7da`][specs-44de7da]; research insights marked done [`b01499f`][specs-b01499f].

### Wave 3 from research

- `infra`: the `ox-setup` composite action caching the whole opam switch
  [`55d842f`][infra-55d842f], keyed on the runner image [`b97643b`][infra-b97643b];
  `check-pins.sh` reads its `pins:` block [`8840b3b`][infra-8840b3b] and checks the `ox`
  commit [`1e297d6`][infra-1e297d6]; migration guide and timings
  [`2023287`][infra-2023287]; `hl-sim` is the pilot [`e182ab9`][hl-sim-e182ab9]. See
  [design/deployment.md](design/deployment.md#ci).
- `hl-protocol`: `Asset_ctx` for `activeAssetCtx` [`4afc464`][hl-protocol-4afc464];
  `liquidationPx` as an option [`4399f2f`][hl-protocol-4399f2f]; mainnet info and
  websocket samples [`c64ea0d`][hl-protocol-c64ea0d]. [Page](repos/hl-protocol.md).
- `hl-mm`: `Hl_venue.Trading` over a signing handle [`0a43f23`][hl-mm-0a43f23];
  `-testnet` signing with `HL_PRIVATE_KEY`, mainnet refused [`c484c80`][hl-mm-c484c80];
  `-params FILE` [`f6d86c3`][hl-mm-f6d86c3]; tick-to-order latency
  [`d46d9c2`][hl-mm-d46d9c2]; live loop with 500 ms acks [`e2e8474`][hl-mm-e2e8474];
  seeded `Bugged_venue` [`c21b5d7`][hl-mm-c21b5d7]; shellcheck in CI
  [`f54cdef`][hl-mm-f54cdef]. [Page](repos/hl-mm.md).
- Five feeds: `Live_feed` stats ([`5120a5f`][okx-feed-5120a5f],
  [`d9be009`][coinbase-feed-d9be009], [`90caa21`][kraken-feed-90caa21],
  [`4f2908f`][deribit-feed-4f2908f], [`2714232`][bitget-feed-2714232]), a
  `Market_data.Normalizer.S` adapter ([`e8077e9`][okx-feed-e8077e9],
  [`dd5c590`][coinbase-feed-dd5c590], [`27c4015`][kraken-feed-27c4015],
  [`ecd2245`][deribit-feed-ecd2245], [`3e048e3`][bitget-feed-3e048e3]; `kraken-feed` and
  `deribit-feed` add a `rebuild-norm` subcommand), `?time_source`
  ([`13301d8`][okx-feed-13301d8], [`6221878`][coinbase-feed-6221878],
  [`ab0003f`][kraken-feed-ab0003f], [`723cb9d`][deribit-feed-723cb9d],
  [`f1b2620`][bitget-feed-f1b2620]), a recorded mainnet minute with allocation pins, and
  a core_bench of the normalizer ([`923fd76`][okx-feed-923fd76],
  [`a7a10d5`][coinbase-feed-a7a10d5], [`9871b5d`][kraken-feed-9871b5d],
  [`7615a21`][deribit-feed-7615a21], [`1ef23bf`][bitget-feed-1ef23bf]). Pages:
  [okx](repos/okx-feed.md), [coinbase](repos/coinbase-feed.md),
  [kraken](repos/kraken-feed.md), [deribit](repos/deribit-feed.md),
  [bitget](repos/bitget-feed.md).

Bugs found in waves 2 and 3:

- `hl-client`: `Live_feed` passed each `l2Book` frame to `on_raw` under both `Bbo` and
  `L2`, so the recorder stored it twice; fixed in [`189cc81`][hl-client-189cc81].
- `market-recorder`: buffered lines could be written before the minute file was open
  (the `test_raw_writer` flake on Linux CI, `Bad file descriptor`); fixed in
  [`5f97596`][market-recorder-5f97596].
- `hl-protocol`: a `liquidationPx` beyond the fixed-point range failed the whole
  clearinghouse decode [`4399f2f`][hl-protocol-4399f2f], and `subscriptionResponse`
  echoes of unmodelled subscriptions failed to decode [`1964453`][hl-protocol-1964453].
- `binance-client`: `with_timeout` around `Pipe.read` in tests left a read pending that
  swallowed the next value [`e15212b`][binance-client-e15212b].
- `infra`: the switch cache key missed the runner image, so an Ubuntu release change
  could restore an incompatible switch [`b97643b`][infra-b97643b].

### Wave 4

- Hardening: `mm-core` hot parameter updates (`Strategy.update_params`, `Live.connect_and_start`
  returns the loop handle) and a rolling action-rate window with grace and cooldown;
  `market-recorder` parse-error and reconnect counters on `/metrics` with Prometheus alert
  rules; `market-maker` reloads through `Live.update_params`; every repository's CI uses the
  `ox-setup` action (warm runs 1.5 to 2.5 minutes). See
  [design/deployment.md](design/deployment.md#ci).

### Wave 5

- Replay: `market-replay` HTTP raw replay and native websocket replay for Hyperliquid,
  Binance and Bybit, paced by `-speed`; `market-data` rebuild gains the L2 snapshot index.
  See [repos/market-replay.md](repos/market-replay.md).

- **Hyperliquid trading** in `market-maker`: `-venue hyperliquid` signs through
  `Hl_venue.Trading` when `HL_PRIVATE_KEY` is set and stays unsigned otherwise; signing
  for mainnet needs `-i-understand-mainnet` [`26ae36e`][market-maker-26ae36e]; a signed
  run on an in-process `hl-sim` under a synthetic clock checks the recovered signer
  [`6b767a8`][market-maker-6b767a8]; `SIGNED=1 scripts/e2e.sh hl` checks the simulator's
  journal [`1ae81da`][market-maker-1ae81da]. No order has been placed on testnet with a
  funded account yet. [Page](repos/market-maker.md).

### Wave 6

- Replication, gaps and hardening. `market-recorder`: `merge` identifies frames by venue
  sequence ([`fd4b1c2`][market-recorder-fd4b1c2]), lists exact gaps
  ([`e01f00e`][market-recorder-e01f00e]), reports suspected gaps from silence
  ([`d5b6f56`][market-recorder-d5b6f56]), takes `-clock-error`
  ([`d6f5653`][market-recorder-d6f5653]), matches across midnight
  ([`5e2681b`][market-recorder-5e2681b]); collector ids honoured by `merge` and
  `rebuild-norm` ([`dfc1ac9`][market-recorder-dfc1ac9],
  [`b31caf8`][market-recorder-b31caf8], [`c7f2317`][market-recorder-c7f2317]); client gaps
  write disconnect lines and `gaps_total` ([`6eb774e`][market-recorder-6eb774e]); clock
  error, exchange lag, long cycle and `max_fds` gauges
  ([`af7e618`][market-recorder-af7e618], [`a119187`][market-recorder-a119187],
  [`788836b`][market-recorder-788836b], [`d62cff1`][market-recorder-d62cff1]); subscribe
  and stalled event log tests ([`8312421`][market-recorder-8312421],
  [`9539251`][market-recorder-9539251]); `check-config` venue index
  ([`9e96f3e`][market-recorder-9e96f3e]); `e2e-sims.sh` in CI
  ([`968c1a4`][market-recorder-968c1a4]); `MEMTRACE` ([`f15e611`][market-recorder-f15e611]).
  `market-replay`: websocket replay for OKX, Coinbase, Kraken, Deribit and Bitget, tested
  with each feed's `Live_feed`; speed 0 Binance replays hold at a recorded depth snapshot's
  join point. `market-data`: `Funding.Stable.V2` with an optional `exch_ts`
  ([`64381d1`][market-data-64381d1], [`a61ead7`][market-data-a61ead7]), the daily
  `instruments` table ([`3c978c7`][market-data-3c978c7]), 64k row groups
  ([`cc0fd95`][market-data-cc0fd95]), candles checked against DuckDB
  ([`1431404`][market-data-1431404]), a pyarrow type test in CI
  ([`194c72b`][market-data-194c72b]), `scripts/daycheck-diff.sh`
  ([`5c654e9`][market-data-5c654e9], [`cda1a10`][market-data-cda1a10]) and
  `queries/lead_lag.sql` ([`3f4cef2`][market-data-3f4cef2]): Binance leads Bybit, OKX and
  Bitget by 17 to 33 ms on 85 s of mainnet BTC perpetuals. See
  [repos/market-recorder.md](repos/market-recorder.md),
  [repos/market-replay.md](repos/market-replay.md) and
  [repos/market-data.md](repos/market-data.md).

[market-data-a7fdae0]: https://github.com/winterchill-trading/market-data/commit/a7fdae0
[hl-client-e91dc3e]: https://github.com/winterchill-trading/hl-client/commit/e91dc3e
[market-data-73df673]: https://github.com/winterchill-trading/market-data/commit/73df673
[market-data-6c3fd6c]: https://github.com/winterchill-trading/market-data/commit/6c3fd6c
[market-data-31c5547]: https://github.com/winterchill-trading/market-data/commit/31c5547
[market-data-f36a1a4]: https://github.com/winterchill-trading/market-data/commit/f36a1a4
[market-data-059c226]: https://github.com/winterchill-trading/market-data/commit/059c226
[market-data-6bce54d]: https://github.com/winterchill-trading/market-data/commit/6bce54d
[market-data-7a22217]: https://github.com/winterchill-trading/market-data/commit/7a22217
[market-data-841347c]: https://github.com/winterchill-trading/market-data/commit/841347c
[market-data-41f0137]: https://github.com/winterchill-trading/market-data/commit/41f0137
[market-data-0b1e244]: https://github.com/winterchill-trading/market-data/commit/0b1e244
[market-recorder-1b6231b]: https://github.com/winterchill-trading/market-recorder/commit/1b6231b
[market-recorder-d2c151e]: https://github.com/winterchill-trading/market-recorder/commit/d2c151e
[market-recorder-d77e995]: https://github.com/winterchill-trading/market-recorder/commit/d77e995
[market-recorder-e5cabb5]: https://github.com/winterchill-trading/market-recorder/commit/e5cabb5
[market-recorder-e93afcc]: https://github.com/winterchill-trading/market-recorder/commit/e93afcc
[market-recorder-4cbfdf4]: https://github.com/winterchill-trading/market-recorder/commit/4cbfdf4
[market-recorder-86719f2]: https://github.com/winterchill-trading/market-recorder/commit/86719f2
[market-recorder-5d0dd08]: https://github.com/winterchill-trading/market-recorder/commit/5d0dd08
[market-recorder-5c13f5c]: https://github.com/winterchill-trading/market-recorder/commit/5c13f5c
[market-recorder-3d433dd]: https://github.com/winterchill-trading/market-recorder/commit/3d433dd
[market-recorder-119042c]: https://github.com/winterchill-trading/market-recorder/commit/119042c
[market-recorder-4522dcc]: https://github.com/winterchill-trading/market-recorder/commit/4522dcc
[market-recorder-d426706]: https://github.com/winterchill-trading/market-recorder/commit/d426706
[market-recorder-081cbc8]: https://github.com/winterchill-trading/market-recorder/commit/081cbc8
[market-recorder-8213d74]: https://github.com/winterchill-trading/market-recorder/commit/8213d74
[market-recorder-d70a6a3]: https://github.com/winterchill-trading/market-recorder/commit/d70a6a3
[market-recorder-0b0fcc2]: https://github.com/winterchill-trading/market-recorder/commit/0b0fcc2
[market-recorder-c67c662]: https://github.com/winterchill-trading/market-recorder/commit/c67c662
[market-maker-4b71c76]: https://github.com/winterchill-trading/market-maker/commit/4b71c76
[market-maker-405a79f]: https://github.com/winterchill-trading/market-maker/commit/405a79f
[market-maker-4647bc4]: https://github.com/winterchill-trading/market-maker/commit/4647bc4
[market-maker-62e8d18]: https://github.com/winterchill-trading/market-maker/commit/62e8d18
[market-maker-64e4bd8]: https://github.com/winterchill-trading/market-maker/commit/64e4bd8
[market-maker-6966e8a]: https://github.com/winterchill-trading/market-maker/commit/6966e8a
[market-maker-c4ab82d]: https://github.com/winterchill-trading/market-maker/commit/c4ab82d
[market-maker-de992b4]: https://github.com/winterchill-trading/market-maker/commit/de992b4
[hl-client-777e47c]: https://github.com/winterchill-trading/hl-client/commit/777e47c
[hl-client-4df4fe3]: https://github.com/winterchill-trading/hl-client/commit/4df4fe3
[hl-client-89bd8a7]: https://github.com/winterchill-trading/hl-client/commit/89bd8a7
[hl-client-09e5292]: https://github.com/winterchill-trading/hl-client/commit/09e5292
[hl-client-31862fe]: https://github.com/winterchill-trading/hl-client/commit/31862fe
[hl-client-189cc81]: https://github.com/winterchill-trading/hl-client/commit/189cc81
[hl-client-3b829cf]: https://github.com/winterchill-trading/hl-client/commit/3b829cf
[hl-client-5e54d72]: https://github.com/winterchill-trading/hl-client/commit/5e54d72
[binance-client-29860ab]: https://github.com/winterchill-trading/binance-client/commit/29860ab
[binance-client-7db5265]: https://github.com/winterchill-trading/binance-client/commit/7db5265
[binance-client-9eee6db]: https://github.com/winterchill-trading/binance-client/commit/9eee6db
[binance-client-326c118]: https://github.com/winterchill-trading/binance-client/commit/326c118
[binance-client-7aac2b7]: https://github.com/winterchill-trading/binance-client/commit/7aac2b7
[bybit-client-3f443a6]: https://github.com/winterchill-trading/bybit-client/commit/3f443a6
[bybit-client-8cd80b9]: https://github.com/winterchill-trading/bybit-client/commit/8cd80b9
[bybit-client-48ffe19]: https://github.com/winterchill-trading/bybit-client/commit/48ffe19
[bybit-client-8e58e31]: https://github.com/winterchill-trading/bybit-client/commit/8e58e31
[bybit-client-a846534]: https://github.com/winterchill-trading/bybit-client/commit/a846534
[specs-44de7da]: https://github.com/winterchill-trading/specs/commit/44de7da
[specs-b01499f]: https://github.com/winterchill-trading/specs/commit/b01499f
[infra-55d842f]: https://github.com/winterchill-trading/infra/commit/55d842f
[infra-b97643b]: https://github.com/winterchill-trading/infra/commit/b97643b
[infra-8840b3b]: https://github.com/winterchill-trading/infra/commit/8840b3b
[infra-1e297d6]: https://github.com/winterchill-trading/infra/commit/1e297d6
[infra-2023287]: https://github.com/winterchill-trading/infra/commit/2023287
[hl-sim-e182ab9]: https://github.com/winterchill-trading/hl-sim/commit/e182ab9
[hl-protocol-4afc464]: https://github.com/winterchill-trading/hl-protocol/commit/4afc464
[hl-protocol-4399f2f]: https://github.com/winterchill-trading/hl-protocol/commit/4399f2f
[hl-protocol-c64ea0d]: https://github.com/winterchill-trading/hl-protocol/commit/c64ea0d
[hl-mm-0a43f23]: https://github.com/winterchill-trading/hl-mm/commit/0a43f23
[hl-mm-c484c80]: https://github.com/winterchill-trading/hl-mm/commit/c484c80
[hl-mm-f6d86c3]: https://github.com/winterchill-trading/hl-mm/commit/f6d86c3
[hl-mm-d46d9c2]: https://github.com/winterchill-trading/hl-mm/commit/d46d9c2
[hl-mm-e2e8474]: https://github.com/winterchill-trading/hl-mm/commit/e2e8474
[hl-mm-c21b5d7]: https://github.com/winterchill-trading/hl-mm/commit/c21b5d7
[hl-mm-f54cdef]: https://github.com/winterchill-trading/hl-mm/commit/f54cdef
[okx-feed-5120a5f]: https://github.com/winterchill-trading/okx-feed/commit/5120a5f
[coinbase-feed-d9be009]: https://github.com/winterchill-trading/coinbase-feed/commit/d9be009
[kraken-feed-90caa21]: https://github.com/winterchill-trading/kraken-feed/commit/90caa21
[deribit-feed-4f2908f]: https://github.com/winterchill-trading/deribit-feed/commit/4f2908f
[bitget-feed-2714232]: https://github.com/winterchill-trading/bitget-feed/commit/2714232
[okx-feed-e8077e9]: https://github.com/winterchill-trading/okx-feed/commit/e8077e9
[coinbase-feed-dd5c590]: https://github.com/winterchill-trading/coinbase-feed/commit/dd5c590
[kraken-feed-27c4015]: https://github.com/winterchill-trading/kraken-feed/commit/27c4015
[deribit-feed-ecd2245]: https://github.com/winterchill-trading/deribit-feed/commit/ecd2245
[bitget-feed-3e048e3]: https://github.com/winterchill-trading/bitget-feed/commit/3e048e3
[okx-feed-13301d8]: https://github.com/winterchill-trading/okx-feed/commit/13301d8
[coinbase-feed-6221878]: https://github.com/winterchill-trading/coinbase-feed/commit/6221878
[kraken-feed-ab0003f]: https://github.com/winterchill-trading/kraken-feed/commit/ab0003f
[deribit-feed-723cb9d]: https://github.com/winterchill-trading/deribit-feed/commit/723cb9d
[bitget-feed-f1b2620]: https://github.com/winterchill-trading/bitget-feed/commit/f1b2620
[okx-feed-923fd76]: https://github.com/winterchill-trading/okx-feed/commit/923fd76
[coinbase-feed-a7a10d5]: https://github.com/winterchill-trading/coinbase-feed/commit/a7a10d5
[kraken-feed-9871b5d]: https://github.com/winterchill-trading/kraken-feed/commit/9871b5d
[deribit-feed-7615a21]: https://github.com/winterchill-trading/deribit-feed/commit/7615a21
[bitget-feed-1ef23bf]: https://github.com/winterchill-trading/bitget-feed/commit/1ef23bf
[market-recorder-5f97596]: https://github.com/winterchill-trading/market-recorder/commit/5f97596
[hl-protocol-1964453]: https://github.com/winterchill-trading/hl-protocol/commit/1964453
[binance-client-e15212b]: https://github.com/winterchill-trading/binance-client/commit/e15212b
[market-maker-26ae36e]: https://github.com/winterchill-trading/market-maker/commit/26ae36e
[market-maker-6b767a8]: https://github.com/winterchill-trading/market-maker/commit/6b767a8
[market-maker-1ae81da]: https://github.com/winterchill-trading/market-maker/commit/1ae81da

## In progress

### Copy-trading platform

In progress; design in [design/copytrading.md](design/copytrading.md), decisions in
[ADR 0007](adr/0007-agent-keys-not-custody.md) and
[ADR 0008](adr/0008-bonsai-web-frontend.md).

- `hl-protocol`: `approveAgent` and `approveBuilderFee` actions, user subscriptions for
  any address, leaderboard rows, order `builder` field.
- `hl-client`: user-signed EIP-712 actions, `Exchange.approve_agent` and
  `approve_builder_fee`, `User_feed`, `Leaderboard.fetch`, `Info.user_fills_by_time`,
  `Client.trading_with_agent`.
- `hl-sim`: agent and builder fee approvals, agent-signed orders, user subscriptions
  for any address, a `leaderboard` info request, `-leaders N` simulated leaders.
- [hl-copy-core](repos/hl-copy-core.md) (done): `Scale`, `Caps`, `Rounding`, `Mirror`,
  `Score`, `Pnl`, `Follower_config`.
- [hl-leaderboard](repos/hl-leaderboard.md): `collect`, `rank`, `serve`.
- [hl-copy-engine](repos/hl-copy-engine.md): followers, resync, journals, metrics,
  end-to-end script on `hl-sim`.
- [hl-copy-api](repos/hl-copy-api.md): wallet login, agent keys, follows.
- [hl-copy-web](repos/hl-copy-web.md): Bonsai frontend and `Api_types`.
- `infra`: compose and Helm entries for the copy-trading services; the first real
  `make up-copy` run passed on 2026-10-13 (wallet login, agent approval, follow, mirrored
  position within seconds) after three first-run fixes.
- `hl-copy-backtest` (done, in hl-copy-core): ranks a leaderboard collection by replaying
  each leader's fills through `Mirror`, reports per leader.
- `hl-sim`: `portfolio` info request (done), so the collector gets equity curves.
- Open: verify on testnet that another address's user streams are readable and what
  the 10-unique-users websocket limit counts.

## Fiat rails

- [griffin-client](repos/griffin-client.md) (done): sandbox client and `griffin` CLI, with
  the live sandbox walk passing. Open: signed requests accepted end to end, real webhook
  deliveries.
- [lightspark-client](repos/lightspark-client.md) (done): Grid sandbox reads and writes pass
  live, GraphQL covered by fixtures. Open: GraphQL side verified with a Lightning token.
- `venue-net` TLS host-name verification (in progress).

## Next

- **Native cloud sinks** when the conditions in
  [design/cloud-sinks-and-replication.md](design/cloud-sinks-and-replication.md#when-a-native-sink-is-justified)
  hold.
- **Replication** (partially done): `market-recorder merge` and
  `scripts/replicate-day.sh` merge two collectors' days into one canonical `raw/`
  (frame-text identity within a window, earliest `recv_ts`, disconnects kept only where
  both copies have a gap, a per-series report); see
  [repos/market-recorder.md](repos/market-recorder.md#replication). Sequence identity
  and gap lists, silences, the clock bound, the day boundary and collector ids are done
  (wave 6). Remaining: ordering inside the clock bound, the L2 snapshot rule, a second
  collector per exchange in a second region, cross-region replication and the daily
  merge job.
- **AWS deployment**: k3s on EC2 in ap-northeast-1 (Binance, Hyperliquid) and
  ap-southeast-1 (Bybit). See [design/deployment.md](design/deployment.md).
- **specs upkeep**: every new repository and architecture change updates these pages
  (see [CLAUDE.md](CLAUDE.md)); refresh the `oxcaml-claude-skills` ecosystem map from
  [overview.md](overview.md).

### hl-sim parity

Gaps between `hl-sim` and the real Hyperliquid API, ranked by value per effort in
[research/hl-sim-parity.md](research/hl-sim-parity.md#ranked-gaps) (S under a day, M one to
three days, L a week or more). The copy-trading items (agents, builder fees, `userFillsByTime`,
`portfolio`, `userRole`) are listed under [Copy-trading platform](#copy-trading-platform).

1. `order-book`, `exchange-core`, `hl-sim` (done): self-trade prevention as "expire maker"
   (cancel the resting order, keep matching the taker) (M). `order-book`: per-book `Stp.t`
   (`Cancel_taker` default, `Expire_maker`, `Cancel_both`) with the removed orders in
   `Result.expired_makers`; `exchange-core`: `Exchange.create ?self_trade`, a
   `Self_trade` cancel event per expired order, the policy in the journal header;
   `hl-sim`: `Expire_maker`, `selfTradeCanceled`, the invented error dropped; `hl-mm`
   treats `selfTradeCanceled` as a cancel.
2. `hl-sim`: fees at the base tier, 4.5 bp taker and 1.5 bp maker, with a tier flag (S).
3. `hl-sim`: `orderUpdates` for rejected orders and `liquidatedCanceled` for liquidation
   cancels (S).
4. `hl-protocol`, `hl-sim`: `orderStatus` by oid and cloid (S-M).
5. `hl-protocol`, `hl-sim`, `hl-client`: `scheduleCancel` dead man's switch (S).
6. `hl-protocol`, `hl-sim`: `updateLeverage` and `activeAssetData` (S).
7. `hl-sim`: optional signature and nonce checking (M).
8. `hl-protocol`, `hl-sim`: `batchModify` and modify's `always_place` flag (S).
9. `hl-sim`: 60 s websocket idle timeout and a periodic-disconnect fault option (S).
10. `hl-sim`, `order-book`: mainnet `l2Book` cadence and `nSigFigs`/`mantissa`
    aggregation (S-M).
11. `hl-protocol`, `hl-sim`: `clearinghouseState`, `openOrders`, `userEvents` and
    `userFundings` subscriptions (M).
12. `hl-sim`: rate limits behind a flag (IP weights and 429, address budget, open order
    cap, websocket limits) (M).
13. `exchange-core`, `hl-sim` (done): separate oracle and mark, premium-based funding paid
    on oracle notional (M-L). `exchange-core`: `Exchange.set_oracle` (journalled),
    `Price_index` mark median, `Premium_funding` (5 s samples, clamp, 4% cap),
    `Market_sim.Config.oracle_interval`; `hl-sim`: `-oracle-interval-ms` (3000), and
    `activeAssetCtx` reports oracle, premium and impact prices.
14. `exchange-core`, `hl-sim` (done): liquidations through the book with slices, backstop
    and the fill `liquidation` field (L). `exchange-core`: `Exchange.create
    ?book_liquidation`, `drain_liquidation_events`, `EXJRNL03` journal header; `hl-sim`:
    liquidation fills and `userEvents` `liquidation`. Remaining: fills for backstop
    takeovers.
15. `exchange-core`, `hl-sim`: trigger orders (done: `Exchange.place_trigger`, a trigger
    book on the mark, `Trigger_event` log, `triggered` updates and `orderStatus` trigger
    fields) and TP/SL grouping (`normalTpsl`, `positionTpsl`; pending) (L).
16. `hl-protocol`, `hl-sim`: `metaAndAssetCtxs` (done), `fundingHistory`,
    `predictedFundings`, `candleSnapshot`, `bbo` (M).
17. `exchange-core`, `hl-sim` (done): margin tables and tiers (M). `exchange-core`:
    `Margin_tier`, `Instrument.create ?margin_tiers`, tiered maintenance and leverage
    checks; `hl-sim`: mainnet tiers, `marginTables` in `meta`.
18. `hl-sim`, `hl-client`: websocket `post` requests (M).
19. `hl-protocol`, `hl-sim`: wire cosmetics (`"x.0"` prices, websocket error text, 422) (S).

### From research

Proposed actions from the [research notes](research/README.md), one line each, deduplicated
across themes. Each theme document orders its own list by value and links the sources.

#### State machines and logs ([theme](research/themes/state-machines-and-logs.md))

- `market-data`, clients: emit a gap event on `Live_feed` resync; document reconnect frame loss.

#### Data platform ([theme](research/themes/data-platform.md))

- `infra`: run `market-data check` after the day-close job (the command exists).
- `market-recorder`: add a `Venue_source.S` module type and register the clients as modules.
- `market-recorder`: export the `Parquet_sink` dropped count on `/metrics` if it adopts the sink.

#### OCaml and OxCaml practices ([theme](research/themes/ocaml-practices.md))

- all repos: add the `check-obj-magic.sh` job from `oxcaml-claude-skills` to CI.
- `mm-core`: use `Time_ns.Span.t` for the `_ms` fields of `Params.t`.
- `market-recorder`: log `[%here]` in errors (`check-config` errors carry the venue index).

#### Performance ([theme](research/themes/performance.md))

- `mm-core`: add GC counts to reports (the recorder exports GC stats and RSS).
- `market-maker`: count Async cycles over 50 ms; warn on cycles over 20 ms (the recorder does).
- clients, `mm-core`: audit `with_timeout` for abandoned work, as `venue-net` did.

#### Testing and simulation ([theme](research/themes/testing-and-simulation.md))

- protocol repos: check in a trimmed raw minute per venue; test decoding every frame.
- simulators: pin each row of the
  [TIF and market order table](design/simulators.md#time-in-force-and-market-orders) in a test.
- `market-data`, `hl-sim`: compare trade share and BBO inter-arrival with live data.
- `market-recorder`: add a replay load test (every `examples/` config is parsed).

#### Research tooling ([theme](research/themes/research-tooling.md))

- `mm-core`: drive `Strategy` from `Replay_feed` over a fixture event log and print the quotes.
- `market-data`, `market-maker`: prototype Bonsai_term viewers for event logs and status.

#### Build and deploy ([theme](research/themes/build-and-deploy.md))

- `market-maker`: add nightly builds against upstream `main` and a weekly `e2e-all.sh` run.
- `specs`, `infra`: refine AWS deployment with host checks and a chrony check in node bootstrap.
- `infra`: try proctopus for the local stack and note the result beside the compose stack.

#### Market making and trading systems ([theme](research/themes/market-making-and-trading-systems.md))

- `market-maker`, `market-data`: log order lifecycle events; join fills to public trades.
- `mm-core`: pick reference venues from `market-data`'s `queries/lead_lag.sql` on a full day.

### Performance (from OxCaml research)

Concrete actions from the [OxCaml performance notes](research/oxcaml-performance/README.md)
and their [hot-path audit](research/oxcaml-performance/audit.md), ordered by expected win per
effort. Each starts by adding or rerunning the repository's bench and pinning words per call.

1. `binance-client` `lib/feed_normalizer.ml` (done): `Frame_scan`, a strict `[@zero_alloc]`
   scanner with Yojson fallback and `frame_reference`; trades 2.48 us/440 words to
   0.49 us/24, bbo 420 to 21 words, checked against Yojson on every fixture and 27k
   corrupted frames.
2. `fixed-decimal` `lib/fixed_decimal.ml` (done): `of_substring_exn` (85 ns/14 words to
   18 ns/0), `blit_to_bytes` (126 ns/48 words to 15 ns/0), `[@@zero_alloc]` on all
   arithmetic and comparisons, old parser kept as `Reference` for property tests.
3. `market-recorder` `lib/recorder.ml`, `lib/metrics.ml`, `lib/raw_writer.ml` (done): counters
   and output file resolved once per stream, reused timestamp buffer, blit into the file
   buffer; `on_raw` 832 ns/186 words to 383 ns/0 words, about 600k frames/s per core.
4. `order-book` `lib/order_book.ml` (done): `best_bid_or_null`, `best_ask_or_null` and
   `mid_or_null` at 0 words; O(1) cancel (24.8 us to 0.26 us behind 1000 orders).
5. `bybit-client` `lib/live_feed.ml`, `hl-client` `lib/normalizer.ml`, `okx-feed`
   `lib/normalizer.ml`: the scanner from item 1 per venue; cache the Bybit topic string and
   one `Instrument.t` per subscription. okx-feed done: trades 431 to 25 words, l2 snapshot
   115k to 5k, index ticker sort dropped. bybit-client done: trades 806 to 54 words, bbo
   577 to 77, l2 1327 to 536, scanner wired through an `?intercept` hook. hl-client done:
   trades 603 to 41 words, full l2Book 3883 to 274, bbo-only 22. Item complete.
6. `infra` release images (done): O3 is the default tag for hl-sim, binance-sim, bybit-sim
   and market-maker (order-book fill 95 to 57 ns, mm-core quote 2x on amd64); recorder and
   replay stay on default flags (zstd and the raw reader unchanged, binance-client scanner
   4 to 9% slower). See infra/docs/images.md.
7. `mm-core` `lib/market_state.ml`, `lib/quoter.ml` (done): flat `Float_u.t` state with
   `or_null` accessors, `Strategy.tick_u`, `Risk.check_or_null`; quote 354 to 48 words,
   idle tick 45 to 0; 300-script bisimulation against the pure reference. Next:
   `Reconciler.reconcile` (3050 of a requote tick's words).
8. `market-data` `lib/merge.ml`, `lib/raw_minute.ml` (done): batched merge, int-keyed heap,
   index-split lines; raw reader 0.6 M to 2.7 M lines/s, 332 to 39 words per line.
9. `exchange-core` `engine/exchange.ml`, `engine/clearinghouse.ml` (done): step with 1000
   accounts 388 us to 70 us (77k to 20 words), place with 500 open orders 44 us to 0.95 us
   via a reserved-margin cache; bisimulation tests against the old paths.
10. `price-anchor` `lib/anchor.ml`, `lib/queue_ahead.ml` (done): `or_null` marks and mid,
    queue-ahead indexed by price with a cursor refresh skipped while no exchange event
    happened, one-walk `Eligible.size`; 34.8 to 7.0 us per event at 500 resting orders
    (42.9 to 17.4 with client churn), trade words 80 to 23.
11. `parquet` `lib/writer.ml` (done): `Writer.Direct` typed builders and `Zstd_bytes`;
    1.1 to 1.5x rows/s, 6 to 1.1 words per row, peak RSS 220 to 128 MB on 10M rows.
12. `venue-net` `src/ws_client.ml` (done): batched delivery (26 to 13 words per frame) and
    an `on_message` callback (0 words); see the README performance table.
13. clients and feeds (done): every `Live_feed` takes frames through `Ws_client ~on_message`,
    13 fewer words per frame; binance `User_ws` still reads `messages` (low rate, listen-key
    swaps). Time moves only where decoding is cheap (OKX about 10%).
14. `market-data` `lib/parquet_sink.ml` and day-close (done): `Parquet_schemas.Direct` writers,
    byte-identical output; the chunked event-log reader took day close from 1.07 M to
    2.9 M rows/s (334 to 27 words per row).

[market-recorder-fd4b1c2]: https://github.com/winterchill-trading/market-recorder/commit/fd4b1c2
[market-recorder-e01f00e]: https://github.com/winterchill-trading/market-recorder/commit/e01f00e
[market-recorder-d5b6f56]: https://github.com/winterchill-trading/market-recorder/commit/d5b6f56
[market-recorder-d6f5653]: https://github.com/winterchill-trading/market-recorder/commit/d6f5653
[market-recorder-5e2681b]: https://github.com/winterchill-trading/market-recorder/commit/5e2681b
[market-recorder-dfc1ac9]: https://github.com/winterchill-trading/market-recorder/commit/dfc1ac9
[market-recorder-b31caf8]: https://github.com/winterchill-trading/market-recorder/commit/b31caf8
[market-recorder-c7f2317]: https://github.com/winterchill-trading/market-recorder/commit/c7f2317
[market-recorder-6eb774e]: https://github.com/winterchill-trading/market-recorder/commit/6eb774e
[market-recorder-af7e618]: https://github.com/winterchill-trading/market-recorder/commit/af7e618
[market-recorder-a119187]: https://github.com/winterchill-trading/market-recorder/commit/a119187
[market-recorder-788836b]: https://github.com/winterchill-trading/market-recorder/commit/788836b
[market-recorder-d62cff1]: https://github.com/winterchill-trading/market-recorder/commit/d62cff1
[market-recorder-8312421]: https://github.com/winterchill-trading/market-recorder/commit/8312421
[market-recorder-9539251]: https://github.com/winterchill-trading/market-recorder/commit/9539251
[market-recorder-9e96f3e]: https://github.com/winterchill-trading/market-recorder/commit/9e96f3e
[market-recorder-f15e611]: https://github.com/winterchill-trading/market-recorder/commit/f15e611
[market-recorder-968c1a4]: https://github.com/winterchill-trading/market-recorder/commit/968c1a4
[market-data-64381d1]: https://github.com/winterchill-trading/market-data/commit/64381d1
[market-data-a61ead7]: https://github.com/winterchill-trading/market-data/commit/a61ead7
[market-data-3c978c7]: https://github.com/winterchill-trading/market-data/commit/3c978c7
[market-data-cc0fd95]: https://github.com/winterchill-trading/market-data/commit/cc0fd95
[market-data-1431404]: https://github.com/winterchill-trading/market-data/commit/1431404
[market-data-194c72b]: https://github.com/winterchill-trading/market-data/commit/194c72b
[market-data-5c654e9]: https://github.com/winterchill-trading/market-data/commit/5c654e9
[market-data-cda1a10]: https://github.com/winterchill-trading/market-data/commit/cda1a10
[market-data-3f4cef2]: https://github.com/winterchill-trading/market-data/commit/3f4cef2
