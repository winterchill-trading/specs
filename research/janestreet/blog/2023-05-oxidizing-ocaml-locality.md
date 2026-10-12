# Oxidizing OCaml: Locality

- Source: <https://blog.janestreet.com/oxidizing-ocaml-locality/>
- Published: 2023-05-26
- Kind: blog post

## Summary

- First part of the series: Jane Street adds modes to OCaml to get some of Rust's control
  (stack allocation, managed resources, safe concurrency) while keeping GC, type inference
  and zero cost for code that does not opt in.
- Even short-lived heap values cost something: they push the next minor collection closer,
  cause more promotion to the major heap, and make zero-allocation code harder to write.
- The `local` mode marks values that cannot escape their region (roughly the enclosing
  function); the compiler infers it and can place such values on a separate locals stack,
  so for example an option matched immediately after creation need not touch the heap.
- `exclave` ends the current region early so a function can return a local value allocated
  in the caller's region, which is the main way to build stack-allocated structures.
- Local parameters are a promise by the callee not to retain the value, which makes APIs such
  as `with_file` safe against stashing a file descriptor after close.
- Modes are separate from types and deep (a local list's elements are local), with `global` a
  sub-mode of `local`; record fields can be declared `global`, and mutable fields are
  implicitly global to prevent leaks.
- Locality was already in production, used daily by performance-focused developers and
  ignored by others.

## Relevance to us

- Locality is the one mode our `5.2.0+ox` switch certainly supports, and
  [order-book](../../../repos/order-book.md) already takes a `@ local` callback in `iter`;
  but `best_bid`, `best_ask` and `mid` return `Price.t option`, which allocates a `Some` on
  every call from the [mm-core](../../../repos/mm-core.md) quoter.
- **Action:** add an expect test in `order-book` that measures `Gc.minor_words` around
  10,000 calls to `best_bid` and `mid` on a populated book, and if the count is non-zero add
  local-returning variants (via `exclave`) and switch the quoter to them.

Tags: `oxcaml`, `allocation`, `gc`, `performance`
