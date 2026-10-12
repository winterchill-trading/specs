# Developer education at Jane Street

- Source: <https://blog.janestreet.com/developer-education-at-jane-street-index/>
- Published: 2024-10-04
- Kind: blog post

## Summary

- Most learning is apprenticeship-style (team matching, chosen projects, mentorship, code
  review, teammates nearby), but the firm also invests in classroom teaching, which spreads
  tacit knowledge about who knows what and recent hard lessons.
- New developers take OCaml Bootcamp, one to two weeks that ramp from syntax to small apps and
  quietly introduce the key tools (dune, expect tests, docs, editor integration); interns do
  it as a class with lectures and TAs, alongside Real World OCaml.
- Later in the first year come Dev Teach-ins: 2-3 day hands-on classes in dedicated
  classrooms, meant to broaden developers' view of the firm, with managers making room for
  attendance.
- The testing teach-in covers expect tests and Quickcheck plus tools for larger scopes: an
  internal library that automates tests depending on hard-to-simulate external data, Netkit
  for testable networked systems, and `Async.Time_source` for time-dependent behaviour.
- The market data teach-in has students build a market data library from scratch: how an
  order book works, exchange feed design including reliable multicast, API performance
  constraints, feed normalization and common client pitfalls.
- The advanced functional programming teach-in covers GADTs and parameterized types for safer
  APIs (debugging a symbology distribution system), finger trees, CPS and
  defunctionalization applied to a parallel job system, and automatic differentiation.
- The OCaml performance teach-in covers time-stamp counters, inline benchmarks, perf,
  memtrace and magic-trace, microbenchmark pitfalls, cache-hierarchy experiments, average
  versus rare critical paths, and FFI quirks.
- Other teach-ins: Bonsai web apps (virtual DOM, incremental state, a live market data table,
  Chrome tracing) and systems debugging (shell, strace, coredumpctl, gdb, memory, scheduler,
  networking, filesystems, the kernel itself).
- Education is treated as real work, with classrooms in every office and dedicated developer
  educators improving the programs.

## Relevance to us

- **Testing and simulation:** none of our repositories takes an `Async.Time_source.t`, so the
  reconnect backoff and silence watchdog in [venue-net](../../../repos/venue-net.md) are
  tested on wall-clock time. **Action:** add an optional `?time_source` argument to
  `Venue_net.Ws_client.connect`, used by the backoff and watchdog, and an expect test that
  advances a synthetic time source to show a reconnect after `max_silent_intervals`.
- **Testing and simulation:** the same applies to the timers in
  [mm-core](../../../repos/mm-core.md)'s `Live.Make` (requote interval, stale-data checks).
  **Action:** thread a `Time_source.t` through `Live.Make` and convert one live-loop test to
  advance synthetic time instead of sleeping.
- **Data platform:** the market data syllabus (normalization, client pitfalls) is a checklist
  our `Live_feed` modules should satisfy. **Action:** add a "client pitfalls" list to the
  data-platform design page in `specs` (snapshot and diff sequencing, gap detection, resync
  after reconnect), each item linked to the client test that covers it or marked missing.
- **Performance:** memtrace is the standard allocation profiler in this toolchain.
  **Action:** call `Memtrace.trace_if_requested` at startup of the
  [market-recorder](../../../repos/market-recorder.md) binary so setting `MEMTRACE` yields a
  trace of a live run.

Tags: `education`, `testing`, `async`, `market-data`, `performance`
