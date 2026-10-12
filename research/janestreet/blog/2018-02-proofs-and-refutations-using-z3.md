# Proofs (and Refutations) using Z3

- Source: <https://blog.janestreet.com/proofs-and-refutations-using-z3/>
- Published: 2018-02-15
- Kind: blog post

## Summary

- Jane Street used the Z3 SMT solver to check constant-folding rewrites planned for the
  flambda 2.0 optimizer before trusting them.
- Algebraic identities that hold for mathematical numbers can fail for machine numbers:
  fixed-width integers wrap, and floats have non-associative addition, signed zeros and
  rounding modes.
- The bar for a valid float rewrite is bit-identical IEEE 754 results for every input and
  every rounding mode.
- Technique: assert the negation of the identity; "sat" yields a concrete counterexample
  that can be replayed in a toplevel, while "unsat" means the rewrite holds.
- Z3 refuted folding `x + +0.0` to `x` (it fails for negative zero), a rewrite that had
  briefly existed in the development compiler.
- All integer and float simplifications in flambda 2.0 were checked for all four OCaml
  integer widths and all rounding modes; a proof of the `x * 1` rewrite ran past 100,000
  lines, so proofs are not human-checkable.
- Plan: attach the checks as attributes next to the rewrite code via a ppx so they stay
  in sync.

## Relevance to us

- [fixed-decimal](../../../repos/fixed-decimal.md) is exactly the "integers that are not
  mathematical integers" case: `mul_units` and `div_units` truncate toward zero and must
  not overflow near `max_int`. Its tests are hand-picked expect cases; there is no
  randomized check against an exact reference.
- **Action:** add a Base_quickcheck property to `fixed-decimal` tests comparing `mul_units`
  and `div_units` with a `Bigint` reference (truncation toward zero, negative operands,
  values near the range limit), printing any counterexample.

Tags: `formal-methods`, `property-testing`, `testing`
