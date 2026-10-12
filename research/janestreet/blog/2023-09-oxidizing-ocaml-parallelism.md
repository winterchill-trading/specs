# Oxidizing OCaml: Data Race Freedom

- Source: <https://blog.janestreet.com/oxidizing-ocaml-parallelism/>
- Published: 2023-09-01
- Kind: blog post

## Summary

- Third and last part of the series: with OCaml 5 domains, a counter incremented by two
  parallel tasks without synchronization loses updates; OCaml's memory model keeps races
  type-safe, unlike C++ undefined behaviour, but they are still bugs.
- Rust forbids data races by allowing mutation only through exclusive references, at a cost
  in complexity; the goal is the same guarantee while letting most OCaml code ignore
  ownership thanks to the GC.
- A proposed sync mode marks values safe to share across domains: immutable and exclusively
  mutable data are sync, ordinary mutable data is not; closures capturing unsync values are
  unsync.
- A `parallel` primitive demands a sync, once closure with a sync result, so a task capturing
  a `ref` is a type error; at runtime each domain's mutable data is then unreachable from
  other domains.
- Exclusive mutability alone forces Rust-style moves of values between domains; a mutex built
  from a unique sync value and lending a local exclusive borrow restores sharing, but needs a
  mutex per value and only holds sync data.
- Shared-ownership structures such as cyclic mutable lists cannot be exclusively mutable;
  Rust resorts to unsafe code, while capsules hold arbitrary unsync, even cyclic, data.
- Each capsule has a key whose existential type is fresh at creation; pointers into the
  capsule are created, mapped (with the key held exclusively), extracted (sync results only)
  or merged back into the caller by consuming the key uniquely.
- Storing a capsule key inside a mutex yields a data-race-free wrapper for any existing
  structure, shown as a locked hash table; keys are zero-size and the mutex compiles to a
  test-and-set flag or a futex, so the safety is free at runtime.
- At the time, locality had been in production for over a year and unique and once had just
  been merged; planned work included a dual mode axis, effects, off-heap data and mode
  polymorphism.

## Relevance to us

- Context: our programs are single-domain Async, with blocking Parquet writes pushed to
  `In_thread` in [market-data](../../../repos/market-data.md), so we have no shared-memory
  parallelism to protect today.
- **OCaml practice:** the vocabulary in this 2023 design differs from what OxCaml later
  shipped, which misleads agents writing code from blog posts. **Action:** add a
  `GOTCHAS.md` entry in [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md)
  recording which data-race-freedom modes and whether a `Capsule` library exist on our
  `5.2.0+ox` switch, checked by compiling a small example, and their names versus this
  post's `sync`.

Tags: `oxcaml`, `ocaml-practice`, `ai-tools`
