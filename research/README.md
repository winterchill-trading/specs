# Research notes

Reading notes on public engineering writing from a trading firm whose stack ours is built
on: the Jane Street tech blog and the Signals and Threads podcast. The goal is to pull out
what matters for this organization (trading system and data platform architecture,
OCaml and OxCaml practice, testing, performance, deployment, research tooling) and turn it
into concrete proposals for our repositories.

## How to read

- **Theme documents** under [themes/](themes/) synthesize across sources, compare with
  where our repositories stand, and end with a merged, ordered list of proposed actions.
  Read these first.
- **Top 20** below is the short list we would start with.
- **[OxCaml performance](oxcaml-performance/README.md)** has one verified note per language
  or compiler technique (stack allocation, unboxed types, `[@zero_alloc]`, Flambda 2 and
  more) and an audit of our hot paths against them.
- **[Banking infrastructure](banking-infrastructure/README.md)** has one note per banking
  topic (ledger, payment schemes, SCA, KYC and AML, fraud models, cards, treasury,
  reliability) with the fields, codes and thresholds to adopt, and a per-repository
  [implications](banking-infrastructure/implications.md) checklist for the neobank libraries.
- **Insights for us** lists every actionable insight found in the notes, one line each,
  grouped by theme and ordered by value, with a link to the source note and the
  repositories it affects. Several insights from different sources often point at the
  same change; the theme documents merge them.
- **Per-source notes** live under [janestreet/blog/](janestreet/blog/) (named
  `<yyyy-mm>-<slug>.md`) and [janestreet/podcast/](janestreet/podcast/) (named
  `<nn>-<slug>.md`, by episode number). Each gives the source URL and date, a summary in
  our own words, a "Relevance to us" section with one bullet per actionable insight, and a
  tags line. The [index](#index) lists them all.
- The proposed actions also appear one line each in
  [roadmap.md](../roadmap.md#from-research).
- A **Done:** line after an insight links the repository page (or spec page) and the
  commit that implemented it. Partly done insights carry no marker; the roadmap line
  says what is left.
- Notes summarize; they do not reproduce. Quotes are short and attributed. Read the
  original for anything load-bearing. Claims about our repositories were checked against
  the code at the time of writing; the repository's own README and `.mli` files win when
  they disagree.

## Scope

- Every Signals and Threads episode (30 episodes; the two trailers are not covered).
- Every blog post from 2018 onward (88 posts), and 33 earlier posts whose titles are
  relevant to trading systems, OCaml practice, testing, performance or tooling.

## Top 20

The twenty insights we would act on first, highest value first.

1. A deterministic engine is reproducible exactly by replaying its inputs. **Action:** Input journal
   of place/cancel/modify/step/set_mark plus expect test replaying it and diffing drain_events.
   Source: [State Machine Replication, and Why You Should
   Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md). Affects:
   [exchange-core](../repos/exchange-core.md).
   **Done:** [exchange-core](../repos/exchange-core.md), commit `b26dee9`.
1. Fakes that always behave hide caller bugs; bugification makes worst-allowed behaviour routine in
   tests. **Action:** Add a seeded bugify mode to the in-memory Venue.S test fake (rejects, delayed
   cancel acks, split fills, stale open-order polls). Source: [Why Testing is Hard and How to Fix
   it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
   [mm-core](../repos/mm-core.md).
   **Done:** [mm-core](../repos/mm-core.md), commit `d2f0d7a`.
1. A too-aggressive market maker never crashes, so quoting and inventory properties must be explicit.
   **Action:** Base_quickcheck test driving Strategy with random events over seeds: quotes never
   cross, stay ordered, cannot exceed max_position if all fill. Source: [Why Testing is Hard and How
   to Fix it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
   [mm-core](../repos/mm-core.md).
   **Done:** [mm-core](../repos/mm-core.md), commit `c3499eb`.
1. Receivers must know when they lost messages; client resyncs are invisible through Feed.t.
   **Action:** Gap/reconnect event in Market_data.Feed.t written as a disconnect line, tested with a
   forced Bybit gap. Source: [Multicast and the
   Markets](janestreet/podcast/03-multicast-and-the-markets.md). Affects:
   [market-data](../repos/market-data.md), [market-recorder](../repos/market-recorder.md),
   [hl-client](../repos/hl-client.md), [binance-client](../repos/binance-client.md),
   [bybit-client](../repos/bybit-client.md).
1. Late joiners need a compact snapshot, not a replay from midnight. **Action:** Write periodic
   (per-minute) L2 snapshot events so Replay_feed can start mid-day. Source: [Multicast and the
   Markets](janestreet/podcast/03-multicast-and-the-markets.md). Affects:
   [market-recorder](../repos/market-recorder.md), [market-data](../repos/market-data.md).
1. Bisimulation of an optimized structure against a slow reference via random operation sequences.
   **Action:** Add a quickcheck bisimulation test of Order_book against a naive list-based reference
   book. Source: [What the interns have wrought, 2022
   edition](janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md). Affects:
   [order-book](../repos/order-book.md).
   **Done:** [order-book](../repos/order-book.md), commit `834fb9f`.
1. Engine invariants checked on every step are cheap, strong properties for a deterministic
   simulator. **Action:** Base_quickcheck test of random place/cancel/step sequences on Exchange
   asserting zero net position, uncrossed book, unique order ids. Source: [Why Testing is Hard and
   How to Fix it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
   [exchange-core](../repos/exchange-core.md).
   **Done:** [exchange-core](../repos/exchange-core.md), commit `9fab05b`.
1. Multi-symbol replay is an n-way merge of per-stream files; correctness must hold for any
   interleaving. **Action:** Base_quickcheck property test: random multi-symbol events through
   Event_log and Merge, check global recv_ts order, no loss or duplicates. Source: [Scaling and
   benchmarking a critical message bus using a new indexing
   strategy](janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md). Affects:
   [market-data](../repos/market-data.md).
   **Done:** [market-data](../repos/market-data.md), commit `6ba22bf`.
1. Failure paths can be forced without real outages (rlimits, LD_PRELOAD, one-thread pool).
   **Action:** Expect test: Ws_client.connect to a listener that never completes the handshake; check
   timeout and FD count restored. Source: [How recurring network maintenance exposed 6
   bugs](janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md). Affects:
   [venue-net](../repos/venue-net.md).
   **Done:** [venue-net](../repos/venue-net.md), commit `3397fd9`.
1. Unexpected input that crashes the error path or vanishes silently is the classic pipeline
   incident; client parse errors are uncounted. **Action:** Count per-stream parse errors from
   Live_feed into Metrics, expect test with one malformed frame from hl-sim. Source: [Solving Puzzles
   in Production](janestreet/podcast/20-solving-puzzles-in-production.md). Affects:
   [market-recorder](../repos/market-recorder.md), [hl-client](../repos/hl-client.md),
   [binance-client](../repos/binance-client.md), [bybit-client](../repos/bybit-client.md),
   [hl-sim](../repos/hl-sim.md).
1. Without tick-to-order measurement a deferred send goes unnoticed. **Action:**
   recv_ts-to-order-send histogram in Live.Make, p50/p99/max logged at shutdown. Source: [Performance
   Engineering on Hard Mode](janestreet/podcast/18-performance-engineering-on-hard-mode.md). Affects:
   [mm-core](../repos/mm-core.md).
   **Done:** [mm-core](../repos/mm-core.md), commit `0beaf15`.
1. Cross-host timestamp comparison is only valid within measured clock error, which we do not record.
   **Action:** Clock error gauge in /metrics from chronyc tracking every 10 s. Source: [Clock
   Synchronization](janestreet/podcast/06-clock-synchronization.md). Affects:
   [market-recorder](../repos/market-recorder.md).
1. Tested, reviewable transformations catch bad data at each stage. **Action:** Add market-data check
   running fixed DuckDB assertions (no crossed BBO, positive sizes, monotonic recv_ts, no empty
   minutes on liquid symbols) after day-close. Source: [Wrestling the world into
   rows](janestreet/podcast/29-wrestling-the-world-into-rows.md). Affects:
   [market-data](../repos/market-data.md), [infra](../repos/infra.md).
1. Owning the catalog is what makes deprecation and schema evolution possible. **Action:** Add
   market-data catalog -dir D listing per table venues, symbols, date range, file count and leftover
   numbered parts, with an expect test. Source: [Building a data warehouse from
   scratch](janestreet/podcast/28-building-a-data-warehouse-from-scratch.md). Affects:
   [market-data](../repos/market-data.md).
   **Done:** [market-data](../repos/market-data.md), commit `9391e27`.
1. Contract multipliers make raw prices incomparable across venues (1000PEPEUSDT, kPEPE quote per
   1,000 tokens). **Action:** Add a units_per_contract table exposed as a DuckDB view, with an expect
   test showing per-token mids agree across three venues. Source: [Wrestling the world into
   rows](janestreet/podcast/29-wrestling-the-world-into-rows.md). Affects:
   [market-data](../repos/market-data.md).
   **Done:** [market-data](../repos/market-data.md), commit `54d5062`.
1. A rebuilt normalizer path can be validated by diffing against what ran live. **Action:** Make the
   raw-to-norm tool's acceptance test rebuild one day and diff it event by event against live norm/
   logs. Source: [Building a functional email
   server](janestreet/podcast/08-building-a-functional-email-server.md). Affects:
   [market-data](../repos/market-data.md), [market-recorder](../repos/market-recorder.md).
1. Version-skew tests catch writer/reader incompatibilities. **Action:** Check in an event log
   written by current code and test future versions still read it. Source: [Getting from tested to
   battle-tested](janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md). Affects:
   [market-data](../repos/market-data.md).
   **Done:** [market-data](../repos/market-data.md), commit `dfd512d`.
1. OxCaml extensions have no stability promise; CI pulls the ox repo unpinned while the base image
   pins it. **Action:** Pin the ox opam repository to the base image's commit in every CI workflow.
   Source: [Introducing OxCaml](janestreet/blog/2025-06-introducing-oxcaml.md). Affects:
   [infra](../repos/infra.md), [fixed-decimal](../repos/fixed-decimal.md).
1. Captured real traffic is the best codec test data, and the recorder already stores frames
   verbatim. **Action:** Check a trimmed raw minute file into hl-protocol tests; expect test decodes
   every frame, prints counts per channel and errors. Source: [A FUSE server for our in-house storage
   backend](janestreet/blog/2026-10-linux-engineering-depot-fuse.md). Affects:
   [hl-protocol](../repos/hl-protocol.md), [market-recorder](../repos/market-recorder.md).
1. No org benchmark exists, so allocation and speed claims are unmeasured. **Action:** Add a
   core_bench bench for submit/cancel on a 1000-level book in order-book with a README baseline.
   Source: [Core_bench: better micro-benchmarks through linear
   regression](janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md). Affects:
   [order-book](../repos/order-book.md).
   **Done:** [order-book](../repos/order-book.md), commit `8c1bd24`.

## Insights for us

All 236 actionable insights from the notes, grouped by theme. Each line gives the insight,
the proposed action, the source note and the repositories it affects.

### Logs and state machines

18 insights, highest value first.

- A deterministic engine is reproducible exactly by replaying its inputs. **Action:** Input journal
  of place/cancel/modify/step/set_mark plus expect test replaying it and diffing drain_events.
  Source: [State Machine Replication, and Why You Should
  Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md). Affects:
  [exchange-core](../repos/exchange-core.md).
  **Done:** [exchange-core](../repos/exchange-core.md), commit `b26dee9`.
- Receivers must know when they lost messages; client resyncs are invisible through Feed.t.
  **Action:** Gap/reconnect event in Market_data.Feed.t written as a disconnect line, tested with a
  forced Bybit gap. Source: [Multicast and the
  Markets](janestreet/podcast/03-multicast-and-the-markets.md). Affects:
  [market-data](../repos/market-data.md), [market-recorder](../repos/market-recorder.md),
  [hl-client](../repos/hl-client.md), [binance-client](../repos/binance-client.md),
  [bybit-client](../repos/bybit-client.md).
- Unexpected input that crashes the error path or vanishes silently is the classic pipeline
  incident; client parse errors are uncounted. **Action:** Count per-stream parse errors from
  Live_feed into Metrics, expect test with one malformed frame from hl-sim. Source: [Solving Puzzles
  in Production](janestreet/podcast/20-solving-puzzles-in-production.md). Affects:
  [market-recorder](../repos/market-recorder.md), [hl-client](../repos/hl-client.md),
  [binance-client](../repos/binance-client.md), [bybit-client](../repos/bybit-client.md),
  [hl-sim](../repos/hl-sim.md).
- Simple replication depends on deterministic components; our engine claims determinism untested.
  **Action:** Expect test driving two exchange-core engines with identical seeded input and
  comparing event streams. Source: [How to Build an
  Exchange](janestreet/blog/2017-01-how-to-build-an-exchange.md). Affects:
  [exchange-core](../repos/exchange-core.md).
  **Done:** [exchange-core](../repos/exchange-core.md), commit `944b32f`.
- Re-broadcasting full state on each small change makes bursts quadratic and the consumer silently
  lags. **Action:** Add expect test counting subscribe frames sent at connect and reconnect for a
  3-symbol config. Source: [Troubleshooting systemd with
  SystemTap](janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Order-to-fill latency needs the market maker's own order events recorded. **Action:** Write
  market-maker order lifecycle events to an event log queryable with SQL. Source: [What the interns
  have wrought, 2023 edition](janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md).
  Affects: [market-maker](../repos/market-maker.md), [market-data](../repos/market-data.md).
- A log-plus-snapshots replay debugger makes incidents inspectable. **Action:** Add a market-data
  dump subcommand printing a time window of an Event_log as sexps. Source: [What the interns have
  wrought, 2024 edition](janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md).
  Affects: [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `3f1f0ed`.
- Requests outside available data must get an explicit error, never garbage. **Action:** Replay_feed
  errors explicitly on a date range with no event log files, with an expect test. Source: [Getting
  from tested to battle-tested](janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md).
  Affects: [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `68572ca`.
- A sequenced event stream lets consumers rebuild state by replay; engine events have no sequence
  number. **Action:** Add a sequence number to engine Event and a replay-to-fresh-book expect test.
  Source: [Multicast and the Markets](janestreet/podcast/03-multicast-and-the-markets.md). Affects:
  [exchange-core](../repos/exchange-core.md).
  **Done:** [exchange-core](../repos/exchange-core.md), commit `c66a166`.
- Stepped clocks break code assuming time moves forward; files and Merge assume ordered recv_ts.
  **Action:** Clamp recv_ts non-decreasing per stream and count clamps in /metrics. Source: [Clock
  Synchronization](janestreet/podcast/06-clock-synchronization.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Replication merge must treat near-ties within clock error as unordered. **Action:** State the
  unordered-within-bound rule in design/cloud-sinks-and-replication.md. Source: [Clock
  Synchronization](janestreet/podcast/06-clock-synchronization.md). Affects: `specs`.
  **Done:** [cloud sinks design](../design/cloud-sinks-and-replication.md).
- An explicit input-to-transition state machine is replayable if its inputs are logged. **Action:**
  Add a debug option in market-maker logging each Strategy input and resulting plan as one sexp line
  for replay tests. Source: [Building a UI
  Framework](janestreet/podcast/11-building-a-ui-framework.md). Affects:
  [market-maker](../repos/market-maker.md), [mm-core](../repos/mm-core.md).
- Readers should refuse a log whose format digest they do not recognize. **Action:** Header frame
  with Event.Stable.V1 bin_shape digest in each Event_log file; fail on mismatch. Source: [State
  Machine Replication, and Why You Should
  Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `536fd90`.
- Time travel needs state reconstruction, i.e. a book at time t. **Action:** Add -book-at to the
  dump, replaying L2 into a local book and printing top levels. Source: [What the interns have
  wrought, 2024 edition](janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md).
  Affects: [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `3f1f0ed`.
- Machine-readable decision reasons make logs from two implementations diffable. **Action:** Quoter
  returns a typed reason for each unquoted side, logged as sexp. Source: [Building and testing a
  config management orchestrator for
  Windows](janestreet/blog/2026-10-config-management-orchestrator-for-windows.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `578d956`.
- Per-second host socket history made a weeks-old incident reconstructable. **Action:** Add
  node-exporter or equivalent socket/FD collector to the compose stack and Helm notes. Source: [How
  recurring network maintenance exposed 6
  bugs](janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md). Affects:
  [infra](../repos/infra.md).
  **Done:** [infra](../repos/infra.md), commit `2065e6c`.
- Diagnostics must not share a dependency with the failure they report. **Action:** Recorder
  /healthz reports the last Raw_writer flush error and its age. Source: [A resilient kernel log
  reporter](janestreet/blog/2026-10-linux-engineering-kernel-reporter.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Alerts need stateful damping to stay useful. **Action:** Log repeated warnings of one kind at most
  once a minute per stream with a suppressed count. Source: [Building Tools for
  Traders](janestreet/podcast/23-building-tools-for-traders.md). Affects:
  [market-recorder](../repos/market-recorder.md).

### Data platform

33 insights, highest value first.

- Latency is most useful as a distribution over time of day, and we store exch_ts and recv_ts on
  every row. **Action:** Add Parquet_views DuckDB view with per-minute p50/p99 of recv_ts - exch_ts
  per venue and stream. Source: [What the interns have wrought, 2019
  edition](janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md) (`lag` view), commit `4a55541`.
- Producer outrunning consumer through an unbounded queue shows as growing object lifetimes.
  **Action:** Add test stalling Norm_writer while feeding input and printing buffered event count to
  check pipe pushback. Source: [Finding memory leaks with
  Memtrace](janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Multi-symbol replay is an n-way merge of per-stream files; correctness must hold for any
  interleaving. **Action:** Base_quickcheck property test: random multi-symbol events through
  Event_log and Merge, check global recv_ts order, no loss or duplicates. Source: [Scaling and
  benchmarking a critical message bus using a new indexing
  strategy](janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `6ba22bf`.
- Late joiners need a compact snapshot, not a replay from midnight. **Action:** Write periodic
  (per-minute) L2 snapshot events so Replay_feed can start mid-day. Source: [Multicast and the
  Markets](janestreet/podcast/03-multicast-and-the-markets.md). Affects:
  [market-recorder](../repos/market-recorder.md), [market-data](../repos/market-data.md).
- Cross-host timestamp comparison is only valid within measured clock error, which we do not record.
  **Action:** Clock error gauge in /metrics from chronyc tracking every 10 s. Source: [Clock
  Synchronization](janestreet/podcast/06-clock-synchronization.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- A rebuilt normalizer path can be validated by diffing against what ran live. **Action:** Make the
  raw-to-norm tool's acceptance test rebuild one day and diff it event by event against live norm/
  logs. Source: [Building a functional email
  server](janestreet/podcast/08-building-a-functional-email-server.md). Affects:
  [market-data](../repos/market-data.md), [market-recorder](../repos/market-recorder.md).
- Owning the catalog is what makes deprecation and schema evolution possible. **Action:** Add
  market-data catalog -dir D listing per table venues, symbols, date range, file count and leftover
  numbered parts, with an expect test. Source: [Building a data warehouse from
  scratch](janestreet/podcast/28-building-a-data-warehouse-from-scratch.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `9391e27`.
- Contract multipliers make raw prices incomparable across venues (1000PEPEUSDT, kPEPE quote per
  1,000 tokens). **Action:** Add a units_per_contract table exposed as a DuckDB view, with an expect
  test showing per-token mids agree across three venues. Source: [Wrestling the world into
  rows](janestreet/podcast/29-wrestling-the-world-into-rows.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `54d5062`.
- Recorded multi-venue receive timestamps allow a lead-lag measurement of price moves. **Action:**
  Add a DuckDB lead-lag query (1 bp in 5 ms moves) to market-data views. Source: [Visualizing
  information propagation in
  markets](janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md). Affects:
  [market-data](../repos/market-data.md).
- Temporal 'last X before Y' queries over an ordered stream are the core debugging tool; DuckDB ASOF
  JOIN covers it. **Action:** Add a trades_with_bbo ASOF JOIN view to market-data Parquet_views.
  Source: [What the interns have wrought, 2023
  edition](janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `4a55541`.
- Wasted bytes per read is the metric for choosing file granularity. **Action:** DuckDB query
  reporting bytes per venue, stream and symbol for one day, in the data-platform design page.
  Source: [Scaling and benchmarking a critical message bus using a new indexing
  strategy](janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md). Affects:
  `specs`, [market-data](../repos/market-data.md).
  **Done:** [example queries](../design/queries.md).
- Logic in two implementations needs a golden sample check; candles exist in OCaml and SQL.
  **Action:** Test comparing Candle_agg output with DuckDB candles over the same day's Parquet.
  Source: [Python, OCaml, and Machine
  Learning](janestreet/podcast/05-python-ocaml-and-machine-learning.md). Affects:
  [market-data](../repos/market-data.md).
- exch_ts and recv_ts together expose network delay and clock drift. **Action:** DuckDB view of
  per-venue per-minute median and p99 of recv_ts - exch_ts. Source: [Clock
  Synchronization](janestreet/podcast/06-clock-synchronization.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md) (`lag` view), commit `4a55541`.
- New sources should plug in through a signature, not edits to a central match. **Action:**
  Introduce a Venue_source.S module type in market-recorder and register clients as first-class
  modules. Source: [What Is an Operating
  System?](janestreet/podcast/12-what-is-an-operating-system.md). Affects:
  [market-recorder](../repos/market-recorder.md), [hl-client](../repos/hl-client.md),
  [binance-client](../repos/binance-client.md), [bybit-client](../repos/bybit-client.md).
- Replay must keep one global order across streams or small streams run ahead. **Action:** Expect
  test: Replay_feed over 10-event and 10k-event streams outputs sorted recv_ts. Source: [State
  Machine Replication, and Why You Should
  Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `6ba22bf`.
- Start-of-day replay does not scale; snapshots are consumer specific. **Action:** Replay_feed
  starts at last L2 Snapshot at or before requested start. Source: [State Machine Replication, and
  Why You Should Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md).
  Affects: [market-data](../repos/market-data.md).
- Sequence numbers plus peer retransmitters is the shape of our planned replication. **Action:**
  Specify gap detection by venue seq fields and peer gap fill in
  design/cloud-sinks-and-replication.md. Source: [State Machine Replication, and Why You Should
  Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md). Affects:
  `specs`.
  **Done:** [cloud sinks design](../design/cloud-sinks-and-replication.md).
- Synthesized values become facts consumers rely on; record absent as absent. **Action:**
  Funding.Stable.V2 with optional exch_ts, absent for Hyperliquid instead of copying recv_ts.
  Source: [Swapping the Engine Out of a Moving Race
  Car](janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md). Affects:
  [market-data](../repos/market-data.md), [hl-client](../repos/hl-client.md).
- Cleaned data still needs independent checks; reconnect gaps are not marked in raw files.
  **Action:** Add SQL view of per venue/symbol/day minutes with zero trades or BBO updates, tested
  on fixture with a gap. Source: [Finding Signal in the
  Noise](janestreet/podcast/22-finding-signal-in-the-noise.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md) (`check` and its `gaps` view), commit `0746d97`.
- Point-in-time universes avoid survivorship bias; we keep no daily record of instruments and their
  tick/lot. **Action:** day-close writes a daily instruments table (venue, symbol, tick, lot,
  first/last recv_ts). Source: [Finding Signal in the
  Noise](janestreet/podcast/22-finding-signal-in-the-noise.md). Affects:
  [market-data](../repos/market-data.md).
- Rebuilt history must record what produced it so corrected outputs are distinguishable. **Action:**
  day-close writes `<date>.manifest.sexp` per table with producer version, source norm/ files and
  sizes, run time. Source: [Wrestling the world into
  rows](janestreet/podcast/29-wrestling-the-world-into-rows.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `a3d5865`.
- Cross-region recv_ts comparison needs synchronized clocks. **Action:** Expose host clock offset as
  a market-recorder metric. Source: [Visualizing information propagation in
  markets](janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Market data teach-in lists client pitfalls our feeds should be checked against. **Action:** Add a
  client-pitfalls checklist to the specs data-platform page linked to covering tests. Source:
  [Developer education at Jane
  Street](janestreet/blog/2024-10-developer-education-at-jane-street.md). Affects:
  [market-data](../repos/market-data.md), [hl-client](../repos/hl-client.md),
  [binance-client](../repos/binance-client.md), [bybit-client](../repos/bybit-client.md).
  **Done:** [data platform design](../design/data-platform.md).
- Predicate pushdown only helps if storage can be skipped; our row groups are ~1M rows. **Action:**
  Use smaller row groups in Day_close for trades/L2 and verify with EXPLAIN ANALYZE. Source: [What
  the interns have wrought, 2025 edition](janestreet/blog/2025-08-wrought-2025.md). Affects:
  [market-data](../repos/market-data.md), [parquet](../repos/parquet.md).
- Reconciling own fills against public prints is a cheap correctness check. **Action:** DuckDB query
  joining market-maker fills to recorded trades by price, size and time window. Source: [What the
  TDOE interns have wrought, 2026 edition](janestreet/blog/2026-09-tdoe-intern-projects-2026.md).
  Affects: `specs`, [market-data](../repos/market-data.md),
  [market-maker](../repos/market-maker.md).
- Early cutoff applies to batch rebuilds: skip work when inputs are unchanged. **Action:** day-close
  writes an input manifest (sizes, hashes) and skips unchanged days. Source: [Build
  Systems](janestreet/podcast/02-build-systems.md). Affects: [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `a3d5865`.
- Slow consumers should lag visibly, not lose data silently. **Action:** Expose Parquet_sink
  dropped-row count and surface it in /metrics. Source: [Swapping the Engine Out of a Moving Race
  Car](janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md). Affects:
  [market-data](../repos/market-data.md), [market-recorder](../repos/market-recorder.md).
- Removing specific bad records from a stream turns a crash into a quick recovery. **Action:** Give
  the planned raw-to-norm tool a skip-list of raw file and line numbers to exclude. Source: [Solving
  Puzzles in Production](janestreet/podcast/20-solving-puzzles-in-production.md). Affects:
  [market-data](../repos/market-data.md).
- Derived datasets need a record of exact inputs and code; our parquet writer has no key-value
  metadata. **Action:** day-close writes manifest.sexp listing input event logs with sizes and build
  version, with expect test. Source: [The Uncertain Art of Accelerating ML
  Models](janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md). Affects:
  [market-data](../repos/market-data.md), [parquet](../repos/parquet.md).
  **Done:** [market-data](../repos/market-data.md), commit `a3d5865`.
- Previewing the effect of a change, including failure what-ifs, is what made the network tooling
  valuable. **Action:** Add a failure table (collector down, region down, uploader stalled) with
  expected gaps and detection to design/cloud-sinks-and-replication.md. Source: [The Network as a
  Program](janestreet/podcast/27-the-network-as-a-program.md). Affects: `specs`.
  **Done:** [cloud sinks design](../design/cloud-sinks-and-replication.md).
- Small files multiply into object-store and metadata cost; compaction between write and read keeps
  reads fast. **Action:** Have day-close print per table and day input frames, sink parts replaced
  and output bytes in the CronJob log. Source: [Building a data warehouse from
  scratch](janestreet/podcast/28-building-a-data-warehouse-from-scratch.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `d48772f`.
- Random access into compressed files is ~1000x slower than streaming; raw files suit sequential
  replay only. **Action:** State in specs design/data-platform.md that raw zstd files are for
  sequential replay and point queries go through Parquet/DuckDB. Source: [How to shuffle a big
  dataset](janestreet/blog/2018-09-how-to-shuffle-a-big-dataset.md). Affects: `specs`,
  [market-data](../repos/market-data.md).
  **Done:** [data platform design](../design/data-platform.md).
- Failing over to a farther site is a latency change, not a transparent swap. **Action:** Add open
  question on tagging events with collector and region to design/cloud-sinks-and-replication.md.
  Source: [The Thermodynamics of Trading](janestreet/podcast/24-the-thermodynamics-of-trading.md).
  Affects: `specs`.
  **Done:** [cloud sinks design](../design/cloud-sinks-and-replication.md).

### OCaml practice

32 insights, highest value first.

- Errors should carry the offending value as sexp context. **Action:** Make Params.validate build
  errors with Error.create_s including the field value. Source: [How to fail -- introducing
  Or_error.t](janestreet/blog/2014-04-how-to-fail-introducing-or-error-dot-t.md). Affects:
  [mm-core](../repos/mm-core.md).
- Full record destructuring forces every field to be validated. **Action:** Destructure Params.t
  fully in Params.validate with no wildcard. Source: [How to fail -- introducing
  Or_error.t](janestreet/blog/2014-04-how-to-fail-introducing-or-error-dot-t.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `9725c9f`.
- Tagged ints cap 10^-8 units near 4.6e10; the limit should be pinned in code. **Action:** Add an
  expect test pinning fixed-decimal's max value and the parse failure one unit above. Source: [What
  is gained and lost with 63-bit
  integers?](janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `36ffdf6`.
- Universal type guarantees are the cheapest check on agent-written code; escape hatches undo them.
  **Action:** Rule and CI grep failing on Obj.magic or Obj.repr outside an allowlist. Source:
  [Formal methods and the future of
  programming](janestreet/blog/2026-06-formal-methods-at-jane-street.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `0010965`.
- Modes encode resource ownership (local, unique, borrow_) and agents need working examples.
  **Action:** Compiling example of @ local, @ unique and borrow_ with switch support notes and
  GOTCHAS entries. Source: [Using OxCaml to implement type-safe reference counting between OCaml and
  Python](janestreet/blog/2026-06-oxcaml-typesafe-reference-counting-python.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `31215bf`.
- Distinct duration types rule out unit mistakes raw ints allow. **Action:** Change mm-core Params
  *_ms int fields to Time_ns.Span.t. Source: [Core Gems:
  Time](janestreet/blog/2009-11-core-gems-time.md). Affects: [mm-core](../repos/mm-core.md).
- NaN and infinity must not reach fixed-point values silently. **Action:** Add an expect test that
  fixed-decimal of_float raises on nan and infinity, and document it. Source: [Making something out
  of nothing (or, why None is better than NaN and
  NULL)](janestreet/blog/2010-07-making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null.md).
  Affects: [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `713394c`.
- Each layer should tag errors with context instead of replacing them. **Action:** Tag
  market-recorder check-config errors with the file and venue entry index. Source: [How to fail --
  introducing Or_error.t](janestreet/blog/2014-04-how-to-fail-introducing-or-error-dot-t.md).
  Affects: [market-recorder](../repos/market-recorder.md).
- Float edge cases (-0.0, NaN, infinity) silently change results. **Action:** Expect test pinning
  Fixed_decimal of_float on -0.0/nan/infinity; raise on non-finite input. Source: [Proofs (and
  Refutations) using Z3](janestreet/blog/2018-02-proofs-and-refutations-using-z3.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `713394c`.
- Named alerts flag risky functions at call sites without deprecating them. **Action:** Add [@@alert
  lossy] to Fixed_decimal of_float and mark intended call sites with [@alert "-lossy"]. Source: [A
  look at OCaml 4.08](janestreet/blog/2019-07-a-look-at-ocaml-4-08.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `4242430`.
- Unix-dependent Core modules moved to X_unix libraries; agents still use old Core.Unix/Command.run
  names. **Action:** Add gotchas-log entry listing Core.X to X_unix renames and dune library names.
  Source: [Goodbye Core_kernel](janestreet/blog/2021-08-goodbye-core-kernel.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `d95a47d`.
- Agent-written OxCaml code can break on compiler upgrades. **Action:** Record the pinned ox commit
  and the extensions in use in oxcaml-claude-skills. Source: [Introducing
  OxCaml](janestreet/blog/2025-06-introducing-oxcaml.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
- Let%map closures cannot capture @ local values or return unboxed types. **Action:** Add rule and
  compiler error to GOTCHAS.md. Source: [Fun with Algebraic Effects - from Toy Examples to Hardcaml
  Simulations](janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
- Distinct unit types encode a key invariant that should be pinned. **Action:** Test proving Price.t
  cannot be passed where Size.t is expected (must-fail compile). Source: [Formal methods and the
  future of programming](janestreet/blog/2026-06-formal-methods-at-jane-street.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `c321187`.
- Library I/O helpers can silently split or retry syscalls. **Action:** Add Bigstring_unix.write
  ~min_len looping behaviour to GOTCHAS.md. Source: [A FUSE server for our in-house storage
  backend](janestreet/blog/2026-10-linux-engineering-depot-fuse.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `d95a47d`.
- The GC does not manage scarce resources such as file descriptors. **Action:** Test that rolling
  100 minute files keeps open descriptor count constant. Source: [Python, OCaml, and Machine
  Learning](janestreet/podcast/05-python-ocaml-and-machine-learning.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Read-only versus trading clients are a permission worth encoding in types. **Action:** Give the
  hl-client handle a phantom read_only/trading parameter when EIP-712 signing lands. Source:
  [Language Design](janestreet/podcast/07-language-design.md). Affects:
  [hl-client](../repos/hl-client.md), [market-recorder](../repos/market-recorder.md).
- The recorder gets read-only Binance clients by passing empty API keys, a convention instead of a
  type. **Action:** Add a key-less Config.read_only to binance-client and use it in market-recorder.
  Source: [Language Design](janestreet/podcast/07-language-design.md). Affects:
  [binance-client](../repos/binance-client.md), [market-recorder](../repos/market-recorder.md).
- Behavior types cannot express, like reconnect gaps, needs doc comments in the .mli. **Action:**
  Document frame loss and resync on reconnect in the venue-net Ws_client.messages doc comment.
  Source: [Writing, Technically](janestreet/podcast/10-writing-technically.md). Affects:
  [venue-net](../repos/venue-net.md).
- With tracing GC, caller-provided buffers avoid churning large short-lived buffers. **Action:**
  Check Framed reader for per-frame buffer allocation; add reusable-buffer variant if so. Source:
  [Memory Management](janestreet/podcast/13-memory-management.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `336e1ee`.
- When agents write code, a checked spec is what humans can review. **Action:** Skill rule: public
  .mli changes need a Base_quickcheck contract property in the same commit. Source: [The Future of
  Programming](janestreet/podcast/16-future-of-programming.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `10588f3`.
- Jumping from an alert to the code that raised it saves the first minutes of an incident.
  **Action:** Include [%here] positions in Raw_writer and Uploader error and warning logs. Source:
  [Solving Puzzles in Production](janestreet/podcast/20-solving-puzzles-in-production.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Pinning counterexamples only helps if every agent follows the convention. **Action:** Add rule to
  testing skill: shrunk Quickcheck counterexamples go into ~examples with the fix. Source: [Building
  Tools for Traders](janestreet/podcast/23-building-tools-for-traders.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `10588f3`.
- Agents refactor reliably when a type change comes first and compiler errors drive the edits.
  **Action:** Add a type-first refactor recipe (.mli first, dune build, fix in dependency order,
  rerun expect tests) to the janestreet-ocaml-style skill. Source: [Why ML Needs a New Programming
  Language](janestreet/podcast/25-why-ml-needs-a-new-programming-language.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `10588f3`.
- The 2023 data-race-freedom vocabulary differs from what OxCaml shipped, misleading agents.
  **Action:** Record in GOTCHAS.md which data-race modes and Capsule exist on 5.2.0+ox versus the
  blog names. Source: [Oxidizing OCaml: Data Race
  Freedom](janestreet/blog/2023-09-oxidizing-ocaml-parallelism.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
- Mode-based refcounting is a worked example of unique/local/visibility modes. **Action:** Add a
  modes-in-practice pointer entry in oxcaml-claude-skills. Source: [What the interns have wrought,
  2025 edition](janestreet/blog/2025-08-wrought-2025.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
- strace-ui hides Async futex/epoll noise and follows FDs. **Action:** Add a
  debugging-sockets-with-strace-ui tip. Source: [strace-ui, Bonsai_term, and the TUI
  renaissance](janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `d95a47d`.
- Finalizer-based release ties large external resources to GC timing. **Action:** List C-backed
  handles in recorder and venue-net pages, noting explicit close versus finalizer. Source: [Using
  OxCaml to implement type-safe reference counting between OCaml and
  Python](janestreet/blog/2026-06-oxcaml-typesafe-reference-counting-python.md). Affects:
  [market-recorder](../repos/market-recorder.md), [venue-net](../repos/venue-net.md).
- Signatures are the unit of design and force interface thinking first. **Action:** Add a
  signature-first note for new venues to the oxcaml-claude-skills skills. Source: [Language
  Design](janestreet/podcast/07-language-design.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), [mm-core](../repos/mm-core.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `10588f3`.
- OCaml interfaces tend to be under-documented. **Action:** CI step dune build @doc with warnings as
  errors plus doc comments on exports, piloted. Source: [The Future of
  Programming](janestreet/podcast/16-future-of-programming.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
- Agents write better niche-language code when pointed at a corpus of real examples. **Action:**
  Give each skill a reference-modules list of 3-5 files from our repos showing the pattern in use.
  Source: [Why ML Needs a New Programming
  Language](janestreet/podcast/25-why-ml-needs-a-new-programming-language.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `0700b9a`.
- Learning goals as concrete action verbs give a check on whether teaching material works; skills
  teach agents. **Action:** Open each skill with 3-5 concrete outcomes and one small exercise per
  outcome to test a fresh agent session. Source: [Learning Goals and the Goals of Learning: Teaching
  in the Age of
  AI](janestreet/podcast/30-learning-goals-and-the-goals-of-learning-teaching-in-the-age-of-ai.md).
  Affects: [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `0700b9a`.

### Performance

29 insights, highest value first.

- No org benchmark exists, so allocation and speed claims are unmeasured. **Action:** Add a
  core_bench bench for submit/cancel on a 1000-level book in order-book with a README baseline.
  Source: [Core_bench: better micro-benchmarks through linear
  regression](janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `8c1bd24`.
- Memtrace samples allocations cheaply enough for production and finds leaks via time-window
  filters. **Action:** Verify memtrace works on 5.2.0+ox; if so call Memtrace.trace_if_requested at
  start of market-recorder run. Source: [Finding memory leaks with
  Memtrace](janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- A timeout that does not cancel leaves work running that fires all at once on recovery. **Action:**
  Audit every with_timeout in venue-net and the three clients; record abandoned-but-running cases in
  GOTCHAS.md. Source: [How recurring network maintenance exposed 6
  bugs](janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md). Affects:
  [venue-net](../repos/venue-net.md), [hl-client](../repos/hl-client.md),
  [binance-client](../repos/binance-client.md), [bybit-client](../repos/bybit-client.md),
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
- Words-per-run output makes allocation claims checkable. **Action:** Add a core_bench case for
  Quoter.quote in mm-core and record minor words per run. Source: [Core_bench: better
  micro-benchmarks through linear
  regression](janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `6bc0a3b`.
- GC cost must be measured before it can be shaped. **Action:** Add Gc.quick_stat collection counts
  and promoted words to Mm_core.Live.Report. Source: [Building a lower-latency
  GC](janestreet/blog/2015-04-building-a-lower-latency-gc.md). Affects:
  [mm-core](../repos/mm-core.md), [market-maker](../repos/market-maker.md).
- Long-running services need GC behaviour visible over time. **Action:** Export GC collection
  counters and heap words on market-recorder /metrics. Source: [Building a lower-latency
  GC](janestreet/blog/2015-04-building-a-lower-latency-gc.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- GC tuning must compare RSS across several space_overhead values, not one run or top_heap_size.
  **Action:** Document comparing OCAMLRUNPARAM o=40/80/160 on the recorder sims e2e by peak RSS and
  CPU time. Source: [Memory allocator
  showdown](janestreet/blog/2020-09-memory-allocator-showdown.md). Affects:
  [infra](../repos/infra.md), [market-recorder](../repos/market-recorder.md).
  **Done:** [infra](../repos/infra.md), commit `edd1c26`.
- Long Async cycles stall every feed in a single-threaded program; detect them first. **Action:**
  Export a count and max of Async cycles over 50 ms on market-recorder /metrics. Source:
  [Magic-trace: Diagnosing tricky performance issues easily with Intel Processor
  Trace](janestreet/blog/2022-01-magic-trace.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Local mode and exclave remove short-lived allocations like option results. **Action:** Measure
  Gc.minor_words for Order_book.best_bid/mid in an expect test; add local variants if non-zero.
  Source: [Oxidizing OCaml: Locality](janestreet/blog/2023-05-oxidizing-ocaml-locality.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `3cd731e`.
- Exporting immediacy lets the compiler treat int-backed types as non-pointers. **Action:** Mark
  Fixed_decimal.Make type t [@@immediate] and pin with an Obj.is_int test. Source: [ICFP
  2024](janestreet/blog/2024-08-icfp-2024.md). Affects: [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `6062921`.
- A publisher must never slow down for one slow consumer. **Action:** Test that a never-reading
  websocket subscriber does not delay other clients' order acks. Source: [Multicast and the
  Markets](janestreet/podcast/03-multicast-and-the-markets.md). Affects:
  [hl-sim](../repos/hl-sim.md).
  **Done:** [hl-sim](../repos/hl-sim.md), commit `d6cf920`.
- Hot paths can silently regain allocation; minor-heap words per op makes it visible. **Action:**
  ppx_expect test printing Gc.minor_words per submit/cancel over 10k cycles. Source: [Memory
  Management](janestreet/podcast/13-memory-management.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `3cd731e`.
- Headroom for 2-5x busy days requires a known per-pipeline ceiling. **Action:** Bench executable:
  raw minute file through normalizer and Event_log writer, print msgs/sec. Source: [Swapping the
  Engine Out of a Moving Race
  Car](janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Burst tails are queueing; batching when behind is the standard fix. **Action:** Drain pending book
  updates and quote once on the latest book. Source: [Performance Engineering on Hard
  Mode](janestreet/podcast/18-performance-engineering-on-hard-mode.md). Affects:
  [mm-core](../repos/mm-core.md).
- Tagged multiplication is several times slower than untagged. **Action:** Add a core_bench for
  fixed-decimal mul/div/Product.mul vs Int.( * ), confirming zero allocation. Source: [What is
  gained and lost with 63-bit
  integers?](janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `eb17dd1`.
- Optimizer gains (20-30% fewer allocations) only matter if allocation is measured. **Action:** Add
  a core_bench bench/ to order-book reporting time and allocated words for a seeded order batch.
  Source: [A better inliner for OCaml, and why it matters](janestreet/blog/2016-02-flambda.md).
  Affects: [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `8c1bd24`.
- Allocation-site profiling with backtraces finds leaks in long-running processes. **Action:** Add
  Memtrace.trace_if_requested at market-recorder startup. Source: [A brief trip through
  Spacetime](janestreet/blog/2017-01-a-brief-trip-through-spacetime.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Dynamic probes on a live binary answer questions logs cannot. **Action:** Add gotchas-log note on
  perf/bpftrace uprobes against OCaml symbols in the recorder container. Source: [Troubleshooting
  systemd with SystemTap](janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md).
  Affects: [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
- A stray per-packet allocation shows up as GC time in feed handlers. **Action:** Print
  Gc.minor_words per message in the binance-client Live_feed test. Source: [What the interns have
  wrought, 2022 edition](janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md). Affects:
  [binance-client](../repos/binance-client.md).
- Memtrace is the standard allocation profiler. **Action:** Call Memtrace.trace_if_requested in
  market-recorder startup. Source: [Developer education at Jane
  Street](janestreet/blog/2024-10-developer-education-at-jane-street.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- String round trips between I/O buffers can dominate allocation. **Action:** Benchmark allocation
  per frame in the on_raw to Raw_writer path and record it. Source: [A FUSE server for our in-house
  storage backend](janestreet/blog/2026-10-linux-engineering-depot-fuse.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Agent-run benchmark sweeps over several implementations beat intuition. **Action:** bench/
  executable timing submit and cancel on a synthetic book. Source: [Scaling and benchmarking a
  critical message bus using a new indexing
  strategy](janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `8c1bd24`.
- Tail latency, not the median, is what fails when markets are busy. **Action:** Record p50/p99/max
  book-update-to-executed-plan latency in Live.Report. Source: [Programmable
  Hardware](janestreet/podcast/01-programmable-hardware.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `0beaf15`.
- Single timing runs are dominated by layout noise; baselines need repeats and spread. **Action:**
  bench/ executable timing insert/cancel/match over a seeded stream with median and spread. Source:
  [Compiler Optimization](janestreet/podcast/04-compiler-optimization.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `8c1bd24`.
- Memory layout and safe stack allocation are the gaps OxCaml unboxed types and local_ now fill.
  **Action:** List hot-path records that would benefit from unboxed fields in the order-book README.
  Source: [Language Design](janestreet/podcast/07-language-design.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `1d68467`.
- Allocation profiles find hot-path allocation quickly. **Action:** Run memtrace on recorder during
  e2e-sims and record top 5 allocation sites. Source: [Performance Engineering on Hard
  Mode](janestreet/podcast/18-performance-engineering-on-hard-mode.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Profile first; consumers have a few microseconds per event to keep up. **Action:** Add core_bench
  of Binance Feed_normalizer over a recorded minute file reporting ns per frame. Source: [The
  Uncertain Art of Accelerating ML
  Models](janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md). Affects:
  [binance-client](../repos/binance-client.md).
- Optimization settings should be judged on real workloads. **Action:** Compare default release vs
  -O3 on the order-book bench and log result in GOTCHAS.md. Source: [Compiler
  Optimization](janestreet/podcast/04-compiler-optimization.md). Affects:
  [order-book](../repos/order-book.md), [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [order-book](../repos/order-book.md), commit `635788c`.
- OCaml 5 domains with local data-race freedom make parallelism safe to try. **Action:** Measure
  per-table day-close time in market-data and prototype a -jobs flag using domains if one table
  dominates. Source: [What Is an Operating
  System?](janestreet/podcast/12-what-is-an-operating-system.md). Affects:
  [market-data](../repos/market-data.md).

### Testing and simulation

57 insights, highest value first.

- Fakes that always behave hide caller bugs; bugification makes worst-allowed behaviour routine in
  tests. **Action:** Add a seeded bugify mode to the in-memory Venue.S test fake (rejects, delayed
  cancel acks, split fills, stale open-order polls). Source: [Why Testing is Hard and How to Fix
  it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `d2f0d7a`.
- Boundary-biased generators find overflow and rounding bugs example tests miss. **Action:** Add
  Base_quickcheck round-trip and Product.mul reference tests near the 63-bit range ends. Source:
  [Quickcheck for Core](janestreet/blog/2015-10-quickcheck-for-core.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `c17ff35`.
- Bisimulation against a naive reference finds semantic gaps invariant checks miss. **Action:** Add
  Base_quickcheck test comparing Order_book fills with a naive sorted-list matcher on random op
  sequences. Source: [What the interns have wrought, 2020
  edition](janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `834fb9f`.
- Record/replay modes make data-dependent code cheap to test against real inputs. **Action:** Add
  HTTP record mode to venue-net saving request/response fixtures, plus hl-client expect test
  decoding a recorded real info response. Source: [What the interns have wrought, 2021
  edition](janestreet/blog/2021-08-what-the-interns-have-wrought-2021.md). Affects:
  [venue-net](../repos/venue-net.md), [hl-client](../repos/hl-client.md).
- Raw frames we already record can serve as real-venue parser fixtures. **Action:** Add
  binance-client expect test feeding one recorded raw minute file through Live_feed parser and
  printing per-stream counts. Source: [What the interns have wrought, 2021
  edition](janestreet/blog/2021-08-what-the-interns-have-wrought-2021.md). Affects:
  [binance-client](../repos/binance-client.md), [market-recorder](../repos/market-recorder.md).
- Bisimulation of an optimized structure against a slow reference via random operation sequences.
  **Action:** Add a quickcheck bisimulation test of Order_book against a naive list-based reference
  book. Source: [What the interns have wrought, 2022
  edition](janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `834fb9f`.
- Randomized market-event sequences with shrinking test trading loops better than scenarios.
  **Action:** Add a Base_quickcheck event-sequence test through Live.Make asserting the position
  limit. Source: [What the interns have wrought, 2025
  edition](janestreet/blog/2025-08-wrought-2025.md). Affects: [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `c3499eb`.
- Whole-system testing needs only images, a compose file and a folder of action scripts. **Action:**
  test-actions/ directory of executable chaos actions against the compose stack. Source: [Getting
  from tested to battle-tested](janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md).
  Affects: [infra](../repos/infra.md).
  **Done:** [infra](../repos/infra.md), commit `c68a5b6`.
- Version-skew tests catch writer/reader incompatibilities. **Action:** Check in an event log
  written by current code and test future versions still read it. Source: [Getting from tested to
  battle-tested](janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `dfd512d`.
- Deterministic network and time simulation is the most valuable test layer. **Action:** Time_source
  parameter for Ws_client backoff and watchdog, tested with a synthetic clock. Source: [Getting from
  tested to battle-tested](janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md).
  Affects: [venue-net](../repos/venue-net.md).
  **Done:** [venue-net](../repos/venue-net.md), commit `d74343c`.
- Failure paths can be forced without real outages (rlimits, LD_PRELOAD, one-thread pool).
  **Action:** Expect test: Ws_client.connect to a listener that never completes the handshake; check
  timeout and FD count restored. Source: [How recurring network maintenance exposed 6
  bugs](janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md). Affects:
  [venue-net](../repos/venue-net.md).
  **Done:** [venue-net](../repos/venue-net.md), commit `3397fd9`.
- Captured real traffic is the best codec test data, and the recorder already stores frames
  verbatim. **Action:** Check a trimmed raw minute file into hl-protocol tests; expect test decodes
  every frame, prints counts per channel and errors. Source: [A FUSE server for our in-house storage
  backend](janestreet/blog/2026-10-linux-engineering-depot-fuse.md). Affects:
  [hl-protocol](../repos/hl-protocol.md), [market-recorder](../repos/market-recorder.md).
- Research and production in different toolsets causes porting pain; our strategy is pure OCaml so
  we can avoid it. **Action:** Expect test driving Mm_core.Strategy from Replay_feed over a fixture
  event log and printing quotes. Source: [Finding Signal in the
  Noise](janestreet/podcast/22-finding-signal-in-the-noise.md). Affects:
  [mm-core](../repos/mm-core.md), [market-data](../repos/market-data.md).
- Engine invariants checked on every step are cheap, strong properties for a deterministic
  simulator. **Action:** Base_quickcheck test of random place/cancel/step sequences on Exchange
  asserting zero net position, uncrossed book, unique order ids. Source: [Why Testing is Hard and
  How to Fix it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
  [exchange-core](../repos/exchange-core.md).
  **Done:** [exchange-core](../repos/exchange-core.md), commit `9fab05b`.
- A failing random run is only useful if it replays exactly. **Action:** Run the Live.Make test on a
  synthetic Async Time_source and print the seed on failure. Source: [Why Testing is Hard and How to
  Fix it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `c3499eb`.
- Shape distributions around thresholds where behaviour changes. **Action:** Add an order-book
  Quickcheck generator drawing prices within 3 ticks of mid, checking invariants each step. Source:
  [Quickcheck for Core](janestreet/blog/2015-10-quickcheck-for-core.md). Affects:
  [order-book](../repos/order-book.md).
- Default generators belong next to their types. **Action:** Derive quickcheck on market-data
  Stable.V1 records and test bin_io round trips. Source: [Quickcheck for
  Core](janestreet/blog/2015-10-quickcheck-for-core.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `e2af09c`.
- E2E scripts that only print evidence pass when nothing happened. **Action:** Make market-recorder
  scripts/e2e-sims.sh exit non-zero when no raw .zst files were written. Source: [When Bash Scripts
  Bite](janestreet/blog/2017-05-when-bash-scripts-bite.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- A bug fix is most convincing as a test exhibiting the bug, then the fix. **Action:** Add
  two-commit bug-fix rule to the oxcaml-claude-skills testing skill. Source: [Ironing out your
  development style](janestreet/blog/2017-08-ironing-out-your-development-style.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `10588f3`.
- Bounded-integer arithmetic must be checked against an exact model, not hand-picked cases.
  **Action:** Base_quickcheck property comparing fixed-decimal mul_units/div_units with a Bigint
  reference. Source: [Proofs (and Refutations) using
  Z3](janestreet/blog/2018-02-proofs-and-refutations-using-z3.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md), commit `c17ff35`.
- Expect tests over checked-in real captures catch venue quirks hand-written samples miss.
  **Action:** Check a real Hyperliquid raw minute excerpt into hl-client tests and expect-test
  decoding every line. Source: [Repeatable exploratory
  programming](janestreet/blog/2018-04-repeatable-exploratory-programming.md). Affects:
  [hl-client](../repos/hl-client.md), [hl-protocol](../repos/hl-protocol.md),
  [market-recorder](../repos/market-recorder.md).
- Domain randomization of simulator parameters guards a strategy against overfitting one sim config.
  **Action:** Add Market_sim.Config.randomize ~seed drawing vol_bps, probabilities and
  max_offset_bps from ranges, with reproducibility expect test. Source: [Thoughts from AAAI
  2019](janestreet/blog/2019-05-thoughts-from-aaai-19.md). Affects:
  [exchange-core](../repos/exchange-core.md), [market-maker](../repos/market-maker.md).
  **Done:** [exchange-core](../repos/exchange-core.md), commit `7fa9e7a`.
- Diffing bytes against an independent reference implementation in expect tests finds bugs on both
  sides. **Action:** When Hyperliquid EIP-712 signing lands, add expect test checking a fixed order
  signature against a vector from the official Python SDK. Source: [What the interns have wrought,
  2019 edition](janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md). Affects:
  [hl-client](../repos/hl-client.md).
- Time series rendered as aligned text in expect tests are reviewable at a glance. **Action:** Add
  mm-core test helper printing mid/bid/ask/position per step and one expect test over a scripted
  price path. Source: [Using ASCII waveforms to test hardware
  designs](janestreet/blog/2020-06-using-ascii-waveforms-to-test-hardware-designs.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `0394609`.
- Venue adapters over one engine should agree on fills for the same orders. **Action:** Add script
  next to e2e-all.sh sending one scripted order sequence to hl-sim and binance-sim with noise off
  and diffing normalized fills. Source: [What the interns have wrought, 2020
  edition](janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md). Affects:
  [market-maker](../repos/market-maker.md), [hl-sim](../repos/hl-sim.md),
  [binance-sim](../repos/binance-sim.md).
- Snapshot tests over real recorded data are missing; per-module expect tests exist. **Action:** Add
  a binance-client expect test feeding a recorded raw minute fixture through Feed_normalizer and
  Local_book. Source: [What if writing tests was a joyful
  experience?](janestreet/blog/2023-01-the-joy-of-expect-tests.md). Affects:
  [binance-client](../repos/binance-client.md), [market-recorder](../repos/market-recorder.md).
- A deterministic engine plus an input log makes simulator incidents replayable. **Action:** Log
  accepted hl-sim /exchange requests and test that replay into a fresh engine gives identical fills.
  Source: [What the interns have wrought, 2024
  edition](janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md). Affects:
  [hl-sim](../repos/hl-sim.md), [exchange-core](../repos/exchange-core.md).
  **Done:** [hl-sim](../repos/hl-sim.md), commit `5028321`.
- Async.Time_source makes time-dependent code testable; venue-net backoff/watchdog use wall clock.
  **Action:** Add ?time_source to Venue_net.Ws_client.connect with a synthetic-time reconnect expect
  test. Source: [Developer education at Jane
  Street](janestreet/blog/2024-10-developer-education-at-jane-street.md). Affects:
  [venue-net](../repos/venue-net.md).
  **Done:** [venue-net](../repos/venue-net.md), commit `d74343c`.
- Live loop timers should run on a synthetic clock in tests. **Action:** Thread Time_source.t
  through Live.Make and convert one live-loop test. Source: [Developer education at Jane
  Street](janestreet/blog/2024-10-developer-education-at-jane-street.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `ea16ba1`.
- Fuzzing bytes into state-machine inputs finds unsafe states. **Action:** Base_quickcheck test
  mapping random bytes to book operations with invariant check after each. Source: [Getting from
  tested to battle-tested](janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md).
  Affects: [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `3e5f224`.
- Effects make lockstep multi-actor simulations straight-line code. **Action:** Handled_effect
  expect-test harness: scripted traders call step, runner calls Exchange.step per round (check
  switch support first). Source: [Fun with Algebraic Effects - from Toy Examples to Hardcaml
  Simulations](janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md). Affects:
  [exchange-core](../repos/exchange-core.md).
- Properties stated once serve as tests now and proof targets later. **Action:** Base_quickcheck
  property running the book invariant check after random submit and cancel sequences. Source:
  [Formal methods and the future of
  programming](janestreet/blog/2026-06-formal-methods-at-jane-street.md). Affects:
  [order-book](../repos/order-book.md).
- Trade share, inter-arrival point masses and price clustering are cheap realism metrics.
  **Action:** DuckDB query for trade share and BBO inter-arrival histogram, run on live Hyperliquid
  and hl-sim hours. Source: [Can you use autoregressive diffusion to generate market
  data?](janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md).
  Affects: `specs`, [market-data](../repos/market-data.md), [hl-sim](../repos/hl-sim.md).
- Shared simulator semantics hide venue-specific differences. **Action:** Per-venue simulator expect
  tests pinning documented behaviour, starting with a crossing post-only order. Source: [What the
  TDOE interns have wrought, 2026 edition](janestreet/blog/2026-09-tdoe-intern-projects-2026.md).
  Affects: [hl-sim](../repos/hl-sim.md), [binance-sim](../repos/binance-sim.md),
  [bybit-sim](../repos/bybit-sim.md).
- Shadow-run a new decision engine beside the old one and diff typed decisions to find bugs in both.
  **Action:** Expect test running Strategy under two Params over one scripted sequence, printing
  only differing Action plans. Source: [Building and testing a config management orchestrator for
  Windows](janestreet/blog/2026-10-config-management-orchestrator-for-windows.md). Affects:
  [mm-core](../repos/mm-core.md).
- Golden recorded-frame tests belong in every venue codec. **Action:** Same recorded-minute decode
  test for Binance and Bybit. Source: [A FUSE server for our in-house storage
  backend](janestreet/blog/2026-10-linux-engineering-depot-fuse.md). Affects:
  [binance-protocol](../repos/binance-protocol.md), [bybit-protocol](../repos/bybit-protocol.md).
- Randomize internal layout choices in property tests to prove outputs do not depend on them.
  **Action:** Property test writing identical events with random Framed buffer and flush sizes,
  checking identical read-back. Source: [Scaling and benchmarking a critical message bus using a new
  indexing strategy](janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md).
  Affects: [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `ab73d96`.
- A miscompilation was caught only by a rarely run test; our e2e scripts run by hand. **Action:**
  Weekly scheduled CI workflow running scripts/e2e-all.sh. Source: [Compiler
  Optimization](janestreet/podcast/04-compiler-optimization.md). Affects:
  [market-maker](../repos/market-maker.md).
- Run old and new versions on identical input and diff outputs before switching. **Action:** Add
  scripts/diff-day-close.sh in market-data diffing day-close tables of two revisions with DuckDB
  EXCEPT. Source: [Building a functional email
  server](janestreet/podcast/08-building-a-functional-email-server.md). Affects:
  [market-data](../repos/market-data.md).
- Swappable implementations let parsing be tested on recorded data without sockets. **Action:** Add
  an hl-client expect test feeding checked-in recorded frames through Live_feed normalize. Source:
  [What Is an Operating System?](janestreet/podcast/12-what-is-an-operating-system.md). Affects:
  [hl-client](../repos/hl-client.md).
- Broken non-production copies are the best incident training; our simulators make one cheap.
  **Action:** Add a fault phase to scripts/e2e-all.sh that restarts the simulator mid-run and checks
  reconnect, resync and quoting. Source: [Solving Puzzles in
  Production](janestreet/podcast/20-solving-puzzles-in-production.md). Affects:
  [market-maker](../repos/market-maker.md), [hl-sim](../repos/hl-sim.md),
  [binance-sim](../repos/binance-sim.md), [bybit-sim](../repos/bybit-sim.md).
- A property-test counterexample found once should rerun forever; no property passes ~examples.
  **Action:** Pass ~examples with a multi-level sweep edge case to properties in
  test/test_order_book.ml. Source: [Building Tools for
  Traders](janestreet/podcast/23-building-tools-for-traders.md). Affects:
  [order-book](../repos/order-book.md).
  **Done:** [order-book](../repos/order-book.md), commit `421fa07`.
- Printing whole state makes expect-test diffs explain failures. **Action:** Expect test running
  seeded Market_sim a few steps, printing top 5 levels per side and positions each step. Source:
  [Building Tools for Traders](janestreet/podcast/23-building-tools-for-traders.md). Affects:
  [exchange-core](../repos/exchange-core.md).
  **Done:** [exchange-core](../repos/exchange-core.md), commit `e69830a`.
- Paging-level alerts are ready-made test properties. **Action:** Test running the recorder against
  hl-sim asserting /metrics alert conditions (closed minute files non-empty, recv_ts non-decreasing
  per file). Source: [Why Testing is Hard and How to Fix
  it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
  [market-recorder](../repos/market-recorder.md), [hl-sim](../repos/hl-sim.md).
- Agents under a strict validator delete or weaken tests. **Action:** Add a skill rule and GOTCHAS
  entry: commits removing tests or accepting changed expect output must say why. Source: [Why
  Testing is Hard and How to Fix
  it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
  [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `10588f3`.
- Cram-style tests diff CLI behavior; we have none. **Action:** Add dune cram test running
  market-data day-close on a tiny event log. Source: [Testing with
  expectations](janestreet/blog/2015-12-testing-with-expectations.md). Affects:
  [market-data](../repos/market-data.md).
- Replayed market data reads best as aligned columns per event. **Action:** Add market-data expect
  test replaying a small event log printing best bid, best ask, last trade per event. Source: [Using
  ASCII waveforms to test hardware
  designs](janestreet/blog/2020-06-using-ascii-waveforms-to-test-hardware-designs.md). Affects:
  [market-data](../repos/market-data.md).
- Record real external responses once and replay them in tests. **Action:** Check in recorded
  Hyperliquid l2Book and clearinghouseState fixtures with decode expect tests. Source: [What the
  interns have wrought, 2022
  edition](janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md). Affects:
  [hl-protocol](../repos/hl-protocol.md).
- Margin and liquidation formulas have branches final-value tests miss. **Action:** Add an
  exchange-core expect test printing per-position maintenance margin terms around a liquidation.
  Source: [Computations that differentiate, debug, and document
  themselves](janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md).
  Affects: [exchange-core](../repos/exchange-core.md).
- Reply/retry matching bugs only appear under high latency; simulators answer instantly. **Action:**
  Add -response-delay-ms to hl-sim and run the hl-mm live-loop test under it. Source: [A
  Higgs-bugson in the Linux Kernel](janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md).
  Affects: [hl-sim](../repos/hl-sim.md), [hl-mm](../repos/hl-mm.md).
- Text screenshot expect tests let agents verify UI work themselves. **Action:** Prototype read-only
  Bonsai_term status screen with one rendered-screen expect test. Source: [strace-ui, Bonsai_term,
  and the TUI
  renaissance](janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md). Affects:
  [market-maker](../repos/market-maker.md).
- Random-walk noise traders lack the lumpiness of real flow (pennying, bursts). **Action:**
  Market_sim option placing a share of noise orders one tick inside the touch; compare histograms.
  Source: [Can you use autoregressive diffusion to generate market
  data?](janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md).
  Affects: [exchange-core](../repos/exchange-core.md).
  **Done:** [exchange-core](../repos/exchange-core.md), commit `ce7fd35`.
- Testing at maximum input rate shows where a system falls behind; the recorder was never saturated.
  **Action:** Back-to-back replay load test printing frames/s and max queue depth. Source:
  [Programmable Hardware](janestreet/podcast/01-programmable-hardware.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Per-tick textual traces (ASCII waveform idea) make state machine changes reviewable as diffs.
  **Action:** Expect test printing one line per tick for 20 ticks of a seeded Market_sim. Source:
  [Programmable Hardware](janestreet/podcast/01-programmable-hardware.md). Affects:
  [exchange-core](../repos/exchange-core.md).
  **Done:** [exchange-core](../repos/exchange-core.md), commit `e69830a`.
- Example configs rot unless the build parses them. **Action:** Add an expect test in
  market-recorder parsing every examples/ file with Config.of_sexp. Source: [Building a functional
  email server](janestreet/podcast/08-building-a-functional-email-server.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Whole-pipeline in-code tests replaced manual diffing and enabled frequent releases. **Action:**
  Run scripts/e2e-sims.sh in market-recorder CI if not already. Source: [Swapping the Engine Out of
  a Moving Race Car](janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md).
  Affects: [market-recorder](../repos/market-recorder.md).
- A realistic testbed answering in minutes speeds performance work. **Action:** e2e-all.sh prints
  per-venue tick-to-order histogram. Source: [Performance Engineering on Hard
  Mode](janestreet/podcast/18-performance-engineering-on-hard-mode.md). Affects:
  [market-maker](../repos/market-maker.md).

### Research tooling

11 insights, highest value first.

- Tested, reviewable transformations catch bad data at each stage. **Action:** Add market-data check
  running fixed DuckDB assertions (no crossed BBO, positive sizes, monotonic recv_ts, no empty
  minutes on liquid symbols) after day-close. Source: [Wrestling the world into
  rows](janestreet/podcast/29-wrestling-the-world-into-rows.md). Affects:
  [market-data](../repos/market-data.md), [infra](../repos/infra.md).
- Python research reaches our data via Parquet; the risk is TIMESTAMP_NS and DECIMAL type fidelity.
  **Action:** Add step to market-data e2e script loading a day-close table with pyarrow and
  asserting ns timestamps and decimal prices. Source: [Using Python and OCaml in the same Jupyter
  notebook](janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md).
  Affects: [market-data](../repos/market-data.md).
- Usage logs show who reads what before a table or column is changed. **Action:** Make market-data
  query append UTC time, user and SQL text to query-log.ndjson in the data dir (opt-out flag).
  Source: [Building a data warehouse from
  scratch](janestreet/podcast/28-building-a-data-warehouse-from-scratch.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `7095d58`.
- Committed expect tests turn one-off data checks into rerunnable notebooks. **Action:** Expect test
  running candle aggregation over a small real event log fixture in market-data. Source: [Repeatable
  exploratory programming](janestreet/blog/2018-04-repeatable-exploratory-programming.md). Affects:
  [market-data](../repos/market-data.md).
- Time_ns conversion is a known pain point at the language boundary. **Action:** Document in
  market-data README how exch_ts/recv_ts map to pandas datetime64[ns, UTC] with one example query.
  Source: [Using Python and OCaml in the same Jupyter
  notebook](janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md).
  Affects: [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `374c6b5`.
- Natural-language-to-SQL needs ground-truth examples over the real schema. **Action:** Specs page
  of example DuckDB queries over market-data views with column notes. Source: [I design with Claude
  more than Figma now](janestreet/blog/2026-02-i-design-with-claude-code-more-than-figma-now.md).
  Affects: `specs`, [market-data](../repos/market-data.md).
  **Done:** [example queries](../design/queries.md).
- A TUI over recorded data is a cheap first viewer. **Action:** Prototype subcommand paging through
  one Event_log file in Bonsai_term. Source: [strace-ui, Bonsai_term, and the TUI
  renaissance](janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md). Affects:
  [market-data](../repos/market-data.md).
- Researchers should reach data without learning our OCaml code. **Action:** examples/query.py
  loading one day of trades via DuckDB views into pandas. Source: [Python, OCaml, and Machine
  Learning](janestreet/podcast/05-python-ocaml-and-machine-learning.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `26749c2`.
- Seeing intermediate values next to inputs makes analysis tools effective. **Action:** Add a DuckDB
  view in market-data joining BBO and trades on time buckets. Source: [Building a UI
  Framework](janestreet/podcast/11-building-a-ui-framework.md). Affects:
  [market-data](../repos/market-data.md).
  **Done:** [market-data](../repos/market-data.md), commit `4a55541`.
- Declaring a document's genre helps readers navigate it. **Action:** Add a Kind header convention
  to the specs CLAUDE.md and apply it to design/ pages. Source: [Writing,
  Technically](janestreet/podcast/10-writing-technically.md). Affects: `specs`.
  **Done:** `specs` [CLAUDE.md](../CLAUDE.md).
- Experts want all state on one dense keyboard-driven screen; recorder only offers machine-oriented
  Prometheus text. **Action:** Add market-recorder status -url subcommand printing a dense per
  venue/stream/symbol table from /metrics. Source: [From the Lab to the Trading Floor: Designing for
  Expert Users](janestreet/podcast/19-from-the-lab-to-the-trading-floor.md). Affects:
  [market-recorder](../repos/market-recorder.md).

### Build and deploy

34 insights, highest value first.

- OxCaml extensions have no stability promise; CI pulls the ox repo unpinned while the base image
  pins it. **Action:** Pin the ox opam repository to the base image's commit in every CI workflow.
  Source: [Introducing OxCaml](janestreet/blog/2025-06-introducing-oxcaml.md). Affects:
  [infra](../repos/infra.md), [fixed-decimal](../repos/fixed-decimal.md).
- Per-repo green CI hides downstream breakage after upstream pushes. **Action:** Add a nightly
  market-maker workflow pinning every upstream repo at main. Source: [Making “never break the build”
  scale](janestreet/blog/2014-07-making-never-break-the-build-scale.md). Affects:
  [market-maker](../repos/market-maker.md).
- CI gates are only as good as their pins. **Action:** Add parquet and market-data to the CI pin
  order of hl-mm and market-maker. Source: [Making “never break the build”
  scale](janestreet/blog/2014-07-making-never-break-the-build-scale.md). Affects:
  [hl-mm](../repos/hl-mm.md), [market-maker](../repos/market-maker.md).
  **Done:** [hl-mm](../repos/hl-mm.md).
- First question for a misbehaving deployment is which binary is running. **Action:** Add
  market_recorder_build_info gauge (version, executable hash) to /metrics with an expect test.
  Source: [This is not the performance you were looking for: the tricks systems play on
  us](janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md).
  Affects: [market-recorder](../repos/market-recorder.md).
- A bounded queue filling under a burst should be visible before it fails. **Action:** Export length
  of each Recorder pipe into Norm_writer as a /metrics gauge. Source: [Troubleshooting systemd with
  SystemTap](janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Container memory limits act on RSS, which differs from Gc.stat heap figures. **Action:** Export
  process RSS from /proc/self/statm on /metrics. Source: [Memory allocator
  showdown](janestreet/blog/2020-09-memory-allocator-showdown.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- A central 'who has not checked in' query beats probing each instance. **Action:** Per-stream
  last_message_age_seconds gauge in recorder /metrics. Source: [Building and testing a config
  management orchestrator for
  Windows](janestreet/blog/2026-10-config-management-orchestrator-for-windows.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Resource limits set by the launcher can silently change. **Action:** Log RLIMIT_NOFILE at recorder
  startup and export open FD count in /metrics. Source: [How recurring network maintenance exposed 6
  bugs](janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Hand-copied build logic drifts; CI pin lines are duplicated and already missing pins. **Action:**
  Script deriving pin order from dune-project files that fails on a missing ci.yml pin. Source:
  [Build Systems](janestreet/podcast/02-build-systems.md). Affects: [infra](../repos/infra.md).
  **Done:** [infra](../repos/infra.md), commit `7644ebf`.
- Flickering alerts that open and close with no action are the main noise signal. **Action:** Add
  healthz_flaps_total per-stream counter of 200/503 transitions to Metrics. Source: [Solving Puzzles
  in Production](janestreet/podcast/20-solving-puzzles-in-production.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- No single hash identifies the multi-repo system under test. **Action:** Print every sibling repo
  HEAD at the start of scripts/e2e-all.sh. Source: [Iron out your release
  process](janestreet/blog/2014-06-ironing-out-your-release-process.md). Affects:
  [market-maker](../repos/market-maker.md).
- Deployed images should record the commits they contain. **Action:** Set
  org.opencontainers.image.revision and per-sibling commit labels on infra images. Source: [Iron out
  your release process](janestreet/blog/2014-06-ironing-out-your-release-process.md). Affects:
  [infra](../repos/infra.md).
  **Done:** [infra](../repos/infra.md), commit `91ea264`.
- Ss -tipn separates a slow peer from a slow consumer on stalled feeds. **Action:** Add an ss -tipn
  troubleshooting section to infra deployment notes. Source: [Inspecting Internal TCP State on
  Linux](janestreet/blog/2014-07-inspecting-internal-tcp-state-on-linux.md). Affects:
  [infra](../repos/infra.md), [market-recorder](../repos/market-recorder.md).
  **Done:** [infra](../repos/infra.md), commit `ae922dd`.
- Loading every shipped example config in tests guards against config drift. **Action:** Expect test
  parsing market-recorder examples/sims.sexp and printing the config. Source: [Caveat Configurator:
  how to replace configs with code, and why you might not want
  to](janestreet/blog/2017-04-caveat-configurator-how-to-replace-configs-with-code-and-why-you-might-not-want-to.md).
  Affects: [market-recorder](../repos/market-recorder.md).
- VM hosts drift in kernel, clock and uptime; checks belong in the deployment plan. **Action:** Add
  a host checks list to the AWS target section of specs design/deployment.md. Source: [This is not
  the performance you were looking for: the tricks systems play on
  us](janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md).
  Affects: `specs`, [infra](../repos/infra.md).
- Set -e is masked by local/export/echo around substitutions; shellcheck flags this. **Action:** Add
  shellcheck to infra CI, then market-maker, hl-mm, market-recorder script dirs. Source: [When Bash
  Scripts Bite](janestreet/blog/2017-05-when-bash-scripts-bite.md). Affects:
  [infra](../repos/infra.md), [market-maker](../repos/market-maker.md), [hl-mm](../repos/hl-mm.md),
  [market-recorder](../repos/market-recorder.md).
- Env-var-driven tracing needs no rebuild in deployed containers. **Action:** Add commented MEMTRACE
  env and writable trace path to recorder Helm values once memtrace confirmed. Source: [Finding
  memory leaks with Memtrace](janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md).
  Affects: [infra](../repos/infra.md).
- A deployment should be exactly one set of code revisions. **Action:** Record built repo and pinned
  sibling commits as a label and file in infra service images. Source: [Building reproducible Python
  environments with
  XARs](janestreet/blog/2023-04-building-reproducible-python-environments-with-xars.md). Affects:
  [infra](../repos/infra.md).
  **Done:** [infra](../repos/infra.md), commit `91ea264`.
- Immutable stable tags versus rolling nightly; we deploy latest. **Action:** Tag service images by
  commit and reference explicit tags in Helm default values. Source: [Building reproducible Python
  environments with
  XARs](janestreet/blog/2023-04-building-reproducible-python-environments-with-xars.md). Affects:
  [infra](../repos/infra.md).
  **Done:** [infra](../repos/infra.md), commit `b23f858`.
- Dune's big wins come from cache hits; our CI rebuilds from scratch. **Action:** Enable dune-cache
  in setup-ocaml for order-book CI, measure, roll out. Source: [How we accidentally built a better
  build system for
  OCaml](janestreet/blog/2025-01-how-we-accidentally-built-a-better-build-system-for-ocaml.md).
  Affects: [order-book](../repos/order-book.md).
- A hash-keyed shared cache removes repeated work; CI rebuilds all siblings each push. **Action:**
  Set dune-cache: true on setup-ocaml, compare job times, roll out. Source: [Build
  Systems](janestreet/podcast/02-build-systems.md). Affects: [hl-sim](../repos/hl-sim.md).
- Caching needs deterministic inputs, but CI pins siblings at moving branch heads. **Action:** CI
  step printing opam pin list with resolved commit hashes. Source: [Build
  Systems](janestreet/podcast/02-build-systems.md). Affects:
  [market-maker](../repos/market-maker.md).
- Compiler changes should arrive deliberately; CI follows the moving ox opam repo. **Action:** Pin
  the ox repository to the base image's commit in CI, starting with fixed-decimal. Source: [Compiler
  Optimization](janestreet/podcast/04-compiler-optimization.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md), [infra](../repos/infra.md).
- Sync quality depends on configuration not yet specified for AWS. **Action:** Document chrony with
  Amazon Time Sync and a chronyc tracking bootstrap check in docs/aws.md. Source: [Clock
  Synchronization](janestreet/podcast/06-clock-synchronization.md). Affects:
  [infra](../repos/infra.md).
- Doc code blocks compiled by the build cannot silently drift from the API. **Action:** Add an mdx
  stanza to fixed-decimal so README examples run under dune runtest. Source: [Writing,
  Technically](janestreet/podcast/10-writing-technically.md). Affects:
  [fixed-decimal](../repos/fixed-decimal.md).
  **Done:** [fixed-decimal](../repos/fixed-decimal.md) (README blocks checked by `test_readme.ml`;
  mdx is not available), commit `a20c749`.
- GC is a single space/time dial; a long-running service should expose where it sits. **Action:**
  Gc.quick_stat gauges (heap words, minor/major counts) in /metrics. Source: [Memory
  Management](janestreet/podcast/13-memory-management.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Applications that expose internal state make support automation easy. **Action:** Add GET /status
  sexp endpoint with open minute files and uploader pending queue. Source: [Solving Puzzles in
  Production](janestreet/podcast/20-solving-puzzles-in-production.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Own fine-grained sensors notice trouble before the provider does. **Action:** Expose per-stream
  gauge of latest recv_ts - exch_ts on /metrics. Source: [The Thermodynamics of
  Trading](janestreet/podcast/24-the-thermodynamics-of-trading.md). Affects:
  [market-recorder](../repos/market-recorder.md).
- Per-agent build dirs could reuse artifacts through dune's shared cache. **Action:** Confirm and
  document the shared dune cache setting for the local workspace. Measured: it does not; a
  different `DUNE_BUILD_DIR` recompiles everything, so reuse one build directory per
  repository. Source: [How we accidentally built
  a better build system for
  OCaml](janestreet/blog/2025-01-how-we-accidentally-built-a-better-build-system-for-ocaml.md).
  Affects: [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md).
  **Done:** [oxcaml-claude-skills](../repos/oxcaml-claude-skills.md), commit `d95a47d`.
- Proctopus manages multi-process local setups. **Action:** Try proctopus for three sims plus
  market-maker and recorder; note result. Source: [strace-ui, Bonsai_term, and the TUI
  renaissance](janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md). Affects:
  [infra](../repos/infra.md).
- Cached service discovery keeps a process working through DNS or config outages. **Action:**
  Document whether the upload command depends on DNS and what happens to upload-pending.sexp during
  a DNS outage. Source: [A resilient kernel log
  reporter](janestreet/blog/2026-10-linux-engineering-kernel-reporter.md). Affects:
  [infra](../repos/infra.md), [market-recorder](../repos/market-recorder.md).
  **Done:** [infra](../repos/infra.md), commit `ae922dd`.
- Time set aside for recurring toil pays back in delivery. **Action:** Pin parquet and market-data
  in hl-mm and market-maker CI. Source: [A Poet's Guide to Product
  Management](janestreet/podcast/17-a-poets-guide-to-product-management.md). Affects:
  [hl-mm](../repos/hl-mm.md), [market-maker](../repos/market-maker.md).
  **Done:** [hl-mm](../repos/hl-mm.md).
- Blameless postmortems with timeline and concrete actions turn incidents into fixes. **Action:**
  Add a postmortem template under postmortems/ in specs. Source: [Solving Puzzles in
  Production](janestreet/podcast/20-solving-puzzles-in-production.md). Affects: `specs`.
  **Done:** `specs` [postmortems/](../postmortems/TEMPLATE.md).
- Maintenance mistakes come from improvising under pressure; write procedures beforehand.
  **Action:** Write step-by-step runbook for upgrading the recorder Helm release. Source: [The
  Thermodynamics of Trading](janestreet/podcast/24-the-thermodynamics-of-trading.md). Affects:
  [infra](../repos/infra.md).
  **Done:** [infra](../repos/infra.md), commit `5cf68f5`.

### Market making and trading systems

22 insights, highest value first.

- A too-aggressive market maker never crashes, so quoting and inventory properties must be explicit.
  **Action:** Base_quickcheck test driving Strategy with random events over seeds: quotes never
  cross, stay ordered, cannot exceed max_position if all fill. Source: [Why Testing is Hard and How
  to Fix it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `c3499eb`.
- Order flags with the same name can mean different things per venue. **Action:** Table in
  simulators design page mapping each Tif and market slippage handling to each venue's wire value
  and semantics. Source: [What the TDOE interns have wrought, 2026
  edition](janestreet/blog/2026-09-tdoe-intern-projects-2026.md). Affects: `specs`,
  [exchange-core](../repos/exchange-core.md).
  **Done:** [simulators design](../design/simulators.md#time-in-force-and-market-orders).
- Many feeds in one process reconnect in lockstep after a partition (thundering herd). **Action:**
  Add random jitter to Ws_client exponential backoff and log the chosen delay. Source: [How
  recurring network maintenance exposed 6
  bugs](janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md). Affects:
  [venue-net](../repos/venue-net.md).
  **Done:** [venue-net](../repos/venue-net.md), commit `64cbb4a`.
- Problem-solver apps that fail to update state re-send forever. **Action:** Quickcheck property:
  reconciling after applying a plan yields only Keep. Source: [State Machine Replication, and Why
  You Should Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md).
  Affects: [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `7dc8b57`.
- Without tick-to-order measurement a deferred send goes unnoticed. **Action:**
  recv_ts-to-order-send histogram in Live.Make, p50/p99/max logged at shutdown. Source: [Performance
  Engineering on Hard Mode](janestreet/podcast/18-performance-engineering-on-hard-mode.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `0beaf15`.
- One oversized liquidationPx discards a whole Hyperliquid snapshot. **Action:** Decode
  liquidationPx in hl-protocol as an option that is None when out of range. Source: [What is gained
  and lost with 63-bit
  integers?](janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md). Affects:
  [hl-protocol](../repos/hl-protocol.md), [hl-mm](../repos/hl-mm.md).
- A stalled Async cycle in the quoting loop means stale quotes. **Action:** Log a warning from the
  market-maker binary when an Async cycle exceeds 20 ms. Source: [Magic-trace: Diagnosing tricky
  performance issues easily with Intel Processor Trace](janestreet/blog/2022-01-magic-trace.md).
  Affects: [market-maker](../repos/market-maker.md).
- Printing every intermediate term of a formula catches bugs the final value hides. **Action:** Add
  Quoter.For_testing.explain tree printer in mm-core with one expect test. Source: [Computations
  that differentiate, debug, and document
  themselves](janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md).
  Affects: [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `25a06bf`.
- Per-tick quoter allocation decides whether locality is worth adopting. **Action:** Add an mm-core
  expect test printing minor words per quote computation. Source: [Oxidizing OCaml:
  Locality](janestreet/blog/2023-05-oxidizing-ocaml-locality.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `0390fef`.
- Immediate retries on ambiguous errors can self-amplify; late acks must be adopted not duplicated.
  **Action:** Add an mm-core expect test where a timed-out place later appears and is adopted by
  cloid. Source: [A Higgs-bugson in the Linux
  Kernel](janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `0237b0a`.
- A deterministic stepped harness addresses non-repeatable market-maker runs. **Action:** Drive
  Strategy against the engine through the harness and pin one fixed-seed run's fills. Source: [Fun
  with Algebraic Effects - from Toy Examples to Hardcaml
  Simulations](janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md). Affects:
  [mm-core](../repos/mm-core.md), [exchange-core](../repos/exchange-core.md).
- A shadow strategy on the live feed reveals behavior changes without sending orders. **Action:**
  Add -shadow-params FILE to market-maker running a second Strategy that only logs plans and counts
  divergences. Source: [Building a functional email
  server](janestreet/podcast/08-building-a-functional-email-server.md). Affects:
  [market-maker](../repos/market-maker.md), [mm-core](../repos/mm-core.md).
- Runaway injectors without rate limits hurt everyone downstream. **Action:** Actions-per-second cap
  in Mm_core.Risk tripping the kill switch. Source: [State Machine Replication, and Why You Should
  Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `e7b0112`.
- The costly bug was a send queued for idle time, not slow code. **Action:** Audit Live.Make and
  adapters for timers/idle scheduling between decision and venue call. Source: [Performance
  Engineering on Hard Mode](janestreet/podcast/18-performance-engineering-on-hard-mode.md). Affects:
  [mm-core](../repos/mm-core.md), [market-maker](../repos/market-maker.md).
- External risk limits depend on correct contract units. **Action:** Expect test showing
  Params.for_instrument and max_position behaviour on a 1000PEPEUSDT-style instrument, documenting
  contracts vs tokens. Source: [Wrestling the world into
  rows](janestreet/podcast/29-wrestling-the-world-into-rows.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `3c92f01`.
- NaN fails float checks only when phrased in the passing direction. **Action:** Add an mm-core test
  that NaN in each float Params field makes validate fail. Source: [Making something out of nothing
  (or, why None is better than NaN and
  NULL)](janestreet/blog/2010-07-making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null.md).
  Affects: [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `6a8bf72`.
- Knowing which venue leads tells the quoter whose price to trust. **Action:** Record measured
  median lag per venue pair in specs before adding cross-venue fair value to mm-core. Source:
  [Visualizing information propagation in
  markets](janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md). Affects:
  [mm-core](../repos/mm-core.md).
- Shipping sample outputs with a model makes parameter changes visible. **Action:** Expect test
  printing quotes for fixed Market_state/Inventory per Params preset. Source: [Python, OCaml, and
  Machine Learning](janestreet/podcast/05-python-ocaml-and-machine-learning.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `3c92f01`.
- Soft limits with a bump budget keep quoting in busy markets while hard limits stay sticky.
  **Action:** Add optional soft_max_position with a bump budget to Params and Risk in mm-core,
  pulling the adding side instead of halting. Source: [An inside look at Jane Street's tech
  internship](janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `2b6c760`.
- Every order path, including emergency ones, must obey the same risk invariants. **Action:** Add a
  Base_quickcheck property in mm-core that Risk.flatten only places reduce-only orders. Source: [An
  inside look at Jane Street's tech
  internship](janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md). Affects:
  [mm-core](../repos/mm-core.md).
  **Done:** [mm-core](../repos/mm-core.md), commit `f924631`.
- Simple models can be hand-adjusted on regime change but our Params are fixed per run. **Action:**
  Add -params FILE sexp flag re-read on SIGHUP after Params.validate. Source: [Finding Signal in the
  Noise](janestreet/podcast/22-finding-signal-in-the-noise.md). Affects:
  [market-maker](../repos/market-maker.md), [mm-core](../repos/mm-core.md).
- Risk overrides need an owner and an expiry or they silently lapse or linger. **Action:** When
  per-run overrides are added to Params, require an expiry and reject expired ones in validate.
  Source: [What the SP interns have wrought, 2026
  edition](janestreet/blog/2026-09-wrought-2026-sp.md). Affects: [mm-core](../repos/mm-core.md).

## Themes

| Theme | Covers |
| --- | --- |
| [State machines and logs](themes/state-machines-and-logs.md) | Concord and Aria, sequencers, total order, gap fill, snapshots, replay, log formats |
| [Data platform](themes/data-platform.md) | Raw-first storage, symbology and units, catalogs and lineage, data quality, layout, Python through files |
| [OCaml and OxCaml practices](themes/ocaml-practices.md) | Stable types, expect tests, errors as values, modes and layouts, Core and Async conventions, review |
| [Performance](themes/performance.md) | Allocation, GC visibility, benchmarking, tail latency, tracing, hardware and network |
| [Testing and simulation](themes/testing-and-simulation.md) | Expect and property tests, reference models, deterministic simulation, fault injection, recorded traffic |
| [Research tooling](themes/research-tooling.md) | Files as interop, repeatable exploration, research hygiene, expert tools, AI coding tools |
| [Build and deploy](themes/build-and-deploy.md) | CI pins, caching, gating, revisions per deployment, configuration, hosts, clocks, observability |
| [Market making and trading systems](themes/market-making-and-trading-systems.md) | Exchanges as sequencers, feeds and gaps, order gateways and reconciliation, risk, venue semantics, latency |

## Index

### Signals and Threads episodes

| Published | Note | Actions | Tags |
| --- | --- | --- | --- |
| 2020-09-09 | [Programmable Hardware](janestreet/podcast/01-programmable-hardware.md) | 3 | `fpga`, `hardware`, `expect-tests`, `market-data`, `latency` |
| 2020-09-16 | [Build Systems](janestreet/podcast/02-build-systems.md) | 4 | `build`, `ocaml-practice`, `deployment`, `data-platform` |
| 2020-09-23 | [Multicast and the Markets](janestreet/podcast/03-multicast-and-the-markets.md) | 4 | `multicast`, `sequencer`, `market-data`, `networking`, `latency` |
| 2020-09-30 | [Compiler Optimization](janestreet/podcast/04-compiler-optimization.md) | 4 | `performance`, `oxcaml`, `formal-methods`, `testing`, `build` |
| 2020-10-07 | [Python, OCaml, and Machine Learning](janestreet/podcast/05-python-ocaml-and-machine-learning.md) | 4 | `python-interop`, `ml`, `research-tooling`, `parquet`, `expect-tests` |
| 2020-10-14 | [Clock Synchronization](janestreet/podcast/06-clock-synchronization.md) | 5 | `clocks`, `ops`, `observability`, `market-data`, `replay` |
| 2020-10-21 | [Language Design](janestreet/podcast/07-language-design.md) | 4 | `ocaml-practice`, `oxcaml`, `architecture`, `education` |
| 2020-10-28 | [Building a functional email server](janestreet/podcast/08-building-a-functional-email-server.md) | 4 | `testing`, `ops`, `data-platform`, `replay` |
| 2020-11-06 | [An inside look at Jane Street's tech internship](janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md) | 2 | `hiring`, `culture`, `risk`, `education` |
| 2021-09-01 | [Writing, Technically](janestreet/podcast/10-writing-technically.md) | 3 | `education`, `testing`, `build`, `culture` |
| 2021-10-06 | [Building a UI Framework](janestreet/podcast/11-building-a-ui-framework.md) | 2 | `ui`, `state-machines`, `ppx` |
| 2021-11-03 | [What Is an Operating System?](janestreet/podcast/12-what-is-an-operating-system.md) | 3 | `architecture`, `ocaml-practice`, `testing`, `networking` |
| 2022-01-05 | [Memory Management](janestreet/podcast/13-memory-management.md) | 3 | `gc`, `allocation`, `oxcaml`, `performance` |
| 2022-04-20 | [State Machine Replication, and Why You Should Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md) | 7 | `state-machines`, `sequencer`, `replay`, `architecture`, `multicast` |
| 2022-09-12 | [Swapping the Engine Out of a Moving Race Car](janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md) | 4 | `architecture`, `market-data`, `stable-types`, `performance`, `ops` |
| 2023-05-18 | [The Future of Programming](janestreet/podcast/16-future-of-programming.md) | 2 | `ai-tools`, `oxcaml`, `property-testing`, `ocaml-practice` |
| 2023-08-15 | [A Poet's Guide to Product Management](janestreet/podcast/17-a-poets-guide-to-product-management.md) | 1 | `culture`, `hiring` |
| 2023-11-28 | [Performance Engineering on Hard Mode](janestreet/podcast/18-performance-engineering-on-hard-mode.md) | 5 | `performance`, `latency`, `observability`, `allocation` |
| 2024-07-12 | [From the Lab to the Trading Floor: Designing for Expert Users](janestreet/podcast/19-from-the-lab-to-the-trading-floor.md) | 1 | `ui`, `culture`, `hiring`, `observability` |
| 2024-10-07 | [Solving Puzzles in Production](janestreet/podcast/20-solving-puzzles-in-production.md) | 7 | `ops`, `observability`, `culture`, `testing` |
| 2024-10-14 | [The Uncertain Art of Accelerating ML Models](janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md) | 2 | `ml`, `performance`, `data-platform`, `research-tooling` |
| 2025-03-12 | [Finding Signal in the Noise](janestreet/podcast/22-finding-signal-in-the-noise.md) | 4 | `research-tooling`, `data-platform`, `ml`, `market-data`, `trading` |
| 2025-05-28 | [Building Tools for Traders](janestreet/podcast/23-building-tools-for-traders.md) | 4 | `expect-tests`, `property-testing`, `ui`, `ocaml-practice`, `simulation` |
| 2025-07-25 | [The Thermodynamics of Trading](janestreet/podcast/24-the-thermodynamics-of-trading.md) | 3 | `hardware`, `ops`, `observability`, `latency` |
| 2025-09-03 | [Why ML Needs a New Programming Language](janestreet/podcast/25-why-ml-needs-a-new-programming-language.md) | 2 | `ml`, `hardware`, `performance`, `ai-tools`, `oxcaml` |
| 2026-03-17 | [Why Testing is Hard and How to Fix it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md) | 6 | `testing`, `simulation`, `property-testing`, `ai-tools`, `culture` |
| 2026-06-01 | [The Network as a Program](janestreet/podcast/27-the-network-as-a-program.md) | 1 | `networking`, `multicast`, `formal-methods`, `deployment` |
| 2026-06-24 | [Building a data warehouse from scratch](janestreet/podcast/28-building-a-data-warehouse-from-scratch.md) | 3 | `data-platform`, `parquet`, `architecture`, `sequencer`, `research-tooling` |
| 2026-09-02 | [Wrestling the world into rows](janestreet/podcast/29-wrestling-the-world-into-rows.md) | 4 | `market-data`, `data-platform`, `trading`, `risk`, `research-tooling` |
| 2026-09-23 | [Learning Goals and the Goals of Learning: Teaching in the Age of AI](janestreet/podcast/30-learning-goals-and-the-goals-of-learning-teaching-in-the-age-of-ai.md) | 1 | `education`, `ai-tools`, `culture`, `testing` |

### Blog posts

| Published | Note | Actions | Tags |
| --- | --- | --- | --- |
| 2026-10-05 | [Scaling and benchmarking a critical message bus using a new indexing strategy](janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md) | 4 | `sequencer`, `replay`, `performance`, `property-testing`, `data-platform` |
| 2026-10-01 | [A resilient kernel log reporter](janestreet/blog/2026-10-linux-engineering-kernel-reporter.md) | 2 | `ops`, `observability`, `deployment` |
| 2026-10-01 | [A FUSE server for our in-house storage backend](janestreet/blog/2026-10-linux-engineering-depot-fuse.md) | 4 | `testing`, `expect-tests`, `allocation`, `async`, `performance` |
| 2026-10-02 | [How recurring network maintenance exposed 6 bugs](janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md) | 5 | `async`, `networking`, `ops`, `observability`, `testing` |
| 2026-10-06 | [Building and testing a config management orchestrator for Windows](janestreet/blog/2026-10-config-management-orchestrator-for-windows.md) | 3 | `ops`, `testing`, `deployment`, `ocaml-practice` |
| 2026-10-02 | [Results from the ASIC puzzle](janestreet/blog/2026-10-asic-puzzle-results.md) | 0 | `hardware`, `education`, `hiring` |
| 2026-09-30 | [What the interns have wrought, special jumbo 2026 edition](janestreet/blog/2026-09-wrought-2026.md) | 0 | `hiring`, `culture`, `oxcaml`, `ml` |
| 2026-09-30 | [What the SP interns have wrought, 2026 edition](janestreet/blog/2026-09-wrought-2026-sp.md) | 1 | `risk`, `hiring`, `culture` |
| 2026-09-30 | [Trading off compute for memory with activation checkpointing](janestreet/blog/2026-09-trading-off-compute-for-memory-with-activation-checkpointing.md) | 0 | `ml`, `performance` |
| 2026-09-30 | [What the TDOE interns have wrought, 2026 edition](janestreet/blog/2026-09-tdoe-intern-projects-2026.md) | 3 | `trading`, `market-data`, `testing`, `hiring` |
| 2026-09-10 | [Can you design a chip? Announcing the protocol emulator ASIC competition](janestreet/blog/2026-09-protocol-emulator-asic-competition.md) | 0 | `hardware`, `education`, `hiring` |
| 2026-09-30 | [Mitigating memorization in LLMs](janestreet/blog/2026-09-mitigating-memorization-in-llms.md) | 0 | `ml`, `research-tooling` |
| 2026-09-30 | [Can you use autoregressive diffusion to generate market data?](janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md) | 2 | `simulation`, `market-data`, `ml` |
| 2026-09-14 | [A study of sequence weighting at scale](janestreet/blog/2026-09-a-study-of-sequence-weighting-at-scale.md) | 0 | `ml`, `research-tooling` |
| 2026-08-05 | [Can you reverse engineer an ASIC?](janestreet/blog/2026-08-can-you-reverse-engineer-an-asic.md) | 0 | `hardware`, `education`, `hiring` |
| 2026-06-15 | [Using OxCaml to implement type-safe reference counting between OCaml and Python](janestreet/blog/2026-06-oxcaml-typesafe-reference-counting-python.md) | 2 | `oxcaml`, `python-interop`, `gc`, `allocation` |
| 2026-06-07 | [Formal methods and the future of programming](janestreet/blog/2026-06-formal-methods-at-jane-street.md) | 3 | `formal-methods`, `ai-tools`, `oxcaml`, `ocaml-practice` |
| 2026-05-26 | [strace-ui, Bonsai_term, and the TUI renaissance](janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md) | 4 | `ui`, `expect-tests`, `ai-tools`, `observability` |
| 2026-04-22 | [Using group theory to explore the space of positional encodings for attention](janestreet/blog/2026-04-using-group-theory-to-explore-positional-encodings-attention.md) | 0 | `ml`, `education` |
| 2026-02-05 | [I design with Claude more than Figma now](janestreet/blog/2026-02-i-design-with-claude-code-more-than-figma-now.md) | 1 | `ai-tools`, `ui`, `culture` |
| 2026-02-24 | [Can you reverse engineer our neural network?](janestreet/blog/2026-02-can-you-reverse-engineer-our-neural-network.md) | 0 | `ml`, `education`, `hiring` |
| 2026-02-11 | [Results from the Advent of FPGA Challenge](janestreet/blog/2026-02-advent-of-fpga-challenge-2025-results.md) | 0 | `fpga`, `hardware`, `education` |
| 2026-01-06 | [Fun with Algebraic Effects - from Toy Examples to Hardcaml Simulations](janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md) | 3 | `oxcaml`, `async`, `simulation`, `testing`, `ocaml-practice` |
| 2025-12-03 | [Getting from tested to battle-tested](janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md) | 5 | `testing`, `simulation`, `property-testing`, `state-machines`, `sequencer` |
| 2025-11-24 | [Advent of FPGA — A Jane Street Challenge](janestreet/blog/2025-11-advent-of-fpga-challenge-2025.md) | 0 | `fpga`, `hardware`, `education` |
| 2025-08-27 | [What the interns have wrought, 2025 edition](janestreet/blog/2025-08-wrought-2025.md) | 3 | `property-testing`, `oxcaml`, `simulation`, `trading`, `data-platform` |
| 2025-07-02 | [A Higgs-bugson in the Linux Kernel](janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md) | 2 | `networking`, `simulation`, `testing`, `ops` |
| 2025-06-14 | [Introducing OxCaml](janestreet/blog/2025-06-introducing-oxcaml.md) | 2 | `oxcaml`, `build`, `performance`, `allocation` |
| 2025-03-22 | [Advent of Hardcaml](janestreet/blog/2025-03-advent-of-hardcaml-2024.md) | 0 | `fpga`, `hardware`, `education` |
| 2025-01-24 | [How we accidentally built a better build system for OCaml](janestreet/blog/2025-01-how-we-accidentally-built-a-better-build-system-for-ocaml.md) | 2 | `build`, `ocaml-practice`, `performance` |
| 2024-10-04 | [Developer education at Jane Street](janestreet/blog/2024-10-developer-education-at-jane-street.md) | 4 | `education`, `testing`, `async`, `market-data`, `performance` |
| 2024-08-26 | [What the interns have wrought, 2024 edition](janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md) | 3 | `replay`, `state-machines`, `observability`, `data-platform`, `risk` |
| 2024-08-29 | [ICFP 2024](janestreet/blog/2024-08-icfp-2024.md) | 1 | `oxcaml`, `allocation`, `ppx`, `performance` |
| 2024-07-22 | [Visualizing piecewise linear neural networks](janestreet/blog/2024-07-visualizing-piecewise-linear-neural-networks.md) | 0 | `ml`, `education` |
| 2023-09-12 | [What the interns have wrought, 2023 edition](janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md) | 2 | `observability`, `data-platform`, `async`, `research-tooling`, `trading` |
| 2023-09-01 | [Oxidizing OCaml: Data Race Freedom](janestreet/blog/2023-09-oxidizing-ocaml-parallelism.md) | 1 | `oxcaml`, `ocaml-practice`, `ai-tools` |
| 2023-07-06 | [We're sponsoring SoME3](janestreet/blog/2023-07-were-sponsoring-some3.md) | 0 | `education`, `culture` |
| 2023-06-21 | [Oxidizing OCaml: Rust-Style Ownership](janestreet/blog/2023-06-oxidizing-ocaml-ownership.md) | 0 | `oxcaml`, `allocation`, `ocaml-practice` |
| 2023-05-26 | [Oxidizing OCaml: Locality](janestreet/blog/2023-05-oxidizing-ocaml-locality.md) | 2 | `oxcaml`, `allocation`, `gc`, `performance` |
| 2023-04-14 | [Building reproducible Python environments with XARs](janestreet/blog/2023-04-building-reproducible-python-environments-with-xars.md) | 2 | `deployment`, `build`, `python-interop`, `research-tooling` |
| 2023-01-09 | [What if writing tests was a joyful experience?](janestreet/blog/2023-01-the-joy-of-expect-tests.md) | 1 | `expect-tests`, `testing`, `market-data`, `replay` |
| 2022-12-07 | [Accelerating zk-SNARKs - MSM and NTT algorithms on FPGAs with Hardcaml](janestreet/blog/2022-12-zero-knowledge-fpgas-hardcaml.md) | 0 | `fpga`, `hardware`, `performance` |
| 2022-11-23 | [Visualizing information propagation in markets](janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md) | 3 | `market-data`, `latency`, `clocks`, `trading`, `research-tooling` |
| 2022-11-17 | [Computations that differentiate, debug, and document themselves](janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md) | 2 | `ocaml-practice`, `expect-tests`, `risk`, `trading`, `research-tooling` |
| 2022-08-25 | [What the interns have wrought, 2022 edition](janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md) | 3 | `property-testing`, `testing`, `performance`, `observability`, `market-data` |
| 2022-08-30 | [Introducing the Jane Street Graduate Research Fellowship](janestreet/blog/2022-08-graduate-research-fellowship.md) | 0 | `hiring`, `education` |
| 2022-03-04 | [Research internships in our Tools and Compilers group](janestreet/blog/2022-03-research-internships-tnc.md) | 0 | `hiring`, `oxcaml`, `education` |
| 2022-01-14 | [How Jane Street Pairs Interns to Projects and Teams During the Software Engineering Internship](janestreet/blog/2022-01-project-pairing.md) | 0 | `hiring`, `culture` |
| 2022-01-11 | [Magic-trace: Diagnosing tricky performance issues easily with Intel Processor Trace](janestreet/blog/2022-01-magic-trace.md) | 2 | `performance`, `latency`, `async`, `observability`, `hardware` |
| 2021-10-21 | [Hiring a Developer Educator](janestreet/blog/2021-10-hiring-a-developer-educator.md) | 0 | `hiring`, `education` |
| 2021-08-09 | [What the interns have wrought, 2021 edition](janestreet/blog/2021-08-what-the-interns-have-wrought-2021.md) | 2 | `testing`, `ppx`, `observability`, `culture` |
| 2021-08-26 | [Goodbye Core_kernel](janestreet/blog/2021-08-goodbye-core-kernel.md) | 1 | `ocaml-practice`, `build` |
| 2021-06-15 | [Looking for a developer experience engineer](janestreet/blog/2021-06-looking-for-a-developer-experience-engineer.md) | 0 | `hiring`, `culture` |
| 2020-12-01 | [Growing the Hardcaml toolset](janestreet/blog/2020-12-growing-the-hardcaml-toolset.md) | 0 | `fpga`, `hardware`, `testing` |
| 2020-11-24 | [Announcing Our Market Prediction Kaggle Competition](janestreet/blog/2020-11-announcing-our-market-prediction-kaggle-competition.md) | 0 | `ml`, `hiring` |
| 2020-10-06 | [Finding memory leaks with Memtrace](janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md) | 3 | `gc`, `allocation`, `observability`, `ops` |
| 2020-09-15 | [Memory allocator showdown](janestreet/blog/2020-09-memory-allocator-showdown.md) | 2 | `gc`, `allocation`, `performance` |
| 2020-08-17 | [What the interns have wrought, 2020 edition](janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md) | 2 | `property-testing`, `testing`, `networking`, `culture` |
| 2020-08-31 | [Announcing Signals and Threads, a new podcast from Jane Street](janestreet/blog/2020-08-announcing-signals-and-threads.md) | 0 | `education`, `culture` |
| 2020-07-24 | [The Jane Street Interview Process — 2020 Edition](janestreet/blog/2020-07-jane-street-interview-process-2020.md) | 0 | `hiring`, `culture` |
| 2020-06-01 | [Using ASCII waveforms to test hardware designs](janestreet/blog/2020-06-using-ascii-waveforms-to-test-hardware-designs.md) | 2 | `expect-tests`, `testing`, `fpga` |
| 2020-06-22 | [Really low latency multipliers and cryptographic puzzles](janestreet/blog/2020-06-really-low-latency-multipliers-and-cryptographic-puzzles.md) | 0 | `fpga`, `hardware`, `latency` |
| 2020-04-17 | [Chrome extensions: Finding the missing proof](janestreet/blog/2020-04-chrome-extensions-finding-the-missing-proof.md) | 0 | `ops`, `deployment` |
| 2020-02-20 | [Watch all of Jane Street's tech talks](janestreet/blog/2020-02-watch-all-of-jane-streets-tech-talks.md) | 0 | `education`, `architecture` |
| 2020-02-03 | [Troubleshooting systemd with SystemTap](janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md) | 3 | `ops`, `observability`, `performance` |
| 2019-12-16 | [Using Python and OCaml in the same Jupyter notebook](janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md) | 2 | `python-interop`, `research-tooling`, `ppx` |
| 2019-12-06 | [Deep-Learning the Hardest Go Problem in the World](janestreet/blog/2019-12-deep-learning-the-hardest-go-problem-in-the-world.md) | 0 | `ml`, `research-tooling` |
| 2019-10-14 | [Commas in big numbers everywhere: An OpenType adventure](janestreet/blog/2019-10-commas-in-big-numbers-everywhere.md) | 0 | `ui`, `research-tooling` |
| 2019-08-30 | [What the interns have wrought, 2019 edition](janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md) | 2 | `observability`, `latency`, `testing`, `async`, `research-tooling` |
| 2019-08-19 | [Using OCaml to drive a Raspberry Pi robot car](janestreet/blog/2019-08-using-ocaml-to-drive-a-raspberry-pi-robot-car.md) | 0 | `hardware`, `async`, `education` |
| 2019-08-16 | [Do applied programming languages research at Jane Street](janestreet/blog/2019-08-applied-pl-research.md) | 0 | `hiring`, `oxcaml` |
| 2019-07-09 | [Of Pythons and Camels](janestreet/blog/2019-07-of-pythons-and-camels.md) | 0 | `ml`, `python-interop` |
| 2019-07-12 | [A look at OCaml 4.08](janestreet/blog/2019-07-a-look-at-ocaml-4-08.md) | 1 | `ocaml-practice`, `build` |
| 2019-05-13 | [Thoughts from AAAI 2019](janestreet/blog/2019-05-thoughts-from-aaai-19.md) | 1 | `ml`, `simulation`, `testing` |
| 2019-04-17 | [Learning ML Depth-First](janestreet/blog/2019-04-learning-ml-depth-first.md) | 0 | `ml`, `education`, `culture` |
| 2019-02-28 | [Machining the ultimate hackathon prize](janestreet/blog/2019-02-hackathon-keyboards.md) | 0 | `culture`, `hardware` |
| 2019-02-28 | [Accelerating Self-Play Learning in Go](janestreet/blog/2019-02-accelerating-self-play-learning-in-go.md) | 0 | `ml`, `culture` |
| 2019-01-29 | [L2 Regularization and Batch Norm](janestreet/blog/2019-01-l2-regularization-and-batch-norm.md) | 0 | `ml` |
| 2019-01-15 | [A tutorial for building web applications with Incr_dom](janestreet/blog/2019-01-a-tutorial-for-building-web-applications-with-incrdom.md) | 0 | `ui`, `ocaml-practice` |
| 2018-09-26 | [How to shuffle a big dataset](janestreet/blog/2018-09-how-to-shuffle-a-big-dataset.md) | 1 | `ml`, `data-platform`, `performance` |
| 2018-09-20 | [Deep learning experiments in OCaml](janestreet/blog/2018-09-deep-learning-experiments-in-ocaml.md) | 0 | `ml`, `ocaml-practice`, `python-interop` |
| 2018-08-06 | [What the interns have wrought, 2018 edition](janestreet/blog/2018-08-what-the-interns-have-wrought-2018.md) | 0 | `hiring`, `networking`, `ui`, `testing` |
| 2018-06-29 | [Plans for OCaml 4.08](janestreet/blog/2018-06-plans-for-ocaml-408.md) | 0 | `ocaml-practice`, `oxcaml` |
| 2018-04-22 | [Repeatable exploratory programming](janestreet/blog/2018-04-repeatable-exploratory-programming.md) | 2 | `expect-tests`, `testing`, `market-data`, `research-tooling` |
| 2018-04-04 | [OCaml all the way down](janestreet/blog/2018-04-ocaml-all-the-way-down.md) | 0 | `fpga`, `culture`, `hardware` |
| 2018-03-27 | [Putting the I back in IDE: Towards a Github Explorer](janestreet/blog/2018-03-putting-the-i-back-in-ide-towards-a-github-explorer.md) | 0 | `culture`, `build` |
| 2018-02-15 | [Proofs (and Refutations) using Z3](janestreet/blog/2018-02-proofs-and-refutations-using-z3.md) | 2 | `formal-methods`, `property-testing`, `testing` |
| 2018-02-16 | [Learn OCaml in NYC](janestreet/blog/2018-02-learn-ocaml-nyc.md) | 0 | `education`, `ocaml-practice` |
| 2017-10-29 | [How Jane Street Does Code Review (Jane Street Tech Talk)](janestreet/blog/2017-10-jane-street-tech-talk-how-jane-street-does-code-review.md) | 0 | `culture` |
| 2017-08-24 | [Ironing out your development style](janestreet/blog/2017-08-ironing-out-your-development-style.md) | 1 | `expect-tests`, `testing`, `culture`, `build` |
| 2017-05-11 | [When Bash Scripts Bite](janestreet/blog/2017-05-when-bash-scripts-bite.md) | 2 | `ops`, `testing`, `build` |
| 2017-04-20 | [This is not the performance you were looking for: the tricks systems play on us](janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md) | 2 | `ops`, `performance`, `deployment`, `observability` |
| 2017-04-25 | [Caveat Configurator: how to replace configs with code, and why you might not want to](janestreet/blog/2017-04-caveat-configurator-how-to-replace-configs-with-code-and-why-you-might-not-want-to.md) | 1 | `ops`, `deployment`, `testing` |
| 2017-03-20 | [Trivial meta-programming with cinaps](janestreet/blog/2017-03-trivial-meta-programming-with-cinaps.md) | 0 | `ppx`, `ocaml-practice`, `build` |
| 2017-01-11 | [How to Build an Exchange](janestreet/blog/2017-01-how-to-build-an-exchange.md) | 1 | `architecture`, `sequencer`, `multicast`, `trading` |
| 2017-01-09 | [A brief trip through Spacetime](janestreet/blog/2017-01-a-brief-trip-through-spacetime.md) | 1 | `allocation`, `gc`, `observability`, `performance` |
| 2016-06-21 | [Let syntax, and why you should use it](janestreet/blog/2016-06-let-syntax-and-why-you-should-use-it.md) | 0 | `async`, `ppx`, `ocaml-practice` |
| 2016-03-09 | [Seven Implementations of Incremental](janestreet/blog/2016-03-seven-implementations-of-incremental.md) | 0 | `ocaml-practice`, `performance` |
| 2016-02-24 | [A better inliner for OCaml, and why it matters](janestreet/blog/2016-02-flambda.md) | 1 | `oxcaml`, `allocation`, `performance` |
| 2015-12-02 | [Testing with expectations](janestreet/blog/2015-12-testing-with-expectations.md) | 1 | `expect-tests`, `testing` |
| 2015-10-26 | [Quickcheck for Core](janestreet/blog/2015-10-quickcheck-for-core.md) | 3 | `property-testing`, `testing`, `ocaml-practice` |
| 2015-07-18 | [Introducing Incremental](janestreet/blog/2015-07-introducing-incremental.md) | 0 | `architecture`, `risk`, `ui`, `performance` |
| 2015-05-05 | [CPU Registers and OCaml](janestreet/blog/2015-05-cpu-registers-and-ocaml-2.md) | 0 | `performance`, `ocaml-practice`, `hardware` |
| 2015-04-09 | [Faster OCaml to C calls](janestreet/blog/2015-04-faster-ocaml-to-c-calls.md) | 0 | `performance`, `allocation`, `ocaml-practice` |
| 2015-04-10 | [Building a lower-latency GC](janestreet/blog/2015-04-building-a-lower-latency-gc.md) | 2 | `gc`, `latency`, `allocation`, `observability` |
| 2015-03-30 | [Why GADTs matter for performance](janestreet/blog/2015-03-why-gadts-matter-for-performance.md) | 0 | `performance`, `ocaml-practice`, `allocation` |
| 2014-10-16 | [What the interns have wrought: RPC_parallel and Core_profiler](janestreet/blog/2014-10-what-the-interns-have-wrought-rpc-parallel-and-core-profiler.md) | 0 | `hiring`, `observability`, `performance`, `allocation` |
| 2014-09-29 | [What is gained and lost with 63-bit integers?](janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md) | 3 | `performance`, `ocaml-practice`, `trading` |
| 2014-07-06 | [Making “never break the build” scale](janestreet/blog/2014-07-making-never-break-the-build-scale.md) | 2 | `build`, `testing`, `culture` |
| 2014-07-09 | [Inspecting Internal TCP State on Linux](janestreet/blog/2014-07-inspecting-internal-tcp-state-on-linux.md) | 1 | `networking`, `ops`, `observability` |
| 2014-06-24 | [Iron out your release process](janestreet/blog/2014-06-ironing-out-your-release-process.md) | 2 | `build`, `deployment`, `culture` |
| 2014-05-17 | [Core_bench: better micro-benchmarks through linear regression](janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md) | 2 | `performance`, `allocation`, `gc`, `testing` |
| 2014-04-23 | [How to fail -- introducing Or_error.t](janestreet/blog/2014-04-how-to-fail-introducing-or-error-dot-t.md) | 3 | `ocaml-practice`, `testing`, `expect-tests` |
| 2014-01-09 | [Async Parallel](janestreet/blog/2014-01-async-parallel.md) | 0 | `async`, `architecture`, `ocaml-practice` |
| 2013-09-11 | [What's 2013 + 50? 1969, of course](janestreet/blog/2013-09-whats-2013-50-1969-of-course.md) | 0 | `clocks`, `ops` |
| 2010-07-15 | [Making something out of nothing (or, why None is better than NaN and NULL)](janestreet/blog/2010-07-making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null.md) | 2 | `ocaml-practice`, `testing`, `risk` |
| 2009-11-07 | [Core Gems: Time](janestreet/blog/2009-11-core-gems-time.md) | 1 | `clocks`, `ocaml-practice`, `stable-types` |
| 2008-12-03 | [Lightweight versioning for lightweight protocols](janestreet/blog/2008-12-lightweight-versioning-for-lightweight-protocols.md) | 0 | `stable-types`, `ocaml-practice`, `architecture` |
| 2008-08-18 | [The perils of polymorphic compare](janestreet/blog/2008-08-the-perils-of-polymorphic-compare.md) | 0 | `ocaml-practice`, `performance` |
| 2008-08-05 | [Better float unboxing](janestreet/blog/2008-08-better-float-unboxing.md) | 0 | `allocation`, `performance`, `ocaml-practice` |
| 2008-03-15 | [Typing RPCs](janestreet/blog/2008-03-typing-rpcs.md) | 0 | `ocaml-practice`, `architecture`, `networking` |
