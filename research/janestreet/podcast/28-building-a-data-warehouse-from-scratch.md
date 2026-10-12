# Building a data warehouse from scratch

- Source: <https://signalsandthreads.com/building-a-data-warehouse-from-scratch/>
- Published: 2026-06-24
- Kind: Signals and Threads episode 28

## Summary

- The guest is a Jane Street engineer who studied mechanism design (auctions and allocation that
  reward truthful bidding), then worked on Google's ad exchange after the DoubleClick acquisition.
  There, real-time bidding queried advertisers' systems for every impression within a 250 ms budget.
- His main lesson from ads: incentive compatibility matters less than explainability. Real systems
  leave budgets for advertisers to manage themselves, because a mechanism that adjusts bids for them
  gives results nobody understands. Simplicity is a value.
- Google's distributed-systems style keeps the hard stateful parts in a few proven components
  (BigTable on Chubby) and builds many stateless servers on top. Trading systems instead keep state
  at the edge because latency budgets are microseconds, not 250 ms. Each organization's
  infrastructure reflects its first application (search for Google, trading for Jane Street).
- Between jobs he ran a startup mapping city curb rules, using AR-style visual odometry to place
  signs to within one parking spot and hand-built parsers for sign language that varies by city. The
  data problem was great; the business didn't work.
- At Jane Street, research data lived in large shared Postgres databases (the main one ran on the
  firm's biggest machine) that traders used with few restrictions. Keeping them up took a
  long-running-transaction killer and a deadlock killer.
- Why Postgres struggles here: it is built for small atomic transactions with indexes on disk and
  in-place row updates, so it cannot compress across rows. Analytical scans over millions of rows
  need a columnar layout.
- An earlier columnar product, Vertica, offered full SQL transactions over columnar storage; that
  layer removed most of the columnar benefit and was easy to break. The guest argues SQL is so good
  that queries don't feel like programs, yet the planner is a compiler that can change a query's
  big-O.
- Long transactions hurt Postgres because writers hold row locks until commit and the engine must
  keep old row versions around, which blocks other writers, delays vacuuming and complicates
  replication.
- The value of a shared database is the ecosystem of joinable data (trades, fees, positions,
  symbology). Many firms protect scale with schema councils and reviewed queries; Jane Street wanted
  to keep the freedom.
- Requirements for Superstore: keep ad hoc use, store more than one machine holds, compress well,
  scan large data fast, and make it hard for one user to hurt another's correctness or performance.
- Design compromise: atomic, order-preserving writes within one table but no cross-table
  transactions. Most data is appended from a source of truth (a trade either happened or didn't), so
  cross-table consistency mostly comes for free.
- Columnar storage makes new columns nearly free and lets queries read 7 of 100 columns, but row
  updates are expensive. Superstore keeps updates and deletes but lets them be slow, and makes every
  write asynchronous: the write is acknowledged in order immediately and becomes readable after the
  system has placed and recompressed the data.
- SQL is the first-class read interface but not the write interface; most writes come from software
  pipelines. Ad hoc join tables are uploaded whole and replaced, never edited row by row. Because
  users are in-house, the team can explain these semantics and build the first examples itself.
- Data sits in Parquet, but users may not read the files directly. Owning every read and write
  enables ACLs beyond Unix permissions, plus read and write usage logs. Those logs make deprecation
  and schema evolution possible; otherwise you grep everyone's SQL, then views, then views of views.
- Cheap queries over terabytes created new uses: network access logs for security, every build and
  code review for tools teams, and high-cardinality records of what a trading system believed when
  it sent each order, written billions of times a day.
- Build versus buy: cloud warehouses (Snowflake, Databricks) charge per query, which makes users
  ration queries, and Jane Street's data is on premises. Open-source systems target web clickstream
  workloads, and the team wanted the freedom to say yes to unusual finance uses. The guest learned
  not to ask users whether they had tried not doing something.
- About 10 PB of storage appliances (an eight-figure purchase) was bought in 2022 on the strength of
  a design doc, before the system ran, amid long supply-chain lead times. Teams agreed to adopt it
  on trust before it existed.
- Main regret: CockroachDB as the transactional metadata store (tables and pointers to data).
  Streaming tables commit to the same row many times a second, and each commit is a serialized Raft
  round. The cap is commits per table, not total throughput or query load.
- The fix is to move metadata to Aria, Jane Street's sequencer-based state machine replication over
  reliable multicast. Aria has a single point of failure: losing the sequencer means read-only mode
  until a mostly manual failover. A well-tended machine fails roughly once in four years, and most
  outages come from software bugs anyway.
- The guest now works on the Hive, the research compute cluster (hundreds of thousands of CPU cores
  and over 10,000 GPUs). It began 20 years ago as six Dell boxes, and its growth now comes from
  neural-network training and feature data.
- At that scale the Hive can knock over anything it touches. A classic failure is thousands of
  machines creating files in one NFS directory: each create is effectively a write to the directory.
  The fixes are isolation from trading systems plus frameworks that write in large chunks.
- Before changing the Hive, he spent a month on a trading desk using it, because features he shipped
  went unused when users reached the Hive through other layers.
- Scheduling is a second-price auction in dollars per core-hour or GPU-hour. It cannot express
  urgency: work worth less but decaying fast should run before more valuable work that can wait.
  Users therefore time submissions themselves, some with notebooks forecasting cluster load. Adding
  urgency makes an already NP-hard problem harder (gang scheduling of GPUs, topology, data placement
  across data centers); local search is the plan.
- Starting a job on thousands of cores means copying a large binary to every worker from one source;
  peer-to-peer fan-out in the style of BitTorrent spreads the load, and the incentive problem
  BitTorrent solves does not arise inside one firm.
- Many Hive jobs are task graphs whose steps use Polars. A lazy, declarative graph (as in Polars or
  Spark, unlike eager Pandas) lets the system plan the work like a distributed query, with
  finance-aware sharding by date and symbol.

## Relevance to us

- Directly relevant to [market-data](../../../repos/market-data.md) and
  [parquet](../../../repos/parquet.md). Our day close already uses the same ack-now, compact-later
  split: live sink parts, then one daily file rewritten with an atomic rename.
- We take the opposite stance on file access: DuckDB views read Parquet directly, which is
  reasonable for a small team. The cost Superstore avoided still applies: we have no inventory of
  what exists and no record of what is read.
- Aria's accepted single point of failure supports our current choice of one collector per venue
  until the replication in the [roadmap](../../../roadmap.md) is needed.
- **Data platform:** Owning the catalog is what makes deprecation and schema evolution possible.
  **Action:** add a `market-data catalog -dir D` command to
  [market-data](../../../repos/market-data.md) printing, per table, venues, symbol count, first and
  last date, file count and leftover numbered `.<n>.parquet` parts, with a ppx_expect test over a
  small fixture directory.
- **Research tooling:** Usage logs show who reads what before a table or column is changed.
  **Action:** make `market-data query` in [market-data](../../../repos/market-data.md) append the
  UTC time, user and SQL text to `query-log.ndjson` under the data directory (opt out with a flag),
  so a schema change can first grep real usage.
- **Data platform:** Small files multiply into object-store and metadata cost; Superstore compacts
  between write and read. **Action:** extend `day-close` in
  [market-data](../../../repos/market-data.md) to print, per table and day, the number of input
  event-log frames, sink parts replaced and output bytes, so small-file buildup and compression
  ratio are visible in the CronJob log (part replacement itself is already covered by the existing
  day-close expect test).
- The single-hot-record regret was checked against our one shared-state file: the
  [market-recorder](../../../repos/market-recorder.md) uploader rewrites `upload-pending.sexp` whole
  on each change, but it lists only files not yet uploaded, so at one file per stream and minute it
  stays small; no change needed.

Tags: `data-platform`, `parquet`, `architecture`, `sequencer`, `research-tooling`
