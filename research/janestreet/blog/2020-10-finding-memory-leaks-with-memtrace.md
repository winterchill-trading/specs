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

- [market-recorder](../../../repos/market-recorder.md) is a long-running process that
  pipes frames from the three `Live_feed`s into writers and an uploader; a slow disk or
  upload stalls are exactly the unbounded-queue failure the second example shows.
- [market-maker](../../../repos/market-maker.md) and the simulators are also long-lived and
  would benefit from an opt-in heap trace.
- Caveat: Memtrace relies on the runtime's statistical memory profiler, which was missing
  from early OCaml 5 releases; whether the `5.2.0+ox` switch supports it must be checked.
- **Action:** check that `memtrace` installs and records a trace on the `5.2.0+ox` switch; if
  it does, add `Memtrace.trace_if_requested ()` to the `market-recorder run` entry point and
  note the `MEMTRACE` variable in its repo page.

Tags: `gc`, `allocation`, `observability`, `ops`
