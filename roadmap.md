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

## In progress

- `specs`: this repository.
- Wave 4 from research:
  - `mm-core`: a hot parameter update hook in `Strategy` and `Live`, with
    `connect_and_run` returning the loop handle, so a `market-maker` reload no longer
    restarts the loop and cancels quotes; `max_actions_per_sec` as a rolling window with
    a grace period after a resync, so a requote burst after a venue restart does not halt
    for good.
  - `market-recorder`: per-stream parse errors and reconnects on `/metrics` from the
    clients' and feeds' new `stats`.
  - CI cache rollout: every repository's workflow moves to `infra`'s `ox-setup` action
    (see [design/deployment.md](design/deployment.md#ci)).

## Next

- **price-anchor**: anchor simulator markets to real venues: mark price via `set_mark`,
  shadow top-N levels, trade-replay fills; TradFi simulators anchor noise to a reference.
  See [design/price-anchor.md](design/price-anchor.md).
- **Replay server**: a `tardis-machine` style server that replays recorded raw minute
  files over HTTP and websocket in each venue's native format, so clients and the market
  maker can run against history.
- **Raw-to-norm tool**: `Market_data.Rebuild_norm` and the feeds' `Normalizer.S`
  adapters exist; one binary linking every venue's normalizer (the three trading clients
  have no adapter yet) completes [ADR 0002](adr/0002-raw-first-storage.md).
- **Native cloud sinks** when the conditions in
  [design/cloud-sinks-and-replication.md](design/cloud-sinks-and-replication.md#when-a-native-sink-is-justified)
  hold.
- **Replication**: two collectors per exchange in two regions, cross-region
  replication, merge by earliest `recv_ts` with gap fill.
- **AWS deployment**: k3s on EC2 in ap-northeast-1 (Binance, Hyperliquid) and
  ap-southeast-1 (Bybit). See [design/deployment.md](design/deployment.md).
- **Hyperliquid trading**: `hl-client` signs and `hl-mm` trades on testnet; the
  `market-maker` binary still uses the unsigned `Hl_venue`, and no order has been placed
  on testnet with a funded account.
- **specs upkeep**: every new repository and architecture change updates these pages
  (see [CLAUDE.md](CLAUDE.md)); refresh the `oxcaml-claude-skills` ecosystem map from
  [overview.md](overview.md).

### From research

Proposed actions from the [research notes](research/README.md), one line each, deduplicated
across themes. Each theme document orders its own list by value and links the sources.

#### State machines and logs ([theme](research/themes/state-machines-and-logs.md))

- `market-data`, clients: emit a gap event on `Live_feed` resync; document reconnect frame loss.
- `market-recorder`: count per-stream parse errors on `/metrics` (clients count them; wave 4).
- `market-recorder`: test subscribe frame counts at connect and reconnect for three symbols.

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
- `market-recorder`: tag `check-config` errors with the venue index; log `[%here]` in errors.

#### Performance ([theme](research/themes/performance.md))

- `mm-core`: add GC counts to reports (the recorder exports GC stats and RSS).
- `market-recorder`, `infra`: wire memtrace (confirmed on the ox base image) into recorder and Helm.
- `market-recorder`, `market-maker`: count Async cycles over 50 ms; warn on cycles over 20 ms.
- clients, `mm-core`: audit `with_timeout` for abandoned work, as `venue-net` did.

#### Testing and simulation ([theme](research/themes/testing-and-simulation.md))

- protocol repos: check in a trimmed raw minute per venue; test decoding every frame.
- `market-recorder`: run `e2e-sims.sh` (which now fails on problems) in CI.
- simulators: pin each row of the
  [TIF and market order table](design/simulators.md#time-in-force-and-market-orders) in a test.
- `market-data`, `hl-sim`: compare trade share and BBO inter-arrival with live data.
- `market-data`: add a day-close diff script across revisions and a day-close cram test.
- `market-recorder`: add a replay load test (every `examples/` config is parsed).

#### Research tooling ([theme](research/themes/research-tooling.md))

- `mm-core`: drive `Strategy` from `Replay_feed` over a fixture event log and print the quotes.
- `market-data`: test candles against DuckDB row for row on the event log fixture.
- `market-data`: run a pyarrow type test of `examples/query.py` in CI.
- `market-data`, `market-maker`: prototype Bonsai_term viewers for event logs and status.

#### Build and deploy ([theme](research/themes/build-and-deploy.md))

- `market-maker`: add nightly builds against upstream `main` and a weekly `e2e-all.sh` run.
- all repos: move CI to the cached `ox-setup` action (wave 4; replaces `dune-cache`).
- `market-recorder`: log `RLIMIT_NOFILE` limits at startup (the FD count is exported).
- `specs`, `infra`: refine AWS deployment with host checks and a chrony check in node bootstrap.
- `infra`: try proctopus for the local stack and note the result beside the compose stack.

#### Market making and trading systems ([theme](research/themes/market-making-and-trading-systems.md))

- `market-maker`, `market-data`: log order lifecycle events; join fills to public trades.
- `market-data`, `mm-core`: add a lead-lag query; record median lag per venue pair.
