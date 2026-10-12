# Memory Management

- Source: <https://signalsandthreads.com/memory-management/>
- Published: 2022-01-05
- Kind: Signals and Threads episode 13

## Summary

- The guest, a compiler engineer, contrasts tracing GC with reference counting: refcounting
  reclaims memory sooner and fits single-owner buffers well, but costs atomic counter updates
  and can stall on freeing a large tree; tracing is usually faster and exposes one
  space-for-time knob.
- OCaml's GC is generational: a bump-pointer minor heap where most objects die young, and
  an incremental mark-and-sweep major heap that works in small slices so pauses stay in the
  hundreds of microseconds instead of seconds for a multi-gigabyte heap.
- Adding a small prefetch queue in front of marking made the mark phase two to three times
  faster: marking order does not matter, so about ten cache misses can be in flight at once
  instead of one. Tagged integers help because the marker needs no side tables.
- General-purpose prefetching (for example in `List.map`) is hard to get right because the
  benefit depends on timing and data size; small changes can flip a cache hit into a 300
  cycle miss.
- Local allocation (now OxCaml's `local_` mode) gives safe stack allocation without Rust
  style lifetime variables: a function declares that it does not capture its argument, so
  type inference keeps working. A separate data stack lets helper functions return local
  values to their caller.
- Stack allocation beats even cheap minor allocation because it reuses memory already in L1
  and leaves fewer minor-heap objects, so promotions fall as if the minor heap were bigger.
- Unboxed types add layouts (kinds) to the type system so code can be polymorphic over
  values of one layout; unboxed tuples travel in registers, `Int32` stops being a boxed
  three-word block, and a non-nullable kind could make `t option` cost no allocation.

## Relevance to us

- Hot paths in [order-book](../../../repos/order-book.md), the quoter in
  [mm-core](../../../repos/mm-core.md) and normalizers feeding
  [market-data](../../../repos/market-data.md) allocate freely today; this episode explains
  where the minor heap cost comes from and which OxCaml features (`local_`, unboxed types)
  remove it.
- [fixed-decimal](../../../repos/fixed-decimal.md) already stores values as immediate
  `int`s, which is the representation the episode recommends over boxed numbers.
- **Action:** add a ppx_expect test in `order-book` that runs 10,000 add/cancel cycles and
  prints `Gc.minor_words` per operation, so allocation regressions show up as a diff.

Tags: `gc`, `allocation`, `oxcaml`, `performance`
