# Introducing Incremental

- Source: <https://blog.janestreet.com/introducing-incremental/>
- Published: 2015-07-18
- Kind: blog post

## Summary

- Open-source release of Incremental, a library for self-adjusting computation: a
  spreadsheet-like dependency graph where only nodes downstream of changed inputs recompute.
- Unlike a spreadsheet, the graph can change shape at runtime via `bind`, so structure can
  depend on data.
- Use cases named: online versions of combinatorial algorithms, incrementally rendered GUIs
  (view as a function of the model), and risk calculations whose inputs are both live
  market data and user configuration that may restructure the model.
- API tour: a generative `Incremental.Make ()` functor mints a separate world per
  application; `Var.create`/`Var.set` feed inputs, `map2` builds nodes, `observe` marks
  outputs, and nothing updates until `stabilize` runs.
- A balanced binary merge tree makes a single element update O(log n);
  `unordered_array_fold` with an inverse function makes sums O(1) per update.
- Cost: firing one node was about 30 ns on the author's laptop, so it pays off only when
  per-node work is large or the changed subgraph is small relative to the whole.
- Self-adjusting computation is related to functional reactive programming but optimizes DAG
  recomputation rather than modelling time-varying values.

## Relevance to us

- Conceptually close to a multi-venue risk or PnL view in [mm-core](../../../repos/mm-core.md), but
  our per-symbol state (`Market_state`, `Inventory`) is small and cheap to recompute, so 30 ns per
  node would not pay off today.
- **Action:** none.

Tags: `architecture`, `risk`, `ui`, `performance`
