# Performance Engineering on Hard Mode

- Source: <https://signalsandthreads.com/performance-engineering-on-hard-mode/>
- Published: 2023-11-28
- Kind: Signals and Threads episode 18

## Summary

- The guest, a former tcmalloc tech lead now on Jane Street's market data team, learned
  by reading real implementations (Linux virtual memory) and by building a graph traversal
  system that emulated complex hardware, which needed detailed knowledge of memory
  parallelism. Production use, unlike coursework, means owning a system after it ships.
- At hyperscalers, optimization is easy mode: so much is spent on machines that a 0.5%
  gain in shared infrastructure (allocation, serialization, logging, compression; the 10%
  to 20% data center tax) pays for itself. The next target is always the top of the fleet
  profile, whatever the business logic.
- At Jane Street, an average CPU cycle is worth little. Trading systems spend 95% to 99% of
  their time busy-polling for packets, and aim for low latency and burst capacity, not high
  utilization. Throughput jobs such as historical research and model training remain easy
  mode, but chase bigger wins in user wait time.
- Many small improvements are below the noise floor yet add up. Efficient defaults and
  mechanical sympathy (knowing what the CPU will do with the code) matter more than always
  profiling first: computers are arrays and integer arithmetic, not cons cells.
- Hard mode is about latency at the moments that matter, such as sending an order or
  handling a burst of market data. That makes it a measurement problem tied to business
  logic.
- Sampling profilers such as perf interrupt periodically and record stack traces. They can
  sample on branch mispredictions or cache misses to point at the exact bad branch.
  Allocation profiles matter too; hot OCaml code aims for zero heap allocation, and a good
  C++ system spends 5% to 10% of its time in malloc.
- Example: deciding to trade and sending the order were each cheap, but the send happened
  200 microseconds later because an older API queued network writes for idle time. No
  profile can show this; switching to an eager API fixed it.
- Magic-trace uses Intel Processor Trace, a hardware ring buffer of control flow at about
  one bit per branch, to dump the last few milliseconds exactly on demand. It costs about
  5% to 15% while on, so it is enabled only when needed. Intel has not shipped comparable
  easy tooling.
- Profiler and tracer terminology is muddled. Memtrace samples allocations but records each
  sampled one's whole life, like tracing 1% of RPCs end to end.
- Traces often beat profiles even for throughput work: they separate one slow call from a
  thousand cheap calls in a tight loop, and show deep recursion by the shape on screen.
- Flame graphs were a leap forward but hide join points, where many thin stacks converge
  on one function in the middle. pprof's call graph shows them; in C++ that function is
  usually malloc.
- Tools by experts for experts (perf flags whose meaning has drifted) need memorized recipes;
  good defaults and visualizations are underinvested.
- Tails are often just the median repeated during a burst: 1 microsecond per message against
  an 800 nanosecond budget is plain queueing theory. Fixes are batching when behind or making
  each message about 20% cheaper; a profile view of a selected trace range would help.
- Sampling still wins for throughput work and for always-on fleet-wide profiling; the guest
  would like a fleet profile of trading systems that excludes idle spinning.
- The biggest lever is architecture and not doing work at all: avoid calling the function,
  drop an unneeded data source, or move work to another process. Choosing C++ does not fix a
  bad design.
- OCaml costs, from least to most important: weaker code generation (annoying, rarely
  decisive), GC rules such as initializing and nulling arrays, and boxed, pointer-heavy data
  that works against mechanical sympathy.
- Workarounds: DSLs that generate safe accessors over flat memory, first for exchange packet
  formats and then for in-memory structures such as an order book; a zero-alloc dialect that
  avoids the GC; and C calls costing a few nanoseconds versus hundreds through Java's JNI.
  Upcoming layout control in OCaml is the change the guest is most excited about.
- Discipline means leaving known slow code alone when it does not matter.
- Crossing PCIe twice costs about 1 microsecond, while an FPGA on the NIC can respond in
  under 100 ns, but hardware only suits simple logic. Latency goals range from under 100
  ns, through 5 to 20 microseconds, to cutting 50 ms tails to 1 ms, plus human-facing tools.
- Fast feedback loops (OODA: observe, orient, decide, act) matter for research and for
  performance work: a realistic testbed that answers in 10 minutes beats days in production.

## Relevance to us

- Busy-polling and FPGAs do not apply to our Async, network-bound stack, and magic-trace
  needs Intel PT on Linux, so for us it would only work on the deployment hosts.
- **Market making and trading systems:** without measuring time from tick to order, a
  deferred send goes unnoticed. **Action:** record the time from a market data event's
  `recv_ts` to the order send it triggers in a histogram in `Live.Make`, and log p50, p99
  and max when the binary shuts down, in [mm-core](../../../repos/mm-core.md).
- **Market making and trading systems:** the costly bug was a send queued for idle time
  rather than slow code. **Action:** audit the plan execution path in `Live.Make` and the
  venue adapters for `after`, timers or idle-priority scheduling between deciding and
  calling the venue, and note findings in
  [market-maker](../../../repos/market-maker.md)'s specs page.
- **Performance:** burst tails are queueing, and batching when behind is the standard fix.
  **Action:** make the live loop drain all pending book updates and quote once on the
  latest book instead of once per update, in [mm-core](../../../repos/mm-core.md).
- **Performance:** allocation profiles find hot-path allocation quickly. **Action:** run
  memtrace on the recorder during `scripts/e2e-sims.sh` and record the top five
  allocation sites on its specs page, in
  [market-recorder](../../../repos/market-recorder.md).
- **Testing and simulation:** a realistic testbed that answers in minutes speeds up
  performance work. **Action:** have `scripts/e2e-all.sh` print the tick-to-order
  histogram per venue, so a latency change can be judged in one run, in
  [market-maker](../../../repos/market-maker.md).

Tags: `performance`, `latency`, `observability`, `allocation`
