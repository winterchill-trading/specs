# Compiler Optimization

- Source: <https://signalsandthreads.com/compiler-optimization/>
- Published: 2020-09-30
- Kind: Signals and Threads episode 4

## Summary

- The guest moved from formal verification research (IBM) to the GCC ARM backend (ARM) and
  academia, then to the OCaml compiler team at Jane Street, drawn by direct contact with users.
- Testing and formal methods complement each other: concrete runs are generalized by
  abstraction, and solvers find states the tests missed; the host adds that a well-typed
  program plus a few tests tends to "snap into place".
- Superoptimization searches for the cheapest instruction sequence provably equivalent to a
  given one (originally straight-line code, checked with solvers). It is too slow for everyday
  builds but useful to measure how far a compiler is from optimal and to target new hardware
  from a semantic model.
- Feedback-directed optimization in OCaml uses sampled execution profiles (no instrumentation)
  to reorder functions and basic blocks so hot code sits together; critical programs ran
  10 to 20 percent faster.
- An unexpected FDO benefit is stable performance: unrelated library changes stop shifting
  code layout, so benchmark deltas become meaningful; randomized layout with statistics is the
  opposite approach to the same noise.
- OCaml's backend favours simple, portable code generation with little architecture-specific
  work; register allocation and ARM scheduling are noted weak spots, and passes cannot easily be
  added, which slowed FDO.
- A miscompilation from a small optimization was caught by a rarely run test; the follow-up was
  to run those tests routinely, treated as a learning event rather than blame.

## Relevance to us

- We compile with the OxCaml `5.2.0+ox` compiler, the descendant of this work, but we have no
  performance baseline for any hot path except a benchmark directory in
  [parquet](../../../repos/parquet.md).
- The layout-noise point means one-off timing comparisons on
  [order-book](../../../repos/order-book.md) or the
  [mm-core](../../../repos/mm-core.md) quoter would be unreliable without repeated runs.
- **Action:** add a `bench/` executable to [order-book](../../../repos/order-book.md) that times
  insert, cancel and match over a fixed seeded order stream, repeated several times with
  median and spread printed, as a baseline before trying OxCaml compiler flags.

Tags: `performance`, `oxcaml`, `formal-methods`, `testing`
