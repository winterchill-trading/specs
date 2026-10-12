# Trading off compute for memory with activation checkpointing

- Source: <https://blog.janestreet.com/trading-off-compute-for-memory-with-activation-checkpointing/>
- Published: 2026-09-30
- Kind: blog post

## Summary

- Activation checkpointing drops some forward-pass activations and recomputes them in the
  backward pass, trading compute for peak memory; an intern built a planner that meets an
  absolute memory budget with minimal extra compute.
- PyTorch already offers a min-cut partitioner in `torch.compile` (which can cut memory
  and time at once, since Inductor fuses cheap recomputation into backward kernels), a
  knapsack-based memory budget API and per-op selective checkpointing.
- Criticisms of the built-ins: the budget is a percentage rather than gigabytes, it is not
  monotonic (a smaller budget can raise the peak through recompute allocations), and it
  ignores true peak memory and true recompute cost; per-op policies cannot see the graph.
- The planner runs once on fake tensors, captures every graph, its min-cut save set and
  the execution order, then greedily removes the save with the lowest recompute cost per
  byte of global peak freed, recomputing liveness each step.
- Recompute cost includes all upstream nodes the backward pass would otherwise not need;
  time is estimated from PyTorch flop formulas with manual corrections for slow ops.
- At training time a custom partitioner tags nodes must-save or must-recompute and reruns
  min-cut. On single-graph test models it beat the knapsack and op-level policies at most
  budgets and smoothed the memory profile; dynamic shapes and RNG ops are not handled.

## Relevance to us

- Not relevant: we do no model training. The general idea (estimate the true peak by
  simulating liveness, then trade recomputation for storage) has no current consumer in
  our repos.
- **Action:** none.

Tags: `ml`, `performance`
