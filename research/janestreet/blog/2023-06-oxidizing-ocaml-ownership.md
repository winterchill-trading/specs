# Oxidizing OCaml: Rust-Style Ownership

- Source: <https://blog.janestreet.com/oxidizing-ocaml-ownership/>
- Published: 2023-06-21
- Kind: blog post

## Summary

- Second part of the series: functional record updates allocate because the original may be
  aliased; if the compiler knew a reference was the only one, the update could happen in
  place behind an immutable interface.
- The uniqueness axis adds `unique` (the only reference anywhere, usable at most once) as a
  sub-mode of the default `shared`; unique records allow `overwrite` updates in place,
  including strong updates that change the record's type, such as an in-place `map`.
- Resource APIs follow: a file `close` that takes the file uniquely cannot be followed by a
  use; borrowing with `&` lends a local shared view, so reads do not consume ownership.
- A middle mode, `exclusive`, means the only active reference for a region, permitting
  mutation without consumption; `exclusively mutable` fields are writable only through
  exclusive references and read-only through shared ones, mirroring Rust's value,
  `&mut` and `&`.
- Closures that capture unique values must run at most once, which needs a linearity axis:
  `once` versus the default `many`, plus `separate` for non-reentrant closures holding
  exclusive borrows (analogous to `FnOnce` and `FnMut`), all without lifetime variables, so
  type inference is unaffected.
- At the time the uniqueness analysis was being implemented, with data-race freedom under
  OCaml 5 as the main motivation.

## Relevance to us

- Background only: none of our code uses uniqueness or linearity modes, and resource
  lifetimes such as minute-file rotation in
  [market-recorder](../../../repos/market-recorder.md) are handled with ordinary Async
  discipline and tests.
- Useful reading for agents before touching OxCaml mode errors; the series' syntax predates
  the shipped compiler, a point recorded under the data-race-freedom note's action for
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).
- **Action:** none.

Tags: `oxcaml`, `allocation`, `ocaml-practice`
