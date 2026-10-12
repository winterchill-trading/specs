# CPU Registers and OCaml

- Source: <https://blog.janestreet.com/cpu-registers-and-ocaml-2/>
- Published: 2015-05-05
- Kind: blog post

## Summary

- On x86-64 the OCaml native compiler has about 13 registers for integers and pointers and
  16 for floats; live variables beyond that are spilled to the stack.
- A statistics loop with many accumulators ran 1.5 to 2 times faster after reordering
  statements so fewer temporaries were live at once.
- Any non-inlined call spills all live registers; a `Printf.sprintf` in an error branch
  before a loop made the loop about 1.35 times slower because the accumulators were then
  reloaded and stored on every iteration.
- Passing loop-invariant values as parameters of a local recursive function, instead of
  reading them from the closure, sped a search loop up by 1.15 to 1.33 times.
- The compiler flag `-dreload` shows where spills happen.

## Relevance to us

- Applies at most to the matching loop in [order-book](../../../repos/order-book.md) and the quoter
  in [mm-core](../../../repos/mm-core.md), neither of which is register-bound today; OxCaml's
  flambda backend also changes the details.
- **Action:** none.

Tags: `performance`, `ocaml-practice`, `hardware`
