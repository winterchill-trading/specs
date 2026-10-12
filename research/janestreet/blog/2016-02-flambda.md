# A better inliner for OCaml, and why it matters

- Source: <https://blog.janestreet.com/flambda/>
- Published: 2016-02-24
- Kind: blog post

## Summary

- With OCaml 4.03 about to be released, the post presents Flambda: a new intermediate
  representation designed for better inlining, plus optimizations built on it.
- In C, inlining mostly saves call overhead; in OCaml it matters more because it exposes
  more code to the optimizer, and OCaml has more to optimize, chiefly allocations.
- Example: a fold taking a closure allocates that closure on every call today; with Flambda
  the fold and the function are inlined and specialized, making it allocation-free.
- Example: summing a list's first and last elements with options allocates three values
  directly and five via the option monad (or `let%bind`); with `-O3 -unbox-closures` all
  versions allocate the same as a hand-tuned one, since immediately destructured options
  are removed.
- The value is letting simple, readable code perform like ugly hand-optimized code.
- Allocation removal that depends on inlining is unpredictable because inlining has
  thresholds; an intern added multi-value returns to the IR so a function returning a small
  tuple gets a tiny, reliably inlined wrapper, letting construction and destructuring cancel
  without inlining the callee.
- Measured on real applications: typically 20-30% fewer allocations and similar latency
  improvements, with more expected as optimizations accumulate.
- Functors, previously costly, can be inlined away, freeing their use as abstractions.
- A planned zero-allocation messaging protocol relies on naive ppx code generation;
  inlining plus constant folding move field-offset computation to compile time.
- Future features like modular implicits need a good inliner to perform well.
- Cost: less predictable performance; 4.03 adds attributes to require or forbid inlining
  per function, alongside work on more predictable heuristics. Built largely by OCamlPro
  with Jane Street and core team contributions.

## Relevance to us

- Background for OxCaml, whose optimizer descends from this line of work. Our hot paths
  lean on functors such as `Fixed_decimal.Make`, which this says inline away.
- **Performance:** optimizer claims are only useful if allocation is measured, and we have
  no benchmarks. **Action:** add a `bench/` executable using core_bench to
  [order-book](../../../repos/order-book.md) that reports time and allocated words for
  inserting and matching a fixed seeded batch of limit orders, so compiler or code changes
  show up as numbers.

Tags: `oxcaml`, `allocation`, `performance`
