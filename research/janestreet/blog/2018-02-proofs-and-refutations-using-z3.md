# Proofs (and Refutations) using Z3

- Source: <https://blog.janestreet.com/proofs-and-refutations-using-z3/>
- Published: 2018-02-15
- Kind: blog post

## Summary

- Formal tools are seen as forbidding; this post shows Z3 validating real compiler work:
  constant-folding rewrites planned for the OCaml optimizer.
- Constant folding evaluates expressions at compile time and also applies identities such
  as neutral elements, absorbing elements, and replacing multiplication by -1 with negation.
- Machine integers are bounded: the -1 rewrite is valid in two's complement only because
  negating the minimum value wraps to itself.
- Floats are worse: addition is not associative, and positive and negative zero compare
  equal yet divide to different infinities, so equal-comparing values are not
  interchangeable.
- The correctness bar: bit-identical IEEE 754 results for all inputs and all rounding
  modes.
- SAT and SMT background: SMT solvers add theories (integers as bit vectors, arrays, IEEE
  floats) that prune search; satisfiable queries come with a model.
- Technique: assert the negation of the identity; "sat" returns a concrete counterexample
  that can be replayed in a toplevel, "unsat" means the rewrite holds, at the cost of
  trusting Z3 (a proof for `x * 1` ran past 100,000 lines).
- Z3 refuted folding `x + +0.0` to `x` (negative zero breaks it); the rewrite had briefly
  been in the development compiler.
- All integer and float simplifications in flambda 2.0 were checked for all four OCaml
  integer widths and all rounding modes.
- Plan: express the checks as attributes next to each rewrite via a ppx so code and proofs
  stay in sync; the safety net encourages bolder optimizations.

## Relevance to us

- **Testing and simulation:** arithmetic on bounded machine integers needs checking
  against an exact model, and fixed-decimal's `mul_units` and `div_units` (truncating
  toward zero, overflow-safe near `max_int`) are only covered by hand-picked expect cases.
  **Action:** add a Base_quickcheck property in
  [fixed-decimal](../../../repos/fixed-decimal.md) comparing both against a `Bigint`
  reference, including negative operands and values near the range limit.
- **OCaml practice:** float edge cases (negative zero, NaN, infinities) silently change
  results, and `of_float` only documents rounding to the nearest unit. **Action:** add an
  expect test in `fixed-decimal` pinning `of_float` behavior on `-0.0`, `nan` and
  `infinity`, and make it raise on non-finite input if it does not already.

Tags: `formal-methods`, `property-testing`, `testing`
