# The perils of polymorphic compare

- Source: <https://blog.janestreet.com/the-perils-of-polymorphic-compare/>
- Published: 2008-08-18
- Kind: blog post

## Summary

- OCaml's polymorphic comparison (`compare_val` in the runtime) walks values structurally,
  ignoring types: records field by field, variants by tag then contents.
- It is convenient, enabling generic maps and sets and quick structural equality.
- It breaks abstraction: two sets with the same elements but different tree shapes compare
  unequal structurally while `Set.equal` says they are equal.
- It raises at runtime on functions, some custom C blocks and objects.
- It is slow when the compiler cannot specialize it; removing stray calls is one of the
  first optimizations the author reaches for.

## Relevance to us

- Every repository opens `Core`, which shadows polymorphic comparison with `int`-only operators, and
  our types derive `compare` and `equal` (for example in
  [fixed-decimal](../../../repos/fixed-decimal.md)), so the guardrail is already in place.
- **Action:** none.

Tags: `ocaml-practice`, `performance`
