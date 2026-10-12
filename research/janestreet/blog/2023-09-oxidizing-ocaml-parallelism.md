# Oxidizing OCaml: Data Race Freedom

- Source: <https://blog.janestreet.com/oxidizing-ocaml-parallelism/>
- Published: 2023-09-01
- Kind: blog post

## Summary

- Third and last part of the series: with OCaml 5 domains, a parallel counter without
  synchronization loses updates (the post shows a count well short of 200,000); OCaml's
  memory model keeps races type-safe but still buggy.
- A proposed sync mode marks values safe to share across domains: immutable and exclusively
  mutable data are sync, ordinary mutable data is not, and a `parallel` primitive demands a
  sync, once closure with a sync result, so capturing a `ref` is a type error.
- Exclusive mutability alone forces Rust-style moves between domains; a mutex built from a
  unique sync value and lending a local exclusive borrow restores sharing.
- Capsules hold arbitrary unsync, even cyclic, mutable data; each capsule has a key whose
  existential type is fresh per creation, and pointers into the capsule are created, mapped,
  extracted (sync results only) or merged back (consuming the key).
- Storing a capsule key inside a mutex yields a data-race-free wrapper for any existing
  structure, shown as a locked hash table; keys are zero-size and the mutex compiles to a
  test-and-set flag, so the safety is free at runtime.
- At the time, locality was in production and unique and once had just been merged; planned
  work included a dual mode axis and modes for effects and off-heap data.

## Relevance to us

- Low today: our programs are single-domain Async (blocking Parquet writes go through
  `In_thread` in [market-data](../../../repos/market-data.md)), so we have no shared-memory
  parallelism to protect.
- The vocabulary in this 2023 design differs from what OxCaml later shipped, which is a known
  source of confusion for agents writing code from blog posts; that belongs in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).
- **Action:** add a `GOTCHAS.md` entry in `oxcaml-claude-skills` recording which
  data-race-freedom modes and the `Capsule` library actually exist on our `5.2.0+ox` switch
  (checked by compiling a two-line example), and their names versus this post's `sync`.

Tags: `oxcaml`, `ocaml-practice`, `ai-tools`
