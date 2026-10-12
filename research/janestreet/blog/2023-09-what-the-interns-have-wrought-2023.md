# What the interns have wrought, 2023 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2023/>
- Published: 2023-09-12
- Kind: blog post

## Summary

- The 2023 program had 152 software engineering interns from 58 schools in 19 countries,
  plus 31 interns in production, IT and network engineering.
- Concord, the platform through which counterparties trade with or through the firm, is
  built on one totally ordered transaction stream, which doubles as a detailed debugging
  record, but tooling could only fetch individual messages.
- An existing linear temporal logic (next, until) query engine over the stream went unused,
  because translating real questions into LTL was hard and queries had to be written as
  s-expressions.
- An intern built a SQL-like frontend (`FIND ... THEN FIRST ... WHERE ... PRINT`) parsed with
  Angstrom, where the hardest part was good error messages; it adds operators such as
  `LAST p BEFORE q` and `NO MESSAGE p BEFORE q`.
- It became the team's go-to tool for debugging performance (for example order-to-first-fill
  latency), and other teams asked for it on their systems.
- A pure OCaml tokenizer replaced a Python tiktoken server so token counts work in the
  browser client of the firm's AI chat front-end; no OCaml regex library fit, so the
  tokenizer regex became a handwritten automaton.
- Exact conformance testing proved too strict (Unicode version differences cause rare
  mismatches), so the differential stress test was relaxed; a functional first version was
  rewritten imperatively with hash tables and arrays for speed.
- It ended slightly faster than the Rust reference for one vendor's tokenizer and nearly 2x
  for another, with higher variance attributed to GC.
- `ppx_tracing` (`@trace` annotations, Perfetto UI) could not follow Async code; the intern
  added `@trace.async`, storing a correlation ID in the Async execution context so concurrent
  calls are told apart, with synchronous calls attaching to the current async parent and
  Fuchsia trace format support for the new events.
- Another team used it to cut its code review server's startup time by about half within
  days; integration with a distributed tracing system is planned.

## Relevance to us

- **Data platform:** "last X before Y" questions are what our recorded data invites (last BBO
  before each trade), and [market-data](../../../repos/market-data.md) already exposes
  Parquet to DuckDB, whose `ASOF JOIN` expresses this without a new language. **Action:** add
  a `trades_with_bbo` view to `Parquet_views` joining each trade to the last BBO at or
  before its `recv_ts`, tested over a small fixture day.
- **Logs and state machines:** order-to-first-fill latency is the market maker's key
  operational number, but its order events are not recorded anywhere queryable.
  **Action:** have the `market-maker` binary in [market-maker](../../../repos/market-maker.md)
  write placed, acked, filled and cancelled order events with timestamps to a `market-data`
  style event log, so the same SQL can compute place-to-ack and place-to-fill times.
- **Performance:** Async-aware tracing would explain where time goes inside the
  [mm-core](../../../repos/mm-core.md) `Live.Make` loop, but `ppx_tracing` is not in our
  dependency set, so this is a larger, later step. Context only.

Tags: `observability`, `data-platform`, `async`, `research-tooling`, `trading`
