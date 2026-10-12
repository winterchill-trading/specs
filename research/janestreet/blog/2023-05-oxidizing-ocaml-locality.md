# Oxidizing OCaml: Locality

- Source: <https://blog.janestreet.com/oxidizing-ocaml-locality/>
- Published: 2023-05-26
- Kind: blog post

## Summary

- First part of the series: Rust handles stack allocation, non-memory resources and safe
  concurrency well, but at the cost of pervasive lifetime reasoning and weaker inference;
  Jane Street adds modes to OCaml to get that control only where it is wanted.
- Even short-lived heap values cost something: the minor heap is larger than cache so new
  allocations evict live data, each allocation brings the next minor collection closer, more
  values get promoted to the costly major heap, and zero-allocation code is hard to write.
- The `local` mode marks values that cannot escape their region (roughly the enclosing
  function); the compiler infers it and can allocate such values on a separate locals stack,
  so an option matched right after creation need not touch the heap.
- `exclave` ends the current region early so a function can return a local value allocated
  in the caller's region, which is the main way to build stack-allocated structures.
- A local parameter is a promise by the callee not to retain the value, which makes APIs such
  as `with_file` safe against stashing a file descriptor that is later closed.
- Modes are separate from types and deep (a local list's elements are local too), with
  `global` a sub-mode of `local`: stack values may point to heap values, never the reverse.
- Compared with Rust lifetimes, locality tracks only "the current region", which loses some
  expressiveness but keeps type inference and higher-order functions simple.
- Record fields can be declared `global` to escape a local record, and mutable fields are
  implicitly global so a local value cannot be leaked through them.
- Locality was already in production, used daily by performance-focused developers and
  ignored by others, which the author counts as success.

## Relevance to us

- **Performance:** [order-book](../../../repos/order-book.md) already takes a `@ local`
  callback in `iter`, but `best_bid`, `best_ask` and `mid` return `Price.t option`, which
  allocates a `Some` on every call. **Action:** add an expect test in `order-book` that
  measures `Gc.minor_words` around 10,000 calls to `best_bid` and `mid` on a populated book,
  and if the count is non-zero add local-returning variants via `exclave`.
- **Market making and trading systems:** the quoter runs on every market data update, so its
  per-tick allocation is the number that decides whether locality is worth adopting.
  **Action:** add an expect test in [mm-core](../../../repos/mm-core.md) that prints
  `Gc.minor_words` per quote computation for a fixed book and inventory, so any change in
  allocation shows up as a diff.
- **OCaml practice:** local callbacks are the cheap, safe pattern for "borrow" APIs such as
  file or socket handles. Context only; our resource handling is via Async and has not
  shown this bug class.

Tags: `oxcaml`, `allocation`, `gc`, `performance`
