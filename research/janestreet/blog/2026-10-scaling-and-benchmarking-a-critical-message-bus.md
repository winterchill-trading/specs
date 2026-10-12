# Scaling and benchmarking a critical message bus using a new indexing strategy

- Source: <https://blog.janestreet.com/scaling-and-benchmarking-a-critical-message-bus/>
- Published: 2026-10-05
- Kind: blog post

## Summary

- Aria is the firm's internal sequenced message bus and hosted service, carrying
  terabytes per day; growth forced repeated re-architecture. An intern project targeted
  cheaper reads of a subset of messages and cut CPU by about 30% on production workloads.
- Aria keeps the recent stream (the "tip") in an in-memory ring buffer; a client that
  falls behind catches up from it ("tip recovery").
- Topics form a hierarchical, file-system-like namespace; clients subscribe to a topic or
  a subtree, and Aria used to filter the whole ring linearly for each subscription. That
  is cache friendly, but as tip recovery grew some servers hit 100% CPU and clients "fell
  off the tip". Adding servers was only a stopgap.
- A per-topic index was impossible (close to a million topics per instance), so the index
  is per topic partition: all topics sharing a two-segment prefix. A request merges the
  relevant partition indexes n-way with a min-heap to rebuild the ordered stream.
- A profiling tool varied partition count, interleaving and reader count. The heap was the
  bottleneck; an agent was asked to write and benchmark five heap implementations
  overnight, and an unboxed heap doubled indexed-recovery speed.
- Validation: many expect tests, Antithesis runs, and a "swarm" of agents reviewing the
  code.
- Index memory: per-index ring buffers would need worst-case sizing (32-byte messages
  would imply a 2 GB index per partition), so indexes draw from a shared pool of
  1024-entry blocks that are recycled once their messages leave the ring.
- Initial recovery (a restarting client replays everything since the start of the week,
  often millions to billions of messages, with many clients restarting together) once
  took over 13 minutes instead of under 2.5 seconds because Aria read 10x more data than
  needed.
- On disk, messages land in chronological per-partition segments, then a separate process
  splits them into "subtree stores". The old rule grouped by the first three topic segments,
  so a quiet topic stored next to a busy one forced readers to skip the busy one's bytes,
  and users had to design topic names around that internal rule.
- Adaptive splitting uses per-topic volumes (known after persistence): greedy clustering
  plus binary search gives big topics their own store and folds small siblings together.
  Candidates were scored on recorded session data by wasted bytes per read, total wasted
  bytes, the worst topic, and the worst useful-byte ratio, with a quickly built web UI to
  visualize them.
- Testing the splitter: expect tests for the intended properties, an existing property
  test extended to randomize the split (random messages on random topics, then reading
  random subtrees and checking order and content), and Antithesis runs.
- Tip indexing is in production with about 30% lower CPU in staging scenarios and no more
  multi-second tail latencies on upgraded servers; adaptive splitting was in staging.

## Relevance to us

- **Data platform:** a multi-symbol replay is an n-way merge of per-stream files, and its
  cost is dominated by how files are grouped. **Action:** add a Base_quickcheck property
  test in [market-data](../../../repos/market-data.md) that writes random events for
  several symbols and streams to `Event_log`, replays them through `Merge`, and checks
  global `recv_ts` order and that no event is lost or duplicated.
- **Data platform:** "wasted bytes per read" is a concrete metric for choosing file
  granularity. **Action:** in `specs`, add to the data-platform design page a DuckDB query
  over one recorded day that reports bytes per venue, stream and symbol, to decide whether
  the planned replay server ([roadmap](../../../roadmap.md)) needs files merged or split.
- **Performance:** cheap agent-run benchmark sweeps of several implementations beat
  picking one by intuition. **Action:** add a `bench/` executable in
  [order-book](../../../repos/order-book.md) that times `submit` and `cancel` on a
  synthetic book, so alternative price-level structures can be compared by number.
- **Testing and simulation:** randomizing an internal layout choice (how the tree is
  split) inside a property test proves the observable output does not depend on it.
  **Action:** in [market-data](../../../repos/market-data.md), add a property test that
  writes the same events with random `Framed` buffer and flush sizes and checks the read
  back events are identical.

Tags: `sequencer`, `replay`, `performance`, `property-testing`, `data-platform`
