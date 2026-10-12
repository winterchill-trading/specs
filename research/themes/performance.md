# Performance

This theme gathers what the Jane Street blog and Signals and Threads say about making OCaml
systems fast and predictable: allocation and the garbage collector, the optimizer (Flambda,
feedback-directed layout), unboxed and local values in OxCaml, profiling with memtrace and
magic-trace, benchmarking with core_bench, latency tails, hardware and networking, and the
indexing work behind a large message bus. It matters to us because every hot path in the org
(order matching, quoting, feed normalization, recording) is written in OxCaml on a
single-threaded Async runtime, and today none of those paths has a measured baseline: we cannot
tell whether a change made them faster, slower, or quietly allocating again.

## Allocation is the cost model

Across sources the recurring claim is that in OCaml the first-order cost is not instructions but
allocation. Minor allocation is a pointer bump, yet each word fills the minor heap, brings the
next collection closer, evicts cache lines and promotes survivors into the expensive major heap
([locality](../janestreet/blog/2023-05-oxidizing-ocaml-locality.md),
[episode 13](../janestreet/podcast/13-memory-management.md)). The uniform one-word
representation adds a second cost: boxed `Int32`, tuples built only to return two values, and
pointer-heavy records that defeat the cache. The performance engineer in
[episode 18](../janestreet/podcast/18-performance-engineering-on-hard-mode.md) ranks this above
weak code generation as OCaml's real handicap, and the language design guest in
[episode 7](../janestreet/podcast/07-language-design.md) names layout and stack allocation as
the missing pieces.

The remedies form a progression. Immediate `int`s avoid headers and pointer tests at the cost
of a tag bit and slower multiplication
([63-bit integers](../janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md));
compiler fixes removed needless float boxing
([float unboxing](../janestreet/blog/2008-08-better-float-unboxing.md)); GADTs let one API pick
a compact representation without closures
([GADTs for performance](../janestreet/blog/2015-03-why-gadts-matter-for-performance.md)). OxCaml
then makes the control explicit: `local` values live on a separate stack and `exclave` returns
them into the caller's region, layouts let unboxed tuples travel in registers, and exporting
immediacy tells the compiler an abstract type is never a pointer
([ICFP 2024](../janestreet/blog/2024-08-icfp-2024.md),
[introducing OxCaml](../janestreet/blog/2025-06-introducing-oxcaml.md)). The common caveat is
that these tools pay off only where allocation has been shown to matter.

## The optimizer helps, but not predictably

Flambda's case was that inlining in OCaml mostly pays by exposing allocations to removal:
closures passed to folds, options built and immediately matched, functor indirection
([Flambda](../janestreet/blog/2016-02-flambda.md)). Real applications saw roughly 20-30% fewer
allocations. The price is predictability, since inlining thresholds decide whether an allocation
disappears. Later sources show the same tension from the other side: magic-trace found a 100 ns
regression and a compiler-upgrade slowdown that were both lost inlining
([magic-trace](../janestreet/blog/2022-01-magic-trace.md)), and feedback-directed optimization
gave 10-20% from code layout alone while also making timings stable enough that small changes
became measurable ([episode 4](../janestreet/podcast/04-compiler-optimization.md)). For us the
lesson is that compiler flags and upgrades are performance events and need a benchmark to judge
them, not an assumption that `-O3` or a newer `ox` commit is better.

## Measure with regression and repetition, not a stopwatch

Core_bench exists because naive timing of short functions is dominated by clock cost and by GC
periodicity: a batch triggers n or n+1 collections and the results go multi-modal. It fits time
against geometrically growing batch sizes, so the slope is cost per run and GC is amortized in,
and it reports minor, promoted and major words per run alongside time
([core_bench](../janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md)). Episode 4
adds that code layout alone shifts single runs, so a baseline needs repeats and a spread.

The allocator post widens this from micro to whole program: in a collected language one run is a
single point on a space/time curve set by `space_overhead`, and `top_heap_size` misstates memory
where RSS does not; only a sweep showed the new allocator winning everywhere
([allocator showdown](../janestreet/blog/2020-09-memory-allocator-showdown.md)). Two system-level
examples show the payoff of cheap, repeatable measurement: the trade-collection pipeline learned
its per-pipeline ceiling (about 50,000 messages per second) only once a performance test ran on
every release ([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md)),
and the message bus team had an agent write and benchmark five heap implementations overnight,
picking an unboxed heap that doubled recovery speed
([Aria indexing](../janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md)).
Hot code can also be pinned in tests: printing `Gc.minor_words` per operation in an expect test
turns any reintroduced allocation into a diff.

## Long-running processes need GC and memory made visible

The lower-latency GC work started from having no visibility into GC phases, then added probes,
minor-heap aging, interruptible scanning and smoothed major slices, cutting one application's
tail latency by a factor of three
([lower-latency GC](../janestreet/blog/2015-04-building-a-lower-latency-gc.md)). Episode 13
explains the opposite tunings seen in practice (a bigger minor heap cuts promotion, a smaller one
keeps tight code in cache) and why caller-provided buffers suit a tracing GC.

For leaks and unexpected allocation the tooling moved from Spacetime, which needed a special
compiler ([Spacetime](../janestreet/blog/2017-01-a-brief-trip-through-spacetime.md)), to
memtrace, which samples allocations cheaply enough for production, turns on through an
environment variable after one startup call, and finds leaks with "allocated between" and "live
between" filters ([memtrace](../janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md)).
Its second worked example, a producer outrunning a consumer through an unbounded queue, is
exactly the failure a recorder can have. Memtrace is also the standard tool taught to new
developers ([developer education](../janestreet/blog/2024-10-developer-education-at-jane-street.md)),
and container limits act on RSS, not on what `Gc.stat` reports.

## Tails come from queueing and scheduling more than from slow code

Several sources agree that the median is the wrong number. Hardware designers measure about
20 ns between p10 and p99 while software tails reach microseconds, and CPUs fall behind exactly
when markets are busiest ([episode 1](../janestreet/podcast/01-programmable-hardware.md)).
Episode 18 makes two points that apply directly to us. First, burst tails are often the median
repeated under load, plain queueing, so the fixes are batching when behind or making each
message cheaper. Second, the worst latency bug it describes was not slow code at all: an order
send was queued for idle time and went out 200 microseconds late, invisible to any profile.

In single-threaded Async programs the equivalent is a long scheduler cycle: one big resync or
flush delays every feed, and magic-trace's first practical trigger was a cycle exceeding a
threshold. Timeouts are another scheduling trap: a timeout that abandons rather than cancels
leaves work that all fires at once on recovery
([network maintenance](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md)).
Fan-out has the same shape: a publisher must never slow down for one slow consumer, which is why
reliable multicast schemes that let a straggler throttle the sender were rejected
([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md)). Latency is also most
useful as a distribution over time of day
([interns 2019](../janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md)).

## Traces answer what profiles cannot

Sampling profilers see one stack every few hundred microseconds and cannot tell one slow call
from a thousand cheap ones. Magic-trace uses Intel Processor Trace to keep the last few
milliseconds of control flow and dump it on demand, at a cost of a few percent while attached,
but it needs a recent Intel CPU with PT exposed, which most cloud VMs lack (magic-trace,
episode 18). Episode 18 adds that flame graphs hide join points where many thin stacks meet,
and memtrace is really a sampled tracer of object lifetimes. Dynamic probes on a live binary
(SystemTap there, `perf` or `bpftrace` uprobes for us) answer questions logs cannot
([SystemTap](../janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md)). Before any
of this, check the environment: the binary and libraries actually running, CPU affinity, NUMA
placement, VM versus bare metal, and host drift
([systems tricks](../janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md)).

## Hardware and the network set the floor

The hardware and networking sources give a useful latency scale even though we run none of it.
FPGA NICs parse and filter venue feeds at line rate with near-deterministic timing; crossing
PCIe twice costs about a microsecond while an on-NIC response can be under 100 ns
(episodes [1](../janestreet/podcast/01-programmable-hardware.md) and
[18](../janestreet/podcast/18-performance-engineering-on-hard-mode.md)). Episode 3 lists the
rest: cut-through switches at hundreds of nanoseconds, layer 1 replication at a few, a context
switch at a microsecond or two, and serialization at about 1 ns per byte at 10 Gbps, which is
why unicasting to hundreds of clients cannot compete with multicast. Multicast in turn suits
trading but not clouds ([episode 27](../janestreet/podcast/27-the-network-as-a-program.md)), and
failing over to a farther site is a latency change, not a transparent swap
([episode 24](../janestreet/podcast/24-the-thermodynamics-of-trading.md)). Low-latency hardware
favors short pipelines over clever arithmetic
([low-latency multipliers](../janestreet/blog/2020-06-really-low-latency-multipliers-and-cryptographic-puzzles.md)).
The practical takeaway for a websocket-based crypto stack is mechanical sympathy rather than
hardware: know the floor, and remember the biggest lever is not doing the work at all.

## Index and lay out data by how it is read

The message bus post is the clearest systems case. Filtering a whole in-memory ring per
subscriber was cache friendly but went to 100% CPU as catch-up traffic grew; per-topic indexes
were impossible at a million topics, so it indexes per topic partition and rebuilds order with an
n-way min-heap merge, drawing index memory from a shared pool of fixed blocks recycled as the ring
advances. On disk, grouping topics by a fixed name prefix forced readers to skip a busy
neighbor's bytes, and adaptive splitting was scored by wasted bytes per read. Result: about 30%
less CPU and no more multi-second tails (Aria indexing). Our multi-symbol replay is the same
n-way merge over per-stream files. Parallelism is the other lever: OCaml 5 domains, with races
kept local by OxCaml modes, make splitting independent work across cores safe to try
([episode 12](../janestreet/podcast/12-what-is-an-operating-system.md)).

## Where we stand

- No repository depends on `core_bench` or `memtrace`, and no code calls `Gc` anywhere in the
  org. Both packages are published in the `ox` opam repository at a v0.18 preview but are not
  installed on the `5.2.0+ox` switch. The only benchmark is a plain throughput executable in
  [parquet](../../repos/parquet.md) (`bench/bench.exe`).
- [order-book](../../repos/order-book.md) already passes the matching context `local_` and
  returns sweep results with `exclave_`, but `best_bid`, `best_ask` and `mid` return
  `Price.t option`, so each call may allocate a `Some`; nothing measures it.
- [fixed-decimal](../../repos/fixed-decimal.md) exports `type t` abstractly from `Make` with no
  `[@@immediate]` annotation, so callers cannot rely on the `int` representation.
- [mm-core](../../repos/mm-core.md) `Live.Make` already batches when behind: each book update
  only folds into `Strategy` state, and a `step_queued` flag lets at most one tick wait, so a
  burst is quoted once on the latest book. `Live.Report` holds fills, PnL and order counts but
  no latency or GC figures.
- [market-recorder](../../repos/market-recorder.md) `/metrics` exports frame, byte, event,
  last-frame-age and upload counters only; no GC, RSS or Async long-cycle gauges.
- `with_timeout` appears in [binance-client](../../repos/binance-client.md) `Market_ws`,
  [bybit-client](../../repos/bybit-client.md) `Ws_stream`, `Live` in mm-core, and the recorder's
  `Recorder` and `Uploader`; [venue-net](../../repos/venue-net.md) itself uses
  `Clock_ns.after` raced against a close ivar instead.
- [hl-sim](../../repos/hl-sim.md) writes to each websocket subscriber with
  `write_without_pushback_if_open`, so a slow reader cannot block the publisher but its queue
  grows without bound, and no test covers a never-reading subscriber.

## Proposed actions

1. Add a core_bench `bench/` executable to [order-book](../../repos/order-book.md) timing
   submit, cancel and match on a seeded book with about 1000 resting levels, reporting time and
   minor words per run, and record the baseline in the README
   ([core_bench](../janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md),
   [Flambda](../janestreet/blog/2016-02-flambda.md),
   [episode 4](../janestreet/podcast/04-compiler-optimization.md),
   [Aria indexing](../janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md)).
2. Add an expect test in [order-book](../../repos/order-book.md) printing `Gc.minor_words` per
   operation over 10,000 submit/cancel cycles and 10,000 `best_bid`/`mid` calls; if the latter
   is non-zero, add local-returning variants with `exclave_`
   ([episode 13](../janestreet/podcast/13-memory-management.md),
   [locality](../janestreet/blog/2023-05-oxidizing-ocaml-locality.md)).
3. Record tick-to-order latency (`recv_ts` of the triggering event to venue call) as p50, p99
   and max in `Live.Report` of [mm-core](../../repos/mm-core.md), and have
   [market-maker](../../repos/market-maker.md) `scripts/e2e-all.sh` print it per venue
   ([episode 1](../janestreet/podcast/01-programmable-hardware.md),
   [episode 18](../janestreet/podcast/18-performance-engineering-on-hard-mode.md)).
4. Export `Gc.quick_stat` heap words, minor and major collection counts, and process RSS from
   `/proc/self/statm` on [market-recorder](../../repos/market-recorder.md) `/metrics`, and add
   collection counts and promoted words to `Live.Report` in [mm-core](../../repos/mm-core.md)
   ([lower-latency GC](../janestreet/blog/2015-04-building-a-lower-latency-gc.md),
   [episode 13](../janestreet/podcast/13-memory-management.md),
   [allocator showdown](../janestreet/blog/2020-09-memory-allocator-showdown.md)).
5. Install memtrace on the `5.2.0+ox` switch and confirm it records; if so, call
   `Memtrace.trace_if_requested` at the start of `market-recorder run`
   ([market-recorder](../../repos/market-recorder.md)), run it during `scripts/e2e-sims.sh` and
   record the top five allocation sites on its page, then add a commented `MEMTRACE` entry to
   the Helm values in [infra](../../repos/infra.md)
   ([memtrace](../janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md),
   [Spacetime](../janestreet/blog/2017-01-a-brief-trip-through-spacetime.md),
   [developer education](../janestreet/blog/2024-10-developer-education-at-jane-street.md),
   [episode 18](../janestreet/podcast/18-performance-engineering-on-hard-mode.md)).
6. Count Async cycles over 50 ms and the maximum cycle time on
   [market-recorder](../../repos/market-recorder.md) `/metrics`, and log a warning from the
   [market-maker](../../repos/market-maker.md) binary for any cycle over 20 ms
   ([magic-trace](../janestreet/blog/2022-01-magic-trace.md)).
7. Audit every `with_timeout` in the three clients, [mm-core](../../repos/mm-core.md) and
   [market-recorder](../../repos/market-recorder.md) (and timer races in
   [venue-net](../../repos/venue-net.md)) for abandoned-but-running work, and log the findings
   in [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md) `GOTCHAS.md`
   ([network maintenance](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md)).
8. Add a market-recorder `bench` executable that pushes one recorded raw minute through a venue
   normalizer and the `Event_log` writer, printing messages per second and allocated bytes per
   frame on the `on_raw` to `Raw_writer` path, and record both on its page
   ([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md),
   [FUSE server](../janestreet/blog/2026-10-linux-engineering-depot-fuse.md)).
9. Mark `type t` `[@@immediate]` in the `Fixed_decimal.Make` signature with an `Obj.is_int` test,
   and add a core_bench for `mul`, `div` and `Product.mul` against `Int.( * )` confirming zero
   words per run, in [fixed-decimal](../../repos/fixed-decimal.md)
   ([ICFP 2024](../janestreet/blog/2024-08-icfp-2024.md),
   [63-bit integers](../janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md)).
10. Add an expect test in [mm-core](../../repos/mm-core.md) printing minor words per
    `Quoter.quote` call for a fixed `Market_state` and inventory
    ([core_bench](../janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md),
    [locality](../janestreet/blog/2023-05-oxidizing-ocaml-locality.md)).
11. In [binance-client](../../repos/binance-client.md), add a core_bench of `Feed_normalizer`
    over a recorded minute reporting ns per frame, and print `Gc.minor_words` per message in
    the `Live_feed` test
    ([episode 21](../janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md),
    [interns 2022](../janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md)).
12. Add an [hl-sim](../../repos/hl-sim.md) test where one websocket subscriber never reads,
    checking other clients' order acks are not delayed and the stalled queue is bounded or
    dropped ([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md)).
13. Document in [infra](../../repos/infra.md) how to compare GC settings: run the recorder sims
    end to end under `OCAMLRUNPARAM=o=40`, `80` and `160`, recording peak RSS and CPU time
    ([allocator showdown](../janestreet/blog/2020-09-memory-allocator-showdown.md)).
14. Once the order-book bench exists, compare the default release build with `-O3` and log the
    result in [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md) `GOTCHAS.md`
    ([episode 4](../janestreet/podcast/04-compiler-optimization.md)).
15. List in the [order-book](../../repos/order-book.md) README the hot-path records that would
    gain from unboxed fields, mixed blocks or `or_null`, as a checklist for a later OxCaml pass
    ([episode 7](../janestreet/podcast/07-language-design.md),
    [ICFP 2024](../janestreet/blog/2024-08-icfp-2024.md)).
16. Check whether the `Framed` reader in [market-data](../../repos/market-data.md) allocates a
    buffer per frame and, if so, add a variant decoding into a caller-supplied buffer
    ([episode 13](../janestreet/podcast/13-memory-management.md)).
17. Add a per-minute p50/p99 `recv_ts - exch_ts` view per venue and stream to
    `Parquet_views` in [market-data](../../repos/market-data.md), and a latest-lag gauge per
    stream on [market-recorder](../../repos/market-recorder.md) `/metrics`
    ([interns 2019](../janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md),
    [episode 24](../janestreet/podcast/24-the-thermodynamics-of-trading.md)).
18. Add a `GOTCHAS.md` note in [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md) on
    running `perf` or `bpftrace` uprobes against OCaml symbols in the recorder container, and
    on magic-trace needing bare metal with Intel PT
    ([SystemTap](../janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md),
    [magic-trace](../janestreet/blog/2022-01-magic-trace.md)).
19. Measure per-table `day-close` time in [market-data](../../repos/market-data.md) and, if one
    table dominates, prototype a `-jobs` flag that writes tables on separate domains
    ([episode 12](../janestreet/podcast/12-what-is-an-operating-system.md)).
