# What the interns have wrought, 2023 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2023/>
- Published: 2023-09-12
- Kind: blog post

## Summary

- The 2023 program had 152 software engineering interns from 58 schools in 19 countries,
  plus 31 interns in other technical roles.
- Concord, the platform for counterparties to trade with or through the firm, is built on one
  totally ordered transaction stream; an existing linear temporal logic (next, until) query
  engine over it went unused because queries were hard to write in s-expressions.
- An intern built a SQL-like frontend (`FIND ... THEN FIRST ... WHERE ... PRINT`) parsed with
  Angstrom, with effort spent on good error messages, plus operators such as
  `LAST p BEFORE q` and `NO MESSAGE p BEFORE q`; it became the team's main tool for
  debugging performance, for example order-to-first-fill latency.
- A pure OCaml tokenizer replaced a Python tiktoken server so token counts work in the
  browser client; it used a handwritten automaton instead of a regex library, a relaxed
  differential test against the reference, and an imperative rewrite with hash tables and
  arrays; it was slightly faster than the Rust reference for one vendor's tokenizer and
  nearly 2x for another, with higher variance from GC.
- `ppx_tracing` gained `@trace.async`: a correlation ID stored in the Async execution
  context tells concurrent calls apart in Perfetto traces, and synchronous calls attach to
  the current async parent; another team used it to cut a server's startup time by about
  half.

## Relevance to us

- Temporal "last X before Y" questions are exactly what our recorded data invites (last BBO
  before each trade); [market-data](../../../repos/market-data.md) already exposes Parquet to
  DuckDB, whose `ASOF JOIN` expresses this without a new language.
- Async-aware tracing would help explain latency inside the
  [mm-core](../../../repos/mm-core.md) `Live.Make` loop, but `ppx_tracing` is not in our
  dependency set, so that is a larger step.
- **Action:** add a `trades_with_bbo` view to `Parquet_views` in `market-data` that joins
  each trade to the last BBO at or before its `recv_ts` with DuckDB `ASOF JOIN`, tested
  over a small fixture day.

Tags: `observability`, `data-platform`, `async`, `ppx`, `research-tooling`
