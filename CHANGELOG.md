# Changelog

One line per architecture change across the organization: a new repository, a new
dependency edge between org packages, a public library or binary, an on-disk format, a
wire protocol, a deployment shape, or an ADR. Newest day first; within a day, in the
order the changes landed. Each line names the repositories and links the spec page that
describes the change. The line is added in the same piece of work that updates the spec
pages (see [CLAUDE.md](CLAUDE.md)). Bug fixes, tests and documentation-only changes do not
belong here.

## 2026-10-16

- `leader-scoring`: new repository with two packages, `leader-scoring` (venue-neutral track
  records, metrics, composite and learned scores, copy capacity, alerts; new edge to
  `market-data`) and `leader-scoring-hl` (read-only Hyperliquid source and the
  `leader-scoring` binary; edges to `hl-protocol` and `hl-client`). `hl-leaderboard` now
  depends on both, logs funding, books and open interest, and writes
  `reports/<address>.json`; `hl-copy-api` and `hl-copy-web` (`Api_types.Scoring`) carry
  the reports to the leader page. See [leader-scoring](repos/leader-scoring.md),
  [hl-leaderboard](repos/hl-leaderboard.md) and
  [design/copytrading.md](design/copytrading.md).

## 2026-10-14

- `org-access`, `payouts-core`, `accounting-sync`, `treasury-rules`, `billing-core`: new
  repositories for business banking libraries: organisations and maker-checker, payout
  batches, accounting exports, treasury policy rules and billing. New dependency edges:
  `org-access` to `money`; `payouts-core` to `money`, `ledger` and `payments-core`;
  `accounting-sync` to `money` and `ledger`; `treasury-rules` to `money` and `risk-rules`;
  `billing-core` to `money` and `ledger`. `billing-core` is in progress. See the pages
  [org-access](repos/org-access.md), [payouts-core](repos/payouts-core.md),
  [accounting-sync](repos/accounting-sync.md), [treasury-rules](repos/treasury-rules.md)
  and [billing-core](repos/billing-core.md).
- `griffin-provider`, `lightspark-provider`: new repositories, the GBP and USD adapters of
  `banking-provider` over `griffin-client` and `lightspark-client`, sandbox by default. New
  dependency edges: to `banking-provider` and to their client. See
  [design/neobank.md](design/neobank.md) and the pages
  [griffin-provider](repos/griffin-provider.md) and
  [lightspark-provider](repos/lightspark-provider.md).
- `opam-repository`: new repository, the organization's opam repository and the only
  place packages are published. `0.1.0` entries for `pg-async`, `fixed-decimal`, `money`,
  `money-cli`, `ledger`, `venue-net` and `parquet`, each a git URL pinned to the audited
  commit; `order-book` waits for `exchange-core`. See
  [repos/opam-repository.md](repos/opam-repository.md) and
  [design/opam-publishing.md](design/opam-publishing.md).
- `money`, `ledger`, `risk-rules`, `striga-client`: new repositories for the neobank demo's
  banking foundations and provider SDK. New dependency edges: `money` to `fixed-decimal`,
  `ledger` to `money`, `risk-rules` to `money` and `payments-core`. See
  [design/neobank.md](design/neobank.md) and the pages
  [money](repos/money.md), [ledger](repos/ledger.md), [risk-rules](repos/risk-rules.md)
  and [striga-client](repos/striga-client.md).
- `kyc-core`, `payments-core`, `card-core`: new repositories for the neobank demo's
  customer, transfer and card state machines. New dependency edges: `payments-core` to
  `money` and `ledger`, `card-core` to `money`, `ledger` and `payments-core`; `kyc-core`
  has none. See [design/neobank.md](design/neobank.md) and the pages
  [kyc-core](repos/kyc-core.md), [payments-core](repos/payments-core.md) and
  [card-core](repos/card-core.md).
- `banking-provider`, `risk-models`, `pg-async`: new repositories for the neobank demo's
  provider boundary, the machine-learned risk scores and the PostgreSQL client. New
  dependency edges: `banking-provider` to `money`, `ledger`, `kyc-core`, `payments-core` and
  `card-core`; `risk-models` to `risk-rules`; `pg-async` has none. See
  [design/neobank.md](design/neobank.md) and the pages
  [banking-provider](repos/banking-provider.md), [risk-models](repos/risk-models.md) and
  [pg-async](repos/pg-async.md).
- ADR 0009: PostgreSQL for application state through `pg-async`, behind a per-service store
  interface with an in-memory and a PostgreSQL implementation (`neobank-api`, `hl-copy-api`).
  See [adr/0009-postgres-replaceable-store.md](adr/0009-postgres-replaceable-store.md) and
  [repos/pg-async.md](repos/pg-async.md).
- `neobank-api`, `neobank-web`: new repositories for the neobank demo's HTTP API and browser
  app. New dependency edges: `neobank-api` to `banking-provider`, `risk-rules` and `pg-async`;
  `neobank-web` to `neobank-api-types`, a package of the `neobank-api` repository. See
  [design/neobank.md](design/neobank.md) and the pages [neobank-api](repos/neobank-api.md)
  and [neobank-web](repos/neobank-web.md).
- `hl-copy-api`: state moves from sexp files to PostgreSQL through `pg-async` (an on-disk
  format change for follows and agent keys; the engine's files are unchanged). New dependency
  edge `hl-copy-api` to `pg-async`. See [repos/hl-copy-api.md](repos/hl-copy-api.md) and
  [ADR 0009](adr/0009-postgres-replaceable-store.md).
- `striga-provider`: new repository, the Striga adapter of `banking-provider`'s `Provider`
  and `Sandbox`, sandbox-limited (the sandbox never provisioned EUR accounts for the test
  persons). New dependency edges: `striga-provider` to `banking-provider` and
  `striga-client`; `neobank-api` to `striga-provider` (its Striga mode is on `main`). See
  [repos/striga-provider.md](repos/striga-provider.md) and
  [design/neobank.md](design/neobank.md).
- Opam readiness audits for `fixed-decimal`, `money`, `ledger`, `order-book`, `parquet`,
  `venue-net` and `pg-async`. `pg-async` builds and passes on plain OCaml 5.2 with Jane
  Street v0.17 and leads tier 1 of the publishing plan; nothing is published. See
  [research/opam-readiness](research/opam-readiness/README.md) and
  [design/opam-publishing.md](design/opam-publishing.md).
- Audit gap fixes that change a public interface or an on-disk format: `money` (rational
  basis points, `Amount.allocate` and `split`, a frozen currency registry), `ledger` (a
  `Refusals_forgotten` journal record for `?refusal_retention`, the `ledger-head-v1` chain
  head), `pg-async` (prepared-statement cache, `Pool` lifetime, `Listen` reconnection; one
  source-incompatible change). See the audit pages under
  [research/opam-readiness](research/opam-readiness/README.md#audits).
- `kyc-core`: business verification (KYB) for legal entities; new persisted format
  `Kyb_event.Stable.V1` (with `Kyb_audit.Entry.Stable.V1`) and `kyc-case kyb` subcommands.
  See [repos/kyc-core.md](repos/kyc-core.md).

- `service-kit`, `otp-mail`, `webauthn`, `auth-kit`, `fx-core`, `investing-core`,
  `scheduler-core`, `requests-core`, `pots-and-insights`, `rewards-core`, `statements`: new
  repositories, the consumer banking libraries (HTTP service blocks, one-time codes and
  email, passkeys, passcodes, FX pricing, investing, recurring schedules, money requests,
  savings pots and insights, loyalty points, account statements). See
  [overview.md](overview.md#repositories-by-layer) and the pages under
  [repos/](repos/service-kit.md).
- Consumer banking library edges: `fx-core` and `requests-core` to `money`, `ledger` and
  `payments-core`; `investing-core` to `fixed-decimal`, `money` and `ledger`;
  `pots-and-insights` to `money`, `ledger` and `scheduler-core`; `rewards-core` and
  `statements` to `money` and `ledger`. The other five have no org package dependency.
  See [overview.md](overview.md#dependency-graph).
- `chain-books`: new repository, double-entry books for an organisation's on-chain treasury:
  venue records booked as ledger entries, positions with cost basis, valuation and
  reconciliation against chain balances, with a Hyperliquid sub-library. New dependency
  edges: `chain-books` to `money`, `ledger` and `hl-protocol`. See
  [repos/chain-books.md](repos/chain-books.md).

## 2026-10-13

- `exchange-core`, `hl-sim`: trigger orders (`Exchange.place_trigger`, `Trigger_event`),
  oracle prices with Hyperliquid's mark and premium funding (`Exchange.set_oracle`,
  `Price_index`, `Premium_funding`, `Market_sim.Config.oracle_interval`), liquidation
  through the book (`Exchange.create ?book_liquidation`, `Book_liquidation`, journal
  header `EXJRNL03`) and margin tiers (`Margin_tier`, `Instrument.create
  ?margin_tiers`); new journal inputs `Place_trigger`, `Modify_trigger`, `Set_oracle`.
  `hl-sim` maps them (`-oracle-interval-ms`, `meta` margin tables, `metaAndAssetCtxs`,
  `userRole`). See [repos/exchange-core.md](repos/exchange-core.md),
  [design/simulators.md](design/simulators.md) and
  [research/hl-sim-parity.md](research/hl-sim-parity.md).
- `hl-copy-core`: second package `hl-copy-backtest` (library and binary) replaying an
  `hl-leaderboard` collection through `Mirror` with slipped IOC fills and taker fees;
  `backtest.json`, `results.parquet`, `curves.parquet`, and `-leaders N` ranks leaders
  by follower pnl. New edges `hl-copy-backtest` to `hl-leaderboard` and `parquet`; CI
  builds the two packages in separate jobs. See [repos/hl-copy-core.md](repos/hl-copy-core.md)
  and [design/copytrading.md](design/copytrading.md#backtest).
- `exchange-core`, `hl-sim`: self-trade policy per exchange (`Exchange.create
  ?self_trade`, an `Order_book.Stp.t`) with a `Self_trade` cancel event per expired own
  order; engine journals with a non-default policy start with `EXJRNL02` and a
  `Journal.Header.t`. `hl-sim` runs `Expire_maker`, Hyperliquid's rule. See
  [repos/exchange-core.md](repos/exchange-core.md) and
  [design/simulators.md](design/simulators.md).
- `hl-protocol`, `hl-client`, `hl-copy-engine`: `Max_builder_fee` and `User_fill.Detailed`
  (`builderFee`, `liquidation`) in hl-protocol, `Info.max_builder_fee` and
  `Info.user_fills_detailed` in hl-client, and `run -builder -builder-fee-tenths-bp` in the
  engine, sending the builder field only for followers that approved the fee. See
  [design/copytrading.md](design/copytrading.md).
- `hl-copy-api`: `scripts/e2e-stack.sh` and the `e2e-stack` CI job run the platform end
  to end on `hl-sim` with `hl-leaderboard`, `hl-copy-engine` and hl-copy-web's live smoke
  test; `/ws` frames are `Api_types.Ws_push` from `hl-copy-api-types`; `tools/dev_wallet`
  signs like a browser wallet for scripts. See
  [design/copytrading.md](design/copytrading.md).
- `hl-copy-web`: Bonsai app with every page on mock data, and the `hl-copy-api-types`
  package (`Api_types`) defining the `hl-copy-api` endpoints and bodies; no org package
  dependency. See [repos/hl-copy-web.md](repos/hl-copy-web.md).
- `hl-copy-engine`: the engine library and binary (`run`, `approve-agent`, `replay`):
  per-follow Bin_prot journal (`<journal>/<follower>-<leader>/<date>.journal`), shared
  leader subscriptions with `clearinghouseState` polling past ten leaders, agent keys from
  `Hl_copy_core.Key_store` under `-state-dir`, `/metrics` and `/status`; depends on
  `hl-copy-core`, `hl-client`, `market-data`, tests on `hl-sim`. See
  [repos/hl-copy-engine.md](repos/hl-copy-engine.md).
- `hl-leaderboard`: `collect`, `rank` and `serve` (raw `<recv_ts> <body>` logs,
  `leaders.parquet`, `fills.parquet`, `/leaders` JSON), scored with `hl-copy-core`'s
  `Score` on the `portfolio` month curve; depends on `parquet` directly. See
  [repos/hl-leaderboard.md](repos/hl-leaderboard.md).
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
  `/ws`, CORS, rate limits, `/metrics`); depends on `hl-copy-api-types` from
  `hl-copy-web`. `hl-copy-core`: new `Key_store`, the sealed agent key file format the
  API writes and the engine reads (adds `cryptokit`).
  See [repos/hl-copy-api.md](repos/hl-copy-api.md) and
  [design/copytrading.md](design/copytrading.md).
- `griffin-client` (new): Async client and CLI (`griffin`) for a UK banking API, with
  typed resources, hypermedia navigation, RFC 9421 request signing, webhook verification
  and a host-name-checked TLS config; no org package dependency. See
  [repos/griffin-client.md](repos/griffin-client.md).
- `lightspark-client` (new): Async client and CLI (`lightspark`) for a Lightning and UMA
  GraphQL API and a Grid banking API, with typed resources, webhook verification for both,
  and a host-name-checked TLS config; no org package dependency. See
  [repos/lightspark-client.md](repos/lightspark-client.md).
- `money`, `ledger`, `kyc-core`, `payments-core`, `card-core`, `risk-rules`,
  `banking-provider`, `striga-client`, `striga-provider`, `neobank-api`, `neobank-web`,
  `infra`: neobank demo design, repository plan and dependency graph (planned). See
  [design/neobank.md](design/neobank.md).

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
