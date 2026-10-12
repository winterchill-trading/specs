# Scaling and benchmarking a critical message bus using a new indexing strategy

- Source: <https://blog.janestreet.com/scaling-and-benchmarking-a-critical-message-bus/>
- Published: 2026-10-05
- Kind: blog post

## Summary

- Aria, the internal sequenced message bus (terabytes per day), keeps the recent stream
  in an in-memory ring buffer; lagging clients catch up from it ("tip recovery") by
  filtering the whole stream down to their topic subtrees with a linear scan.
- As tip recovery grew, servers hit 100% CPU and clients fell off the tip. The fix is an
  index per topic partition (all topics sharing a two-segment prefix; a per-topic index
  was impossible with close to a million topics), merged n-way with a min-heap.
- A profiling tool varied partition count, interleaving and readers; the heap was the
  bottleneck, and an agent benchmarked five heap implementations overnight, picking an
  unboxed one for a 2x gain.
- Index storage uses a shared pool of 1024-entry blocks that are recycled once their
  messages leave the ring, instead of worst-case-sized ring buffers (a tip of 32-byte
  messages would need a 2 GB index per partition).
- Initial recovery (replay since start of week) once took 13 minutes instead of 2.5
  seconds because on-disk "subtree stores" grouped topics by a fixed three-segment rule
  and readers filtered 10x more bytes than needed.
- Adaptive splitting combines greedy clustering with binary search over per-topic volume:
  heavy topics get their own store, light siblings share one. Candidates were scored on
  wasted bytes per read, total and worst case, against data captured from real sessions.
- Testing: expect tests for split properties, a property test with random messages,
  topics and random splits checking order and content, and Antithesis runs. Result: about
  30% less CPU and fewer multi-second tail latencies.

## Relevance to us

- [market-data](../../../repos/market-data.md) event logs and the planned replay server
  ([roadmap](../../../roadmap.md)) face the same question: per-symbol, per-stream files are
  our version of "subtree stores", and a multi-symbol replay is an n-way merge by time.
- The "wasted bytes per read" metric is a concrete way to judge our
  [market-recorder](../../../repos/market-recorder.md) file granularity.
- **Action:** in `market-data`, add a Base_quickcheck property test that writes random
  events for several symbols into separate event logs and checks a heap-based merge
  replays them in global `recv_ts` order with no loss.

Tags: `sequencer`, `replay`, `performance`, `property-testing`, `data-platform`
