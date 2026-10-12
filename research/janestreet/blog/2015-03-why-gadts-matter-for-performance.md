# Why GADTs matter for performance

- Source: <https://blog.janestreet.com/why-gadts-matter-for-performance/>
- Published: 2015-03-30
- Kind: blog post

## Summary

- Argues that GADTs are useful in systems code, not only for typed interpreters, because
  they let you choose memory representations safely.
- OCaml's uniform one-word value representation means an `'a array` costs a word per
  element even for bytes; `bytes` is compact but a different type.
- A plain variant over `Array` and `Bytes` cases forces `get`/`set` to `char`, since a match
  must have one result type.
- A record of closures works but allocates a closure per operation for every value.
- A GADT whose `Bytes` constructor returns `char t` while `Array` stays polymorphic, plus a
  locally abstract type annotation in each function, gives a fully polymorphic API with no
  closures.
- The general theme is precise control of representation behind an easy interface.

## Relevance to us

- Our data types (`Market_data.Event`, fixed-point `int` values) already have compact
  representations, and OxCaml unboxed types now cover more of this ground; no current
  [market-data](../../../repos/market-data.md) or [order-book](../../../repos/order-book.md)
  structure needs a GADT for layout.
- **Action:** none.

Tags: `performance`, `ocaml-practice`, `allocation`
