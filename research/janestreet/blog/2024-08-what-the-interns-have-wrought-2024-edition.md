# What the interns have wrought, 2024 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2024-edition-index/>
- Published: 2024-08-26
- Kind: blog post

## Summary

- Camels, a first version of a pure OCaml dataframe library in the style of Polars, motivated
  by slow Rust builds and binding bugs; expressions are built as syntax first and compiled
  before execution, and broadcasting is explicit, with a phantom length type (one versus
  input) so a missing broadcast is a compile error.
- A speed-over-size variant of bin_prot for transaction logging from latency-sensitive
  systems: fixed-width integers instead of variable-length encoding, so runs of adjacent
  non-pointer fields can be copied with one `memcpy`; the serializer is driven by `typerep`
  rather than a new ppx.
- A surprise along the way: `Obj.unsafe_ith_field` allocates on all-float records, so a C
  replacement was needed; the format beat bin_prot everywhere (10-20% on small messages, up
  to 15x on large flat ones) and cut production tail latencies by 30-65%, with heavy
  Quickcheck round-trip testing.
- Limshare, which dynamically allocates risk limits across trading systems, is an Aria app
  (a replicated state machine over one global log); its debugger could only replay forward
  from the start of the day.
- The intern added periodic snapshots so the debugger can step backwards (find the last
  snapshot, replay forward), with breakpoints such as "a request was rejected" and tabular
  state dumps; the Aria team adopted it as a general tool.

## Relevance to us

- [market-data](../../../repos/market-data.md) event logs are bin_prot `Stable.V1` records
  written by [market-recorder](../../../repos/market-recorder.md); at our message rates
  bin_prot's write cost is not a bottleneck, so the fast format is background only.
- The log-plus-snapshot debugger maps onto our append-only `Event_log` and `Replay_feed`:
  today nothing lets a person inspect a short window of a recorded day.
- **Action:** add a `market-data dump` subcommand that prints one stream's `Event_log`
  records between `-from` and `-to` timestamps as sexps, with an expect test over a small
  fixture log, as the first step toward a replay debugger.

Tags: `replay`, `observability`, `data-platform`, `performance`, `risk`
