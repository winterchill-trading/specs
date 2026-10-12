# Swapping the Engine Out of a Moving Race Car

- Source: <https://signalsandthreads.com/swapping-the-engine-out-of-a-moving-race-car/>
- Published: 2022-09-12
- Kind: Signals and Threads episode 15

## Summary

- Gord, about 15 years old, collects all of Jane Street's trading activity from venues
  worldwide, normalizes it, and serves it to hundreds of internal clients for positions,
  short-sale marking, risk, clearing uploads, settlement and regulatory reporting.
- If Gord is down the firm stops trading, so it is built to fail in isolated pieces (one
  bad exchange feed must not affect others). It runs a hot standby in another data center
  that processes the same flow, because machine failures are common at this scale.
- Capacity target: at least 2x the busiest day ever. New peak days tend to jump 2x to 5x
  over the old record, and today's normal days match the old record days.
- Input path: parsers SSH to source boxes and tail pipe-separated FIX-style tag=value files.
  An early promise to always deliver correct-looking data made Gord invent orders for fills
  that arrived without one, and later consumers came to rely on that.
- Normalization covers symbology (Reuters codes, Bloomberg symbols, venue codes, harder
  outside US equities), usernames and many other fields. It is moving toward the source
  systems, which understand their own venues best.
- The original data model had only orders, outs and fills. Rejects were encoded as an
  invented order plus a close, and corrections and allocations as cancel-and-rebook of
  whole fills, so new concepts were forced into types that did not fit.
- Extra fields went into a string map because the top-level bin_io type could not change
  without every client rolling. The free-form format looked easy to evolve, but clients
  relied on its implicit structure, so real changes still broke them. Adding optional
  fields was easy; adding a new transaction kind was not.
- Per-client downgrades on the server meant serializing each message once per client
  version, and serialization is one of Gord's largest costs. Small, frequent messages got a
  new compact format.
- Architecture: parser, then DB (which adds the invented records), then a normalizer in
  each office, then clients directly over TCP. Fan-out to hundreds of clients was the main
  scaling problem.
- No contract limited how fast sources could send; Gord simply had to keep up. The guest
  added performance tests to find the limit: about 50,000 messages per second per pipeline,
  25,000 allowed in practice. Throughput scales by sharding sources over more pipelines.
- Order is guaranteed only within one source, which keeps the system loosely coupled and
  lets offices keep running when links between them degrade. Global order across exchanges
  means little anyway, given exchange-side delays.
- Push over TCP buffered data per client and disconnected slow clients, even though many
  clients (end-of-day reporting) only need to finish by day's end. Kafka's pull model keeps
  data on disk, lets slow readers fall behind with alerts instead of dying, and replaces
  per-client snapshots with one side process that writes snapshots periodically.
- Producers now fill typed records per message kind (a bond fill, for example) through a
  library, instead of asking the Gord team which of a hundred FIX tags are required. The
  plan is typed structure end to end, so type changes flow through the monorepo.
- Instead of the full stream or fills only (plus a later monitoring stream), clients can
  subscribe to fixed sub-streams such as options; arbitrary predicates are a later goal.
- Process changes: from almost no in-code tests and days of diffing dev output against
  production, to unit and whole-pipeline in-code tests plus a performance test on every
  release. Releases went from a few per year to monthly.
- Releasing used to mean flipping a production symlink by hand in three regions, each
  within a narrow window; one missed flip caused a big incident. A dated config now
  schedules which instance is primary per day, set days ahead.
- The daily start and stop helps with archiving and maintenance but blocks 24/7 operation,
  which needs boxes that join and leave dynamically.
- The second half covers recruiting programs (INSIGHT, IN FOCUS, a women-in-tech brunch)
  with about 20% of attendees reaching internships; not relevant to us.

## Relevance to us

- The client `Live_feed` normalizers and [market-data](../../../repos/market-data.md) play
  a small version of Gord's role: venue codes become `Instrument` values, ordering is
  promised per stream only, and `Market_data.Event` is already a typed variant with pinned
  `Stable.V1` shapes rather than a bag of fields.
- **Performance:** knowing the per-pipeline ceiling is the only way to know the headroom
  for a 2x to 5x busy day. **Action:** add a `bench` executable that pushes one recorded
  raw minute file through a venue normalizer and the `Event_log` writer and prints messages
  per second, then record the number on its specs page, in
  [market-recorder](../../../repos/market-recorder.md).
- **Data platform:** made-up values become facts that consumers rely on; record what the
  venue did not send as absent. **Action:** add a `Funding.Stable.V2` with an optional
  `exch_ts`, written as absent for Hyperliquid instead of copying `recv_ts`, in
  [market-data](../../../repos/market-data.md) and
  [hl-client](../../../repos/hl-client.md).
- **Data platform:** slow consumers should lag visibly, not lose data silently.
  **Action:** expose the count of rows `Parquet_sink` dropped past `max_pending_rows` and
  add it to the `/metrics` output in [market-recorder](../../../repos/market-recorder.md)
  wherever the sink is used, in [market-data](../../../repos/market-data.md).
- **Testing and simulation:** whole-pipeline in-code tests replaced manual diffing and
  made monthly releases safe. **Action:** run `scripts/e2e-sims.sh` (sims, recorder,
  `/healthz` and `/metrics` checks) in CI for
  [market-recorder](../../../repos/market-recorder.md), if it is not already there.
- **Build and deploy:** hand-timed production switches fail eventually; schedule them in
  config. Our planned two-region collectors will need the same. Context only until
  replication is designed.

Tags: `architecture`, `market-data`, `stable-types`, `performance`, `ops`
