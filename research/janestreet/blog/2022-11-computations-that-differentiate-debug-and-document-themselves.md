# Computations that differentiate, debug, and document themselves

- Source: <https://blog.janestreet.com/computations-that-differentiate-debug-and-document-themselves/>
- Published: 2022-11-17
- Kind: blog post

## Summary

- Jane Street estimates and reduces the costs of its positions (margin, financing, market
  risk, regulatory capital), which is a numerical optimization problem.
- `Gradient_calculator` lets a computation be written once and then evaluated,
  differentiated automatically, debugged through every intermediate value, and documented as
  an auto-generated LaTeX formula.
- They built their own rather than use JAX (poor OCaml interop) or OWL and ocaml-torch, whose
  tensor-centric model fits poorly with explicit, equation-like cost formulas.
- The API is a `Computation.t` built from constants, named variables and combinators such as
  `sum`, `square` and `abs`; `evaluate` returns the value and updates each variable's
  partial derivative; a black-box node accepts hand-computed costs and gradients.
- Internally it is an expression tree evaluated lazily with forward-mode automatic
  differentiation, chosen over reverse mode because their formulas have little chain-rule
  nesting, so the extra complexity was not worth it.
- A net-market-value example (positions netted per account per bank) converts from plain
  float code mostly by swapping `List.sum` and `Float.abs` for the combinators; an expect
  test then prints a table of partial derivatives whose signs are easy to sanity-check.
- A printed debug tree shows every node's value in an expect test, which replaces scattered
  prints, exposes wrong terms on branches the final value does not exercise (for example
  nested maxima), and makes reviewing changes to the calculation easy; depth limits keep big
  trees readable.
- Metavariables turn the expanded LaTeX into the general formula (a sum over banks, accounts
  and tickers), and the formula updates automatically when the computation changes.
- A built-in gradient descent `optimize` converges on the toy problem; the real use adds
  constraints that keep each ticker's total position fixed while moving it across accounts.
- Future work: incremental evaluation, compiler-style simplification (constant folding,
  common subexpressions, a DAG), effect-handler AD in OCaml 5, SVG output, open-sourcing.

## Relevance to us

- **Market making and trading systems:** a quote is a small formula (mid, inventory skew,
  spread, ladder offsets), and seeing every intermediate term in a test makes skew bugs
  obvious even when the final price looks plausible. **Action:** add a
  `Quoter.For_testing.explain` in [mm-core](../../../repos/mm-core.md) that prints each
  term of one quote computation as an indented tree, used in one expect test with a long
  inventory.
- **Testing and simulation:** margin and liquidation in the engine are cost formulas of the
  same kind, and branches such as cross versus isolated margin are only partly exercised by
  final-value tests. **Action:** add an expect test in
  [exchange-core](../../../repos/exchange-core.md) that prints the per-position terms
  behind one account's maintenance margin just before and after a liquidation trigger.
- **OCaml practice:** printing derivative or sensitivity tables in expect tests is a cheap
  sanity check for any pricing code. **Action:** none until we have an optimizer; we do no
  gradient-based optimization today.

Tags: `ocaml-practice`, `expect-tests`, `risk`, `trading`, `research-tooling`
