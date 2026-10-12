# Developer education at Jane Street

- Source: <https://blog.janestreet.com/developer-education-at-jane-street-index/>
- Published: 2024-10-04
- Kind: blog post

## Summary

- Besides apprenticeship-style learning on teams, new developers take OCaml Bootcamp (one to
  two weeks covering the language plus dune, expect tests, docs and editor tooling) and,
  later in their first year, Dev Teach-ins: 2-3 day hands-on classes in dedicated classrooms.
- The testing teach-in covers expect tests, Quickcheck, an internal library for tests that
  depend on external data, Netkit for testable networking, and `Async.Time_source` for
  testing time-dependent behaviour.
- The market data teach-in has students build a market data library from scratch: order
  books, exchange feed design including reliable multicast, API performance constraints,
  feed normalization and client pitfalls.
- Other teach-ins: advanced functional programming (GADTs, finger trees, CPS,
  defunctionalization, automatic differentiation), OCaml performance (TSC counters, inline
  benchmarks, perf, memtrace, magic-trace, cache effects), Bonsai web apps, and systems
  debugging (shell, strace, gdb, memory, scheduler, filesystems).
- The firm hires dedicated developer educators and treats teaching as real work.

## Relevance to us

- The testing curriculum names a tool we do not use: none of our repositories takes an
  `Async.Time_source.t`, so the reconnect backoff and silence watchdog in
  [venue-net](../../../repos/venue-net.md) and the timers in
  [mm-core](../../../repos/mm-core.md) and
  [market-recorder](../../../repos/market-recorder.md) run on wall-clock time in tests.
- The market data syllabus (normalization, client gotchas) is a checklist for
  [market-data](../../../repos/market-data.md) and the `Live_feed` modules.
- **Action:** add an optional `?time_source` argument to `Venue_net.Ws_client.connect` used
  by the backoff and silence watchdog, and an expect test that advances a synthetic time
  source to show a reconnect after `max_silent_intervals` without sleeping.

Tags: `education`, `testing`, `async`, `market-data`
