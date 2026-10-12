# Building a lower-latency GC

- Source: <https://blog.janestreet.com/building-a-lower-latency-gc/>
- Published: 2015-04-10
- Kind: blog post

## Summary

- Goal: predictable latency in OCaml without resorting to object pooling everywhere, which
  makes code harder to reason about.
- Problems listed with the 4.02 runtime: no visibility into GC phases, false promotions
  from minor collections that happen at awkward moments, a collector clocked only by
  allocation rather than wall time, non-incremental scanning of large arrays and roots, and
  major-slice sizing that forces work immediately after heavy promotion.
- Work done by a visiting runtime expert: GC probes for per-phase profiling, aging in the
  minor heap, interruptible array and root scanning, decoupling major slices from minor
  collections, and work accounting smoothed over a circular buffer of future slices.
- Applications can then schedule GC work from an idle-detection job; credit for forced
  slices is subtracted from the scheduled work.
- Size-segregated free lists were in progress.
- Result: tail latency of one production application dropped by a factor of 3 with little
  tuning; aging gave no clear win for batch jobs.
- Separately run minor collections only when the minor heap is above a configured size, to avoid
  promoting short-lived objects too early.

## Relevance to us

- **Performance:** GC cost must be measured before it can be shaped, and we currently record no GC
  numbers in the trading loop. **Action:** add minor and major collection counts and promoted words
  from `Gc.quick_stat` to `Mm_core.Live.Report` in [mm-core](../../../repos/mm-core.md), so every
  `scripts/e2e-all.sh` run in [market-maker](../../../repos/market-maker.md) shows GC load per
  venue.
- **Performance:** Long-running services need GC behaviour visible over time, not only at exit.
  **Action:** export `Gc.quick_stat` minor and major collection counters and heap words as gauges on
  the `/metrics` endpoint of [market-recorder](../../../repos/market-recorder.md).

Tags: `gc`, `latency`, `allocation`, `observability`
