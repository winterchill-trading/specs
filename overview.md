# Overview

The organization builds a crypto perpetuals trading stack in OxCaml on the Jane Street
libraries (Core, Async, ppx_jane): exchange simulators for Hyperliquid, Binance USD-M
Futures and Bybit v5 linear, typed clients for the same three venues, one venue-neutral
market-making strategy that runs on all of them, read-only market data feeds for five
more venues (OKX, Coinbase, Kraken, Deribit, Bitget), and a raw-first market data
platform that records live feeds and turns them into Parquet for SQL. A TradFi layer adds
simulators of NYSE, Cboe and CME that speak those venues' binary protocols over TCP, on
the same engine plus shared US equities and futures semantics. Every repository is an opam
package (or two), built with dune 3.17, tested with ppx_expect and Base_quickcheck, and
pinned from GitHub in CI. Locally all repositories sit side by side under one directory
with an untracked `dune-workspace`, so dune resolves siblings by public name.

## Repositories by layer

| Layer | Repository | Role | Status |
| --- | --- | --- | --- |
| Primitives | [fixed-decimal](repos/fixed-decimal.md) | 10^-8 fixed-point decimals, distinct types per use | done |
| Primitives | [exchange-core](repos/exchange-core.md) | Venue-neutral types (package `exchange-core`) and the exchange engine (package `exchange-core-engine`) | done |
| Protocols | [hl-protocol](repos/hl-protocol.md) | Hyperliquid wire types and JSON codecs | done |
| Protocols | [binance-protocol](repos/binance-protocol.md) | Binance USD-M wire types, codecs, HMAC signing | done |
| Protocols | [bybit-protocol](repos/bybit-protocol.md) | Bybit v5 linear wire types, codecs, signing | done |
| Engine and simulators | [order-book](repos/order-book.md) | Price-time priority book and matching | done |
| Engine and simulators | `exchange-core-engine` | Matching, clearinghouse, margin, funding, liquidation, noise traders (in [exchange-core](repos/exchange-core.md)) | done |
| Engine and simulators | [hl-sim](repos/hl-sim.md), [binance-sim](repos/binance-sim.md), [bybit-sim](repos/bybit-sim.md) | HTTP and websocket servers speaking each venue's API over the engine | done |
| Engine and simulators | [price-anchor](repos/price-anchor.md) | Anchors a simulated market to a live or recorded reference: mark, shadow levels, trade-replay fills | library done, simulator flags planned |
| Engine and simulators | [sim-scorecard](repos/sim-scorecard.md) | Scores a simulator run against recorded data: stylised facts, distances and pass bands | done |
| TradFi | [equities-core](repos/equities-core.md) | US equities, options and futures semantics: sessions, ticks, lots, symbology, auctions, order types, halts, fees | done |
| TradFi | [nyse-sim](repos/nyse-sim.md), [cboe-sim](repos/cboe-sim.md), [cme-sim](repos/cme-sim.md) | NYSE Pillar and XDP, Cboe BOE and PITCH, CME iLink 3 and MDP 3.0 over the engine, binary over TCP | done |
| Clients | [venue-net](repos/venue-net.md) | Async HTTP and reconnecting websocket transport | done |
| Clients | [hl-client](repos/hl-client.md), [binance-client](repos/binance-client.md), [bybit-client](repos/bybit-client.md) | Typed venue clients, local books, `Live_feed` market data; Binance and Bybit also carry the `Mm_core.Venue.S` adapter | done |
| Feeds | [okx-feed](repos/okx-feed.md), [coinbase-feed](repos/coinbase-feed.md), [kraken-feed](repos/kraken-feed.md), [deribit-feed](repos/deribit-feed.md), [bitget-feed](repos/bitget-feed.md) | Read-only public market data as a `Market_data.Feed.t`, no trading | done |
| Market making | [mm-core](repos/mm-core.md) | Pure quoter, reconciler, risk, `Venue.S`, `Live.Make` loop | done |
| Market making | [hl-mm](repos/hl-mm.md) | Hyperliquid `Venue.S` adapter and `hl-mm` binary | done |
| Market making | [market-maker](repos/market-maker.md) | One `market-maker` binary for all three venues | done |
| Copy trading | [hl-copy-core](repos/hl-copy-core.md) | Pure mirroring, scaling, caps and leader scoring; `hl-copy-backtest` replays recorded leaders | done |
| Copy trading | [hl-leaderboard](repos/hl-leaderboard.md) | Leader collection, scoring and `/leaders` JSON | done |
| Copy trading | [leader-scoring](repos/leader-scoring.md) | Track records, metrics, composite and learned scores, copy capacity and alerts; read-only Hyperliquid source | done |
| Copy trading | [hl-copy-engine](repos/hl-copy-engine.md) | Mirrors leaders into follower accounts with agent keys, executing with the follow's algorithm | done |
| Copy trading | [execution-algos](repos/execution-algos.md) | Child-order schedulers (TWAP, VWAP, POV, passive, adaptive copy), impact estimates, cost reports, paper venue | done |
| Copy trading | [copy-backtest](repos/copy-backtest.md) | Recorded markets and leader fills through the mirror and the algorithms; Parquet results checked with DuckDB | done |
| Copy trading | [hl-copy-api](repos/hl-copy-api.md), [hl-copy-web](repos/hl-copy-web.md) | Wallet login, agent approval and follows; Bonsai frontend | in progress |
| Data platform | [parquet](repos/parquet.md) | Pure OCaml Parquet writer | done |
| Data platform | [market-data](repos/market-data.md) | Normalized types, event logs, Parquet sink, day close, DuckDB views, replay | done |
| Data platform | [market-recorder](repos/market-recorder.md) | Live recorder: raw minute files, event logs, uploader, metrics | done |
| Data platform | [market-replay](repos/market-replay.md) | Replay server: raw lines over HTTP, venue-native websockets for the eight crypto venues | done |
| Data platform | [backtest-stats](repos/backtest-stats.md) | Backtest statistics: adjusted, probabilistic and deflated Sharpe ratios, reality check and SPA, probability of backtest overfitting, VaR backtests, acceptance gate from a sexp policy | done |
| Fiat rails | [griffin-client](repos/griffin-client.md) | Async client and CLI for a UK banking API: legal persons, accounts, payments, payees, Confirmation of Payee, webhooks; sandbox by default | done |
| Fiat rails | [lightspark-client](repos/lightspark-client.md) | Async client and CLI for a Lightning and UMA GraphQL API and a Grid banking API: nodes, invoices, customers, transfers, quotes; sandbox writes only, webhook verification | done |
| Fiat rails | [striga-client](repos/striga-client.md) | Async client and CLI for the Striga v1 API: consumers and KYC, wallets, payments, cards, standing orders, webhooks; sandbox by default | done |
| Fiat rails | [striga-provider](repos/striga-provider.md) | `banking-provider`'s `Provider` and `Sandbox` over `striga-client`, with the endpoint and webhook mapping; sandbox by default | done, sandbox-limited |
| Fiat rails | [griffin-provider](repos/griffin-provider.md) | `banking-provider`'s `Provider` and `Sandbox` over `griffin-client` for GBP: UK legal persons, sort-code accounts, Faster Payments, book transfers, Confirmation of Payee; sandbox by default | done, sandbox-limited |
| Fiat rails | [lightspark-provider](repos/lightspark-provider.md) | `banking-provider`'s `Provider` and `Sandbox` over `lightspark-client` for USD: Grid customers, USD and stablecoin accounts, cross-border payouts, FX quotes, swaps; sandbox by default | done, sandbox-limited |
| Banking libraries | [money](repos/money.md) | Currencies, exact minor-unit amounts, FX rates, fees; the base of the banking libraries | done |
| Banking libraries | [ledger](repos/ledger.md) | Double-entry ledger over an append-only Bin_prot journal: holds, idempotency, trial balance, statements | done |
| Banking libraries | [risk-rules](repos/risk-rules.md) | Rule engine for transfers and card authorisations: reason codes, typologies, SCA exemptions, shadow mode, review queue | done |
| Banking libraries | [risk-models](repos/risk-models.md) | Machine-learned scores behind `risk-rules`' `Model.S`; trained offline, scored in OCaml | done |
| Banking libraries | [transaction-monitoring](repos/transaction-monitoring.md) | Real-time AML monitoring: rolling customer and counterparty profiles, eleven typology rules, a GBDT score, Allow/Hold/Block decisions, alerts with a case lifecycle; memory and PostgreSQL stores | done |
| Banking libraries | [kyc-core](repos/kyc-core.md) | Customer due diligence: verification tiers, risk rating, screening, monitoring, retention, audit trail; standalone | done |
| Banking libraries | [sanctions-screening](repos/sanctions-screening.md) | Name screening against OFAC, EU and UK sanctions lists: parsers, normalisation across scripts, explainable fuzzy matching, index, rescreening, cases; PostgreSQL store package | done |
| Banking libraries | [payments-core](repos/payments-core.md) | Payment rails and transfer state machines (SEPA, on-chain, Lightning, intraledger), SCA, standing orders, swaps, reconciliation | done |
| Banking libraries | [card-core](repos/card-core.md) | Card lifecycle, authorization decision, clearing and settlement, disputes, statements | done |
| Banking libraries | [banking-provider](repos/banking-provider.md) | `Provider` interface over the domain libraries and a deterministic fake provider for the neobank demo | done |
| Business banking libraries | [org-access](repos/org-access.md) | Organisations, members and roles, invitations, maker-checker approvals and a hash-chained access audit | done |
| Business banking libraries | [payouts-core](repos/payouts-core.md) | Batches of payouts to many payees: one approval per batch, line state machine, ledger funding holds, receipts, reconciliation | done |
| Business banking libraries | [accounting-sync](repos/accounting-sync.md) | Export of ledger journals to accounting systems: mappings, idempotent entries, period locks, reconciliation | done, no adapter for a real system yet |
| Business banking libraries | [treasury-rules](repos/treasury-rules.md) | Treasury policy rules (sweep, top-up, convert, rebalance, yield, hedge) with caps, guards and exactly-once runs | done |
| Business banking libraries | [billing-core](repos/billing-core.md) | Recurring and usage billing: price lists, subscriptions, invoices, dunning, credit notes, ledger bookings | in progress |
| Business banking libraries | [chain-books](repos/chain-books.md) | Double-entry books for an on-chain treasury: activities booked as ledger entries, positions and cost basis, valuation, reconciliation against chain balances, Hyperliquid adapter | done, not on opam yet |
| Consumer banking libraries | [service-kit](repos/service-kit.md) | Async HTTP building blocks: typed routes, RFC 9457 problems, idempotency keys, step-up grants, rate limits, health and metrics; no database | done |
| Consumer banking libraries | [otp-mail](repos/otp-mail.md) | One-time codes hashed at rest, transactional email with MIME and DKIM signing, SMTP client | done |
| Consumer banking libraries | [webauthn](repos/webauthn.md) | WebAuthn and passkey relying-party verification in pure OCaml, with CBOR and COSE decoding; requires OxCaml | done |
| Consumer banking libraries | [auth-kit](repos/auth-kit.md) | Passcode rules, Argon2id hashing, progressive lockout, devices and a security log | done |
| Consumer banking libraries | [fx-core](repos/fx-core.md) | Reference rates, customer FX pricing with rounding rules, single-use quotes, booking through payments-core | done |
| Consumer banking libraries | [investing-core](repos/investing-core.md) | Instruments, end-of-day prices, fractional market orders, positions and their ledger bookings | done |
| Consumer banking libraries | [scheduler-core](repos/scheduler-core.md) | Recurring schedules and exactly-once runs per schedule and date, for any job | done |
| Consumer banking libraries | [requests-core](repos/requests-core.md) | Money requests, payment links and bill splits between customers of one institution | done |
| Consumer banking libraries | [pots-and-insights](repos/pots-and-insights.md) | Savings pots as owned sub-accounts, spending insights and monthly budgets | done |
| Consumer banking libraries | [rewards-core](repos/rewards-core.md) | Loyalty points ledger, earn rules, tiers, cashback redemption and expiry | done |
| Consumer banking libraries | [statements](repos/statements.md) | Customer account statements as CSV and PDF over the ledger journal | done |
| Infrastructure libraries | [pg-async](repos/pg-async.md) | Non-blocking PostgreSQL client for Async over libpq: pool, queries, transactions, migrations; application state store | done |
| Neobank demo | [neobank-api](repos/neobank-api.md) | HTTP API of the neobank demo over `banking-provider`, `risk-rules` and PostgreSQL through `pg-async`; fake provider | done |
| Neobank demo | [neobank-web](repos/neobank-web.md) | Bonsai browser app of the neobank demo, with a built-in mock bank | done |
| Tooling | [infra](repos/infra.md) | Container images, compose stack, Helm chart, deployment notes | done |
| Tooling | [opam-repository](repos/opam-repository.md) | Our opam repository: `0.1.0` entries pinned to audited commits, installed from a fresh OxCaml switch in CI (see [design/opam-publishing.md](design/opam-publishing.md)) | in progress |
| Tooling | [oxcaml-claude-skills](repos/oxcaml-claude-skills.md) | Agent skills and the gotchas log | done |
| Tooling | specs | This repository | in progress |

## Dependency graph

Edges point from a package to the org packages it depends on, taken from each
`dune-project`. Edges implied by a longer path are left out for legibility (for example
`hl-sim` also lists `order-book` and `exchange-core` directly); each `repos/` page lists
the full set. Dotted edges are test-only dependencies (`:with-test`) or, for `infra`,
images it builds.

```mermaid
graph LR
  subgraph primitives["Primitives"]
    fixed_decimal["fixed-decimal"]
    exchange_core["exchange-core"]
  end
  subgraph protocols["Protocols"]
    hl_protocol["hl-protocol"]
    binance_protocol["binance-protocol"]
    bybit_protocol["bybit-protocol"]
  end
  subgraph engine["Engine and simulators"]
    order_book["order-book"]
    engine_pkg["exchange-core-engine"]
    hl_sim["hl-sim"]
    binance_sim["binance-sim"]
    bybit_sim["bybit-sim"]
    price_anchor["price-anchor"]
    sim_scorecard["sim-scorecard"]
  end
  subgraph tradfi["TradFi"]
    equities_core["equities-core"]
    nyse_sim["nyse-sim"]
    cboe_sim["cboe-sim"]
    cme_sim["cme-sim"]
  end
  subgraph clients["Clients"]
    venue_net["venue-net"]
    hl_client["hl-client"]
    binance_client["binance-client"]
    bybit_client["bybit-client"]
  end
  subgraph feeds["Feeds"]
    okx_feed["okx-feed"]
    coinbase_feed["coinbase-feed"]
    kraken_feed["kraken-feed"]
    deribit_feed["deribit-feed"]
    bitget_feed["bitget-feed"]
  end
  subgraph mm["Market making"]
    mm_core["mm-core"]
    hl_mm["hl-mm"]
    market_maker["market-maker"]
  end
  subgraph copy["Copy trading"]
    copy_core["hl-copy-core"]
    copy_backtest["hl-copy-backtest"]
    leaderboard["hl-leaderboard"]
    leader_scoring["leader-scoring"]
    copy_engine["hl-copy-engine"]
    exec_algos["execution-algos"]
    copy_bt["copy-backtest"]
    copy_api["hl-copy-api"]
    copy_web["hl-copy-web"]
  end
  subgraph data["Data platform"]
    parquet["parquet"]
    market_data["market-data"]
    market_recorder["market-recorder"]
    market_replay["market-replay"]
    backtest_stats["backtest-stats"]
  end
  subgraph fiat["Fiat rails"]
    griffin_client["griffin-client"]
    lightspark_client["lightspark-client"]
    striga_client["striga-client"]
    striga_provider["striga-provider"]
    griffin_provider["griffin-provider"]
    lightspark_provider["lightspark-provider"]
  end
  subgraph banking["Banking libraries"]
    money["money"]
    ledger["ledger"]
    kyc_core["kyc-core"]
    sanctions_screening["sanctions-screening"]
    payments_core["payments-core"]
    card_core["card-core"]
    risk_rules["risk-rules"]
    risk_models["risk-models"]
    transaction_monitoring["transaction-monitoring"]
    banking_provider["banking-provider"]
  end
  subgraph consumer["Consumer banking libraries"]
    service_kit["service-kit"]
    otp_mail["otp-mail"]
    webauthn["webauthn"]
    auth_kit["auth-kit"]
    fx_core["fx-core"]
    investing_core["investing-core"]
    scheduler_core["scheduler-core"]
    requests_core["requests-core"]
    pots_and_insights["pots-and-insights"]
    rewards_core["rewards-core"]
    statements["statements"]
  end
  subgraph business["Business banking libraries"]
    org_access["org-access"]
    payouts_core["payouts-core"]
    accounting_sync["accounting-sync"]
    treasury_rules["treasury-rules"]
    billing_core["billing-core"]
    chain_books["chain-books"]
  end
  subgraph infra_libs["Infrastructure libraries"]
    pg_async["pg-async"]
  end
  subgraph neobank["Neobank demo"]
    neobank_api["neobank-api"]
    neobank_api_types["neobank-api-types"]
    neobank_web["neobank-web"]
  end
  subgraph tooling["Tooling"]
    infra["infra"]
    skills["oxcaml-claude-skills"]
    specs["specs"]
  end

  exchange_core --> fixed_decimal
  order_book --> exchange_core
  engine_pkg --> order_book
  hl_protocol --> exchange_core
  binance_protocol --> exchange_core
  bybit_protocol --> exchange_core
  hl_sim --> engine_pkg
  hl_sim --> hl_protocol
  binance_sim --> engine_pkg
  binance_sim --> binance_protocol
  bybit_sim --> engine_pkg
  bybit_sim --> bybit_protocol
  bybit_sim --> price_anchor
  bybit_sim --> bybit_client
  bybit_sim --> binance_client
  price_anchor --> engine_pkg
  price_anchor --> market_data
  sim_scorecard --> engine_pkg
  sim_scorecard --> market_data
  market_data --> exchange_core
  market_data --> parquet
  backtest_stats --> parquet
  mm_core --> exchange_core
  hl_client --> hl_protocol
  hl_client --> venue_net
  hl_client --> market_data
  binance_client --> binance_protocol
  binance_client --> venue_net
  binance_client --> market_data
  binance_client --> mm_core
  bybit_client --> bybit_protocol
  bybit_client --> venue_net
  bybit_client --> market_data
  bybit_client --> mm_core
  hl_mm --> hl_client
  hl_mm --> mm_core
  market_maker --> hl_mm
  market_maker --> binance_client
  market_maker --> bybit_client
  market_recorder --> hl_client
  market_recorder --> binance_client
  market_recorder --> bybit_client
  equities_core --> exchange_core
  nyse_sim --> engine_pkg
  nyse_sim --> equities_core
  cboe_sim --> engine_pkg
  cboe_sim --> equities_core
  cboe_sim --> price_anchor
  cboe_sim --> market_data
  cme_sim --> engine_pkg
  cme_sim --> equities_core
  okx_feed --> market_data
  okx_feed --> venue_net
  coinbase_feed --> market_data
  coinbase_feed --> venue_net
  kraken_feed --> market_data
  kraken_feed --> venue_net
  deribit_feed --> market_data
  deribit_feed --> venue_net
  bitget_feed --> market_data
  bitget_feed --> venue_net
  market_recorder --> okx_feed
  market_recorder --> coinbase_feed
  market_recorder --> kraken_feed
  market_recorder --> deribit_feed
  market_recorder --> bitget_feed
  market_replay --> market_data
  market_replay --> hl_protocol
  market_replay --> binance_protocol
  market_replay --> bybit_protocol
  money --> fixed_decimal
  ledger --> money
  payments_core --> money
  payments_core --> ledger
  card_core --> money
  card_core --> ledger
  card_core --> payments_core
  risk_rules --> money
  risk_rules --> payments_core
  risk_models --> risk_rules
  transaction_monitoring --> risk_rules
  transaction_monitoring --> risk_models
  transaction_monitoring --> money
  transaction_monitoring --> ledger
  transaction_monitoring --> pg_async
  banking_provider --> money
  banking_provider --> ledger
  banking_provider --> kyc_core
  sanctions_screening --> kyc_core
  sanctions_screening --> pg_async
  banking_provider --> payments_core
  banking_provider --> card_core
  striga_provider --> banking_provider
  striga_provider --> striga_client
  griffin_provider --> banking_provider
  griffin_provider --> griffin_client
  lightspark_provider --> banking_provider
  lightspark_provider --> lightspark_client
  org_access --> money
  payouts_core --> money
  payouts_core --> ledger
  payouts_core --> payments_core
  accounting_sync --> money
  accounting_sync --> ledger
  treasury_rules --> money
  treasury_rules --> risk_rules
  billing_core --> money
  billing_core --> ledger
  chain_books --> money
  chain_books --> ledger
  chain_books --> hl_protocol
  neobank_api --> banking_provider
  neobank_api --> striga_provider
  neobank_api --> risk_rules
  neobank_api --> pg_async
  neobank_api --> neobank_api_types
  neobank_web --> neobank_api_types

  fx_core --> money
  fx_core --> ledger
  fx_core --> payments_core
  investing_core --> fixed_decimal
  investing_core --> money
  investing_core --> ledger
  requests_core --> money
  requests_core --> ledger
  requests_core --> payments_core
  pots_and_insights --> money
  pots_and_insights --> ledger
  pots_and_insights --> scheduler_core
  rewards_core --> money
  rewards_core --> ledger
  statements --> money
  statements --> ledger

  copy_core --> exchange_core
  copy_core --> hl_protocol
  copy_core --> market_data
  leaderboard --> hl_client
  leaderboard --> copy_core
  leaderboard --> leader_scoring
  leader_scoring --> market_data
  leader_scoring --> hl_client
  leaderboard --> parquet
  copy_backtest --> leaderboard
  copy_backtest --> copy_core
  copy_backtest --> parquet
  copy_engine --> hl_client
  copy_engine --> copy_core
  copy_engine --> market_data
  copy_engine --> exec_algos
  exec_algos --> market_data
  exec_algos --> exchange_core
  copy_bt --> copy_core
  copy_bt --> exec_algos
  copy_bt --> market_data
  copy_bt --> parquet
  copy_bt --> hl_protocol
  copy_bt --> backtest_stats
  copy_bt --> copy_engine
  copy_api --> copy_core
  copy_api --> hl_client
  copy_api --> copy_web
  copy_api --> pg_async
  copy_api -.-> leaderboard

  hl_mm -.-> hl_sim
  market_maker -.-> hl_sim
  binance_client -.-> binance_sim
  bybit_client -.-> bybit_sim
  market_replay -.-> hl_client
  copy_api -.-> hl_sim
  copy_engine -.-> hl_sim
  market_replay -.-> binance_client
  market_replay -.-> bybit_client
  infra -.-> hl_sim
  infra -.-> binance_sim
  infra -.-> bybit_sim
  infra -.-> market_maker
  infra -.-> market_recorder
  infra -.-> market_data
```

The copy-trading edges are planned from the design and are confirmed as each
repository's `dune-project` lands; hl-copy-engine's and hl-copy-api's are landed
(`hl-copy-web` stands for its `hl-copy-api-types` package, and the API reaches
`hl-leaderboard` over HTTP, linking it only in tests). `hl-copy-backtest` is the second
package of [hl-copy-core](repos/hl-copy-core.md); it needs `hl-leaderboard`, which needs
`hl-copy-core`. See [design/copytrading.md](design/copytrading.md).

The `*-feed` repositories also list `exchange-core` (Coinbase, Kraken, Deribit) and
`fixed-decimal` (Kraken) directly. `fixed-decimal`, `venue-net`, `parquet` and `pg-async`
depend on no org package. `exchange-core` holds two packages because `order-book` sits between them:
`fixed-decimal -> exchange-core -> order-book -> exchange-core-engine`.

## Runtime data flow

```mermaid
graph LR
  subgraph venues["Venues"]
    hl_api["Hyperliquid API"]
    bn_api["Binance USD-M API"]
    by_api["Bybit v5 API"]
    more_api["OKX, Coinbase, Kraken, Deribit, Bitget public APIs"]
  end
  subgraph sims["Simulators"]
    hl_sim["hl-sim :3000"]
    bn_sim["binance-sim :3300"]
    by_sim["bybit-sim :3400"]
  end
  subgraph tradfi_sims["TradFi simulators, binary over TCP"]
    nyse_sim["nyse-sim :4100-4102"]
    cboe_sim["cboe-sim :9300-9302"]
    cme_sim["cme-sim :4300-4302"]
  end
  tradfi_cli["*-sim-cli, e2e scripts, own SBE or BOE code"]
  tradfi_json["JSON feed on /ws"]
  live_feed["Live_feed in hl-, binance-, bybit-client"]
  feeds["Live_feed in the five *-feed repositories"]
  recorder["market-recorder"]
  raw["raw minute files .ndjson.zst"]
  norm["norm/ event logs .bin"]
  uploader["Uploader: rclone command"]
  s3[("S3 bucket")]
  day_close["market-data day-close"]
  pq["parquet/ tables"]
  duckdb["DuckDB SQL"]
  mm["market-maker"]
  anchor["price-anchor (planned)"]

  hl_api --> live_feed
  bn_api --> live_feed
  by_api --> live_feed
  sims --> live_feed
  live_feed -->|on_raw frames| recorder
  live_feed -->|Market_data.Event| recorder
  more_api --> feeds
  feeds -->|on_raw frames, Market_data.Event| recorder
  recorder --> raw
  recorder --> norm
  raw --> uploader
  uploader --> s3
  norm --> day_close
  day_close --> pq
  pq -->|rclone copy| s3
  pq --> duckdb
  s3 --> duckdb
  mm -->|orders, Venue.S| sims
  mm -.->|testnet or mainnet| venues
  venues -.-> anchor
  anchor -.->|mark, top-N levels, trades| sims
  tradfi_cli -->|Pillar, BOE, iLink 3 orders| tradfi_sims
  tradfi_sims -->|XDP, PITCH, MDP 3.0| tradfi_cli
  tradfi_sims --> tradfi_json
  anchor -.->|noise anchored to a reference| tradfi_sims
```

- Each client's `Live_feed.create ?on_raw config ~symbols ~streams` returns a
  `Market_data.Feed.t` (one pipe each for trades, BBO, L2 and funding) and passes every
  frame's text and receive time to `on_raw` before parsing.
- The `*-feed` repositories' `Live_feed.create` has the same shape, read-only, over each
  venue's public websocket.
- `market-recorder` writes raw frames to Tardis-style minute files and normalized events
  to `market-data` event logs, and hands closed minute files to a configurable upload
  command. See [design/data-platform.md](design/data-platform.md).
- `day-close` turns a finished day of event logs into Parquet tables and candles; in the
  Helm chart it runs as a CronJob next to the recorder and uploads `parquet/` with rclone.
  See [design/deployment.md](design/deployment.md).
- `market-maker` drives a simulator or a real venue through `Mm_core.Live.Make`. See
  [design/market-making.md](design/market-making.md).
- The copy-trading platform (in progress) mirrors a Hyperliquid leader's positions
  into followers' accounts through agent keys the followers approve, against `hl-sim`
  or testnet. See [design/copytrading.md](design/copytrading.md).
- The neobank demo (in progress) runs onboarding with KYC, a EUR IBAN account, crypto wallets,
  swaps, SEPA, on-chain and Lightning payments, virtual cards and standing orders over
  provider-neutral libraries (`money`, `ledger`, `kyc-core`, `payments-core`, `card-core`,
  `risk-rules`, `banking-provider`) and the Striga sandbox, or offline over a fake provider.
  Its application state is in PostgreSQL through [pg-async](repos/pg-async.md). See
  [design/neobank.md](design/neobank.md).
- The TradFi simulators have no real data source: noise traders move their books, and
  their order entry and market data are binary over TCP, with the feed repeated as JSON
  on `/ws`. Nothing in the data platform consumes them yet. See
  [design/simulators.md](design/simulators.md#tradfi-simulators).
- `price-anchor` is planned: anchoring simulator prices to real venues. See
  [design/price-anchor.md](design/price-anchor.md).

## Conventions shared by every OCaml repository

- `open! Core`, an `.mli` for every module, labelled arguments, ppx_jane derivations.
- Times are `int` nanoseconds or `Time_ns.t`; venue millisecond timestamps are converted
  at the edge.
- Prices, sizes and USD amounts are `Exchange_core.Price`, `Size`, `Usd`: distinct
  `Fixed_decimal.Make ()` types counting 10^-8 units in an `int`.
- Wire codecs live only in `*-protocol` repositories; `exchange-core` types carry no JSON.
- CI uses `ocaml/setup-ocaml@v3` with the `5.2.0+ox` compiler from the `ox` opam
  repository and pins sibling repositories from GitHub in dependency order.
