# Trading off compute for memory with activation checkpointing

- Source: <https://blog.janestreet.com/trading-off-compute-for-memory-with-activation-checkpointing/>
- Published: 2026-09-30
- Kind: blog post

## Summary

- Backpropagation needs forward-pass activations, which PyTorch keeps until the backward
  pass, so memory peaks at the end of the forward pass. Activation checkpointing discards
  chosen activations and recomputes them later, trading compute for memory (the name is
  misleading: checkpointed nodes are the ones not saved).
- The intern's task: given a model and an absolute memory budget, choose what to drop to
  minimize extra compute.
- Existing PyTorch tools: AOT Autograd in `torch.compile` builds a joint forward and
  backward graph, and a min-cut partitioner drops some saves. That can cut both memory and
  time, because Inductor fuses cheap recomputation into backward kernels and memory-bound
  ops are cheaper to recompute than to reload.
- PyTorch's memory budget API relaxes min-cut in stages and solves a knapsack, but the
  budget is a fraction of default saved activations rather than gigabytes, it is not
  monotonic (lowering it can raise the peak through recompute allocations), and it does not
  model the true peak or true recompute cost.
- Selective activation checkpointing decides per op but cannot see the graph, which the
  true costs require.
- True costs: dropping a node can move the peak into the backward pass's recomputation; and
  recomputing a node costs everything upstream that the backward pass would otherwise not
  need.
- The planner compiles once on fake tensors (shapes, no data) on a single GPU, capturing
  every graph, its min-cut save set and the execution order across graphs, and starts from
  min-cut, so it never saves more than the baseline.
- It greedily removes the save with the best recompute cost per byte of global peak
  reduction, re-deriving graphs and re-simulating liveness each step, until under budget or
  stuck. Greedy can hit local minima; beam search is a possible improvement.
- Peak memory comes from liveness simulation (inputs live for the whole graph, outputs
  from creation to end, intermediates until last use), plus parameters, optimizer state and
  a user reserve for fragmentation and communication buffers. Saves from earlier graphs stay
  alive until their backward pass.
- Time comes from PyTorch flop formulas with manual corrections for ops that run slower
  than their flops suggest; memory-bound kernels are ignored.
- At training time a custom partitioner tags nodes must-save or must-recompute and reruns
  min-cut. On single-graph test models it beat the knapsack and op-level policies at most
  budgets and smoothed the memory profile. Dynamic shapes, data-dependent ops and RNG ops are
  not handled.

## Relevance to us

- We train no models; this applies to none of our repos.
- **Action:** none.

Tags: `ml`, `performance`
