# What the interns have wrought, 2024 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2024-edition-index/>
- Published: 2024-08-26
- Kind: blog post

## Summary

- Camels is a first version of a pure OCaml dataframe library in the style of Polars; the
  firm's Polars bindings suffered from slow Rust builds without good incrementality and from
  hard-to-fix bugs, while OxCaml is gaining the data-race freedom and unboxed types that make
  Polars fast.
- Camels separates syntax from semantics: expressions describe a computation that is compiled
  before execution; broadcasting a scalar to a column is explicit, and a phantom length type
  (one versus input) turns a missing broadcast into a compile error.
- Planned Camels work: SIMD and multicore backends, expression fusion and query planning.
- A speed-over-size variant of bin_prot targets transaction logging from latency-sensitive
  systems, which write compact binary for a slower process to format later.
- It drops bin_prot's variable-length integers so runs of adjacent non-pointer fields can be
  copied with one `memcpy`; the serializer is driven by `typerep` rather than a new ppx, with
  some C for bit manipulation.
- A surprise along the way: `Obj.unsafe_ith_field` allocates on all-float records, so a C
  replacement was needed; the format beat bin_prot in every benchmark (10-20% on small
  messages, up to 15x on large flat ones) and cut production tail latencies by 30-65%, with
  no incidents thanks to extensive Quickcheck round-trip tests.
- Limshare dynamically allocates risk limits across trading systems instead of static
  configuration; it is an Aria app, a replicated state machine whose state is rebuilt by
  replaying one global log, and its debugger could only step forward from the start of day.
- The intern added periodic snapshots (and snapshotting to Limshare itself) so the debugger
  can step backwards by restoring the last snapshot and replaying forward; it supports
  breakpoints such as "a request was rejected", time steps, and tabular state dumps.
- A worked example traces a rejected limit request to an oversized reservation held for
  minutes, which revealed a bug; the Aria team adopted the debugger as a general tool.

## Relevance to us

- **Logs and state machines:** the log-plus-snapshot debugger maps onto our append-only
  `Event_log` and `Replay_feed`, but nothing lets a person inspect a short window of a
  recorded day. **Action:** add a `market-data dump` subcommand in
  [market-data](../../../repos/market-data.md) that prints one stream's `Event_log` records
  between `-from` and `-to` timestamps as sexps, with an expect test over a fixture log.
- **Logs and state machines:** stepping to a point in time needs state reconstruction, which
  for market data means a book. **Action:** extend the dump with a `-book-at` option that
  replays L2 updates into a local book and prints the top levels at the requested time,
  reusing a client's local book module.
- **Testing and simulation:** the simulators' engine in
  [exchange-core](../../../repos/exchange-core.md) is deterministic under a seed, so an
  input log would make sim incidents replayable. **Action:** add an option to `hl-sim` to
  append every accepted `/exchange` request with its timestamp to a file, and a test that
  replays the file into a fresh engine and gets identical fills.
- **Performance:** fixed-width serialization beats bin_prot for hot logging, but our
  recorder's write rate is far below where bin_prot costs matter. Context only.

Tags: `replay`, `state-machines`, `observability`, `data-platform`, `risk`
