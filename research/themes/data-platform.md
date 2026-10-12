# Data platform

This theme covers how market data is recorded, normalized into rows, stored as Parquet,
catalogued, checked and handed to SQL and Python. It matters because our research, our
backtests and the planned replay server all stand on the files written by
[market-recorder](../../repos/market-recorder.md) and derived by
[market-data](../../repos/market-data.md) and [parquet](../../repos/parquet.md). The Jane Street
sources describe a warehouse, a normalization service and an alt-data team at a much larger
scale, but the failure modes they name (made-up values that consumers come to depend on,
untracked derived data, silent gaps, unit mix-ups) are the ones a small raw-first platform hits
first.

## Keep what arrived, with our own clock, and derive the rest

The alt-data team stores every vendor delivery with its own receive time, because vendors revise
history and a backtest on corrected data simulates a time machine
([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)). Our raw minute files
already follow the same rule: each line is our `recv_ts` followed by the frame as received. The
opposite lesson comes from the trading-activity normalizer in
[episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md): a promise
to always deliver complete-looking data led it to invent records, and clients then relied on the
inventions. Recording the absent as absent is cheaper than unwinding that later.

Raw-first only pays off once rebuilding is a command. A rebuilt normalizer is a second
implementation of the live one, so the natural acceptance test is to rebuild a recorded day and
diff it against what ran live
([episode 8](../janestreet/podcast/08-building-a-functional-email-server.md)), and being able to
exclude specific bad records turns a crash into a quick recovery
([episode 20](../janestreet/podcast/20-solving-puzzles-in-production.md)).

## Normalization is mostly metadata: symbology and units

Normalization at Jane Street spans venue codes, vendor symbols and usernames, and gets harder
outside the best-understood markets
([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md)). The
value of a shared store is that trades, positions and symbology join
([episode 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md)). Futures add
contract multipliers and quote conventions where a mix-up means trading many times the intended
size, and risk limits outside the strategy are only as good as that metadata
([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)). Crypto has the same
trap: `1000PEPEUSDT` on Binance and Bybit and `kPEPE` on Hyperliquid quote per thousand tokens, so
raw prices are not comparable across venues.

Instrument metadata also changes over time. A point-in-time universe avoids survivorship bias,
which needs a daily record of which instruments existed and their tick and lot sizes
([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md)). Normalized feeds have
well-known client pitfalls (snapshot and diff sequencing, gap detection, resync after reconnect)
that make a ready checklist for our `Live_feed` modules
([developer education](../janestreet/blog/2024-10-developer-education-at-jane-street.md)).

## Own the catalog and record lineage

Superstore keeps data in Parquet but owns every read and write, and the guest credits the
resulting usage logs with making deprecation and schema evolution possible; without them you grep
everyone's SQL, then views of views
([episode 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md)). We take the
opposite stance, letting DuckDB read files directly, which is reasonable for a small team, but we
still lack the two cheap parts: an inventory of what exists and a record of what is queried.

Lineage is the other half. A derived dataset is trustworthy only if you can say which inputs and
code produced it ([episode 21](../janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md)),
and rebuilt history must be distinguishable from what it replaced
([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)). The same input manifest
gives early cutoff for batch rebuilds, skipping days whose inputs did not change
([episode 2](../janestreet/podcast/02-build-systems.md)). Superstore also compacts between write
and read because small files multiply object-store and metadata cost
([episode 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md)); our day close
does the same, but nothing reports how many parts it replaced or how well it compressed.

## Check the data independently of the code that made it

The alt-data team moved from long database views to composable, tested, reviewed SQL
transformations ([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)), and
cleaned data still needs checks that do not share assumptions with the cleaner
([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md)). For us that means
assertions over the Parquet output: no crossed BBO, positive sizes, ordered `recv_ts`, and minutes
with no trades or BBO updates on liquid symbols, which is also how unmarked reconnect gaps would
surface.

When logic exists twice, a golden sample keeps the copies aligned: candles exist in `Candle_agg`
and can be computed in SQL ([episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md)).
Changes to the batch itself can be checked by running two revisions on the same input and diffing
the tables ([episode 8](../janestreet/podcast/08-building-a-functional-email-server.md)). Once the
market maker logs its fills, joining them to recorded public trades is a cheap end-to-end
correctness check ([intern projects 2026](../janestreet/blog/2026-09-tdoe-intern-projects-2026.md)),
and a request for a date range with no data should fail loudly rather than return nothing
([tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md)).

## Storage layout follows the read pattern

Row stores cannot compress across rows and analytical scans need a columnar layout
([episode 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md)), but columnar
only helps when the reader can skip: pushdown pays off when statistics let whole row groups be
skipped ([wrought 2025](../janestreet/blog/2025-08-wrought-2025.md)). Our row groups default to
about a million rows, so a one-hour filter on a day file rarely skips anything. Wasted bytes per
read is the metric for choosing file granularity, and a multi-symbol replay is an n-way merge whose
correctness must hold for any interleaving
([message bus](../janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md)).
Random access into compressed files is orders of magnitude slower than streaming
([shuffling a big dataset](../janestreet/blog/2018-09-how-to-shuffle-a-big-dataset.md)), so raw
zstd minute files are for sequential replay and point queries belong in Parquet.

Replay has two further needs. It must keep one global order across streams so small streams do
not run ahead, and replaying from the start of the day does not scale
([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).
Late joiners want a compact snapshot
([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md)), yet our event logs hold L2
snapshots only at connect and resync.

## Two timestamps are a measurement, if clocks are known

Every row carries `exch_ts` and `recv_ts`, which together expose network delay and clock drift
([episode 6](../janestreet/podcast/06-clock-synchronization.md)); latency is most useful as a
distribution over the day ([interns 2019](../janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md)),
and receive times across venues allow a lead-lag measurement of price moves
([information propagation](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md)).
Comparisons across hosts are only valid within the measured clock error, which we do not record,
and the planned two-region merge by earliest `recv_ts` depends on it
([episode 6](../janestreet/podcast/06-clock-synchronization.md)). Failing over to a farther
collector is a latency change rather than a transparent swap
([episode 24](../janestreet/podcast/24-the-thermodynamics-of-trading.md)), and previewing failure
cases before building is what made a network tool valuable
([episode 27](../janestreet/podcast/27-the-network-as-a-program.md)). The planned replication
already has the shape of sequence numbers plus peer gap fill
([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).

## Python through files, SQL as the shared language

Jane Street reaches OCaml from notebooks through generated bindings
([Python and OCaml in Jupyter](../janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md)),
but our boundary is files: Parquet that pandas, pyarrow and DuckDB read without OCaml code
([episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md)). The risk then
moves to type fidelity of `TIMESTAMP_NS` and `DECIMAL(18,8)`, and to researchers having a worked
entry point. Temporal "last X before Y" questions are the core debugging query, and DuckDB's
`ASOF JOIN` expresses them directly
([interns 2023](../janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md)). Generating
SQL from natural language works only with real example queries over the actual schema
([designing with Claude Code](../janestreet/blog/2026-02-i-design-with-claude-code-more-than-figma-now.md)).

## Recording must lag visibly, never lose silently

A producer outrunning its consumer through an unbounded queue shows up as growing object
lifetimes ([memtrace](../janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md)), and
slow consumers should lag visibly rather than drop data unseen
([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md)).
Receivers must know when they lost messages
([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md)); our client reconnects are
invisible to the recorder. New sources should plug in behind a signature rather than through edits
to a central match ([episode 12](../janestreet/podcast/12-what-is-an-operating-system.md)), which
matters once `*-feed` repositories arrive.

## Where we stand

- Raw-first with our own receive time is in place: [market-recorder](../../repos/market-recorder.md)
  writes `<recv_ts> <frame>` minute files, zstd-compressed and uploaded through a command; see
  [design/data-platform.md](../../design/data-platform.md).
- No raw-to-norm tool exists, so rebuilding `norm/` from raw is a design property, not a command
  ([market-data](../../repos/market-data.md) known gaps).
- Hyperliquid funding events copy `recv_ts` into `exch_ts` and synthesize `next_funding_time` as
  the next hour (`hl-client` `Live_feed.funding`), the invented-value pattern described above;
  see [hl-client](../../repos/hl-client.md).
- `Market_data.Instrument` is only venue plus the venue's own symbol string; there is no tick, lot
  or contract-size metadata and no daily instruments table.
- `market-data` has three subcommands (`day-close`, `views`, `query`); there is no catalog, check
  or query log, and day close writes no manifest. The [parquet](../../repos/parquet.md) writer
  cannot store key-value metadata.
- `Parquet_views` generates one plain `SELECT *` view per table; no derived views (latency,
  ASOF joins, gap minutes) exist yet.
- `Day_close` uses a default of 1,048,576 rows per row group; the writer emits min/max statistics
  per column chunk.
- `Replay_feed.of_files` merges event logs by `recv_ts` but always starts at the beginning of the
  files; L2 snapshots appear only at connect and resync.
- `Parquet_sink` counts dropped rows (`dropped`), but the recorder does not use the sink, so that
  counter has no consumer today.
- Reconnects inside the clients are not visible through `Market_data.Feed.t`, so reconnect gaps
  are not marked in raw files.
- Timestamps go to Parquet as `TIMESTAMP_NS` with `isAdjustedToUTC=false` and prices as
  `DECIMAL(18,8)`; nothing tests how pyarrow or pandas read them, and `market-data` ships no
  Python example.
- Replication is design only, in
  [design/cloud-sinks-and-replication.md](../../design/cloud-sinks-and-replication.md); it lists
  message identity and reconnect marking as open questions and has no failure table.

## Proposed actions

1. Add `market-data check -dir D -date YYYY-MM-DD` running fixed DuckDB assertions (no crossed
   BBO, positive sizes, ordered `recv_ts`, no empty minutes on liquid symbols, including a
   gap-minutes view tested on a fixture with one gap) and exiting non-zero; run it after the
   day-close CronJob. [market-data](../../repos/market-data.md), [infra](../../repos/infra.md);
   [ep. 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md),
   [ep. 22](../janestreet/podcast/22-finding-signal-in-the-noise.md).
2. Emit a gap or reconnect event through `Market_data.Feed.t` from each `Live_feed` on resync and
   write it as a disconnect line, with an expect test forcing a Bybit sequence gap.
   [market-data](../../repos/market-data.md), [market-recorder](../../repos/market-recorder.md);
   [ep. 3](../janestreet/podcast/03-multicast-and-the-markets.md).
3. Add a per-instrument `units_per_contract` table (1 by default, 1000 for `1000PEPEUSDT` and
   `kPEPE`) as a DuckDB view, with an expect test showing per-token mids agree across the three
   venues. [market-data](../../repos/market-data.md);
   [ep. 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md).
4. Have `day-close` write a `<date>.manifest.sexp` per table (producer version, source `norm/`
   files with sizes and hashes, run time) with an expect test, and skip days whose inputs match
   the manifest. [market-data](../../repos/market-data.md);
   [ep. 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md),
   [ep. 21](../janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md),
   [ep. 2](../janestreet/podcast/02-build-systems.md).
5. Build the raw-to-norm tool with an acceptance test that rebuilds one recorded day and diffs it
   event by event against the live `norm/` logs, plus a skip-list of raw file and line numbers.
   [market-data](../../repos/market-data.md);
   [ep. 8](../janestreet/podcast/08-building-a-functional-email-server.md),
   [ep. 20](../janestreet/podcast/20-solving-puzzles-in-production.md).
6. Add `market-data catalog -dir D` listing per table the venues, symbols, date range, file count
   and leftover numbered parts, with an expect test over a fixture directory.
   [market-data](../../repos/market-data.md);
   [ep. 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md).
7. Add a Base_quickcheck property test writing random multi-symbol, multi-stream events to
   `Event_log` and replaying them through `Merge` and `Replay_feed`, checking global `recv_ts`
   order with no loss or duplicates (covering a 10-event stream beside a 10,000-event one).
   [market-data](../../repos/market-data.md);
   [message bus](../janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md),
   [ep. 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md).
8. Write a periodic (per-minute) L2 snapshot event into the event log and let `Replay_feed` start
   at the last snapshot at or before the requested time.
   [market-recorder](../../repos/market-recorder.md), [market-data](../../repos/market-data.md);
   [ep. 3](../janestreet/podcast/03-multicast-and-the-markets.md),
   [ep. 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md).
9. Add a clock-error gauge to `/metrics` sampled every 10 s from `chronyc -c tracking`, and state
   in the replication design that frames closer than the error bound are unordered.
   [market-recorder](../../repos/market-recorder.md);
   [ep. 6](../janestreet/podcast/06-clock-synchronization.md),
   [information propagation](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md).
10. Add a `Funding.Stable.V2` with optional `exch_ts`, written as absent for Hyperliquid instead of
    copying `recv_ts`. [market-data](../../repos/market-data.md),
    [hl-client](../../repos/hl-client.md);
    [ep. 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md).
11. Have `day-close` write a daily `instruments` table (venue, symbol, tick, lot, first and last
    `recv_ts`) for point-in-time universes. [market-data](../../repos/market-data.md);
    [ep. 22](../janestreet/podcast/22-finding-signal-in-the-noise.md).
12. Add a latency view to `Parquet_views`: per venue, stream and minute, p50 and p99 of
    `recv_ts - exch_ts`. [market-data](../../repos/market-data.md);
    [interns 2019](../janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md),
    [ep. 6](../janestreet/podcast/06-clock-synchronization.md).
13. Add a `trades_with_bbo` view using DuckDB `ASOF JOIN` (last BBO at or before each trade),
    tested over a fixture day. [market-data](../../repos/market-data.md);
    [interns 2023](../janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md).
14. Add a test loading a day-close table with pyarrow, asserting nanosecond timestamps and decimal
    prices; document the mapping of `exch_ts`/`recv_ts` to pandas `datetime64[ns, UTC]` and ship
    `examples/query.py` loading one day of trades via the views.
    [market-data](../../repos/market-data.md);
    [Python and OCaml in Jupyter](../janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md),
    [ep. 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md).
15. Add a test comparing `Candle_agg` output with candles computed by DuckDB over the same day's
    Parquet, row for row. [market-data](../../repos/market-data.md);
    [ep. 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md).
16. Add a `market-recorder` test stalling `Norm_writer` while feeding input and printing the
    buffered event count, to show whether the pipes push back.
    [market-recorder](../../repos/market-recorder.md);
    [memtrace](../janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md).
17. Write trades and L2 in `Day_close` with smaller row groups (for example 128k rows) and confirm
    with `EXPLAIN ANALYZE` that a one-hour `recv_ts` filter scans fewer rows.
    [market-data](../../repos/market-data.md), [parquet](../../repos/parquet.md);
    [wrought 2025](../janestreet/blog/2025-08-wrought-2025.md).
18. Add `scripts/diff-day-close.sh` running day close from two revisions on one recorded day and
    diffing every table with DuckDB `EXCEPT`. [market-data](../../repos/market-data.md);
    [ep. 8](../janestreet/podcast/08-building-a-functional-email-server.md).
19. Make `Replay_feed` (and `query`) fail with an explicit error for a date range that has no
    event log files, with an expect test. [market-data](../../repos/market-data.md);
    [tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md).
20. In the replication design, specify gap detection from venue sequence fields (Binance `pu`/`u`,
    Bybit `seq`) with peer gap fill, add a failure table (collector down, region down, uploader
    stalled) with the expected gap and how readers detect it, and add an open question on tagging
    events with collector and region. `specs`;
    [ep. 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md),
    [ep. 27](../janestreet/podcast/27-the-network-as-a-program.md),
    [ep. 24](../janestreet/podcast/24-the-thermodynamics-of-trading.md).
21. Introduce a `Venue_source.S` module type in the recorder (config to `Feed.t` plus `on_raw`)
    and register the three clients as first-class modules.
    [market-recorder](../../repos/market-recorder.md);
    [ep. 12](../janestreet/podcast/12-what-is-an-operating-system.md).
22. Make `market-data query` append UTC time, user and SQL text to `query-log.ndjson` in the data
    directory, with an opt-out flag. [market-data](../../repos/market-data.md);
    [ep. 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md).
23. Add a lead-lag query to the views: mid moves above 1 bp within 5 ms on one venue and the delay
    to the next same-direction move on the other two.
    [market-data](../../repos/market-data.md);
    [information propagation](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md).
24. Add a client-pitfalls checklist (snapshot and diff sequencing, gap detection, resync after
    reconnect) to [design/data-platform.md](../../design/data-platform.md), each item linked to
    its covering test or marked missing. `specs`;
    [developer education](../janestreet/blog/2024-10-developer-education-at-jane-street.md).
25. Add a specs page of example DuckDB queries over the views with column notes, including a
    bytes-per-venue-stream-symbol query for one day to size replay file granularity. `specs`;
    [designing with Claude Code](../janestreet/blog/2026-02-i-design-with-claude-code-more-than-figma-now.md),
    [message bus](../janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md).
26. Have `day-close` print per table and day the input frames, sink parts replaced and output
    bytes in the CronJob log. [market-data](../../repos/market-data.md);
    [ep. 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md).
27. Once the market maker logs fills, add a DuckDB query joining them to recorded `trades` by
    price, size and time window and listing fills with no public print. `specs`,
    [market-maker](../../repos/market-maker.md);
    [intern projects 2026](../janestreet/blog/2026-09-tdoe-intern-projects-2026.md).
28. If the recorder ever adopts `Parquet_sink`, export its `dropped` count on `/metrics`.
    [market-recorder](../../repos/market-recorder.md);
    [ep. 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md).
29. State in the layers notes of [design/data-platform.md](../../design/data-platform.md) that raw
    zstd files serve sequential replay only and point queries go through Parquet and DuckDB.
    `specs`; [shuffling a big dataset](../janestreet/blog/2018-09-how-to-shuffle-a-big-dataset.md).
