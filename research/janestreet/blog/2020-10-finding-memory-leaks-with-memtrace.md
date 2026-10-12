# Finding memory leaks with Memtrace

- Source: <https://blog.janestreet.com/finding-memory-leaks-with-memtrace/>
- Published: 2020-10-06
- Kind: blog post

## Summary

- Introduces the open-source Memtrace library and Memtrace viewer, built on the statistical
  memory profiling hooks added to the OCaml runtime in 4.11.
- Unlike the older Spacetime profiler, it samples allocations, needs no special compiler
  build, works on all platforms and is cheap enough to leave on in production.
- Integration is one library in the dune file plus a call to `Memtrace.trace_if_requested`
  at startup (after any daemonizing fork); the `MEMTRACE` and `MEMTRACE_RATE` environment
  variables turn tracing on and set the sample rate.
- The viewer shows an inverted flame graph (allocation sites with their callers), a live-heap
  timeline, and filters for "allocated between" and "live between" time windows; a table
  view and zooming help with noisy graphs.
- Worked example 1: combining both filters isolates a steady accumulation phase and points
  straight at a traversal function that leaks small arrays.
- Worked example 2: a producer outrunning its consumer through an unbounded queue; a
  roughly 30-line custom analysis over the trace reader plots each queued object's lifetime
  and shows items waiting over 12 seconds at the peak.
- Traces use a compact binary format with microsecond timestamps, readable by user code for
  bespoke analyses.

## Relevance to us

- **Performance:** a sampled allocation trace that is cheap enough for production finds
  leaks with little more than a time-window filter. **Action:** check that `memtrace`
  installs and records on the `5.2.0+ox` switch (it needs the runtime's statistical memory
  profiler, absent from early OCaml 5 releases); if it does, call
  `Memtrace.trace_if_requested ()` at the start of `market-recorder run` in
  [market-recorder](../../../repos/market-recorder.md) and document `MEMTRACE` on its page.
- **Data platform:** a producer outrunning its consumer through an unbounded queue shows up
  as steadily growing object lifetimes. **Action:** add a `market-recorder` test that stalls
  the `Norm_writer` side while feeding simulated input and prints how many events end up
  buffered, to show whether the pipes apply pushback.
- **Build and deploy:** opt-in tracing driven by an environment variable needs no rebuild to
  use in a deployed container. **Action:** add a commented `MEMTRACE` env entry and a
  writable trace path to the recorder Helm values in [infra](../../../repos/infra.md), once
  Memtrace is confirmed to work.
- **Research tooling:** the trace format is readable from OCaml for custom analyses, such as
  lifetime-by-allocation-site plots. **Action:** none until we have a trace worth analysing.

Tags: `gc`, `allocation`, `observability`, `ops`
