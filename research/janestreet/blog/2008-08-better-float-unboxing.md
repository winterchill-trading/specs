# Better float unboxing

- Source: <https://blog.janestreet.com/better-float-unboxing/>
- Published: 2008-08-05
- Kind: blog post

## Summary

- A colleague found cases where the compiler boxed floats and immediately unboxed them, so
  code that should have been allocation-free float arithmetic allocated heavily.
- The workaround had been ugly manual inlining.
- The team filed a bug, and the fix landed in the OCaml compiler upstream.
- A related missed optimization for equality on polymorphic variants was still pending.

## Relevance to us

- Historical; we avoid floats on hot paths by using
  [fixed-decimal](../../../repos/fixed-decimal.md), and OxCaml's unboxed float types cover the
  remaining cases.
- **Action:** none.

Tags: `allocation`, `performance`, `ocaml-practice`
