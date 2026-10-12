# Core_bench: better micro-benchmarks through linear regression

- Source: <https://blog.janestreet.com/core_bench-micro-benchmarking-for-ocaml/>
- Published: 2014-05-17
- Kind: blog post

## Summary

- Introduces Core_bench: `Bench.Test.create ~name f` plus `Bench.make_command` gives a CLI
  reporting time per run and minor, promoted and major words allocated per run.
- Naive timing fails for short functions because the clock is coarse and costly (hundreds
  of ns on the author's laptop), and batching alone still shows large run-to-run variance.
- That variance comes from GC: at a fixed batch size a sample triggers n or n+1
  collections, giving a periodic multi-modal pattern.
- Core_bench instead runs geometrically growing batch sizes and fits a line of time against
  batch size; the slope is cost per run, fixed overheads fall into the intercept, and GC
  costs are amortized into the estimate.
- The same regression estimates allocation and collections per call; bootstrapped 95%
  confidence intervals and R^2 flag unreliable results.
- Experimental multivariate regression splits time across predictors such as batch size,
  promoted words and compactions to explain odd profiles.
- An inline benchmark syntax lets benchmarks live next to code and be tracked over time.
- Arrays of 256 or more words are allocated straight into the major heap, which the benchmark output
  makes visible.

## Relevance to us

- **Performance:** No repository in the org has a benchmark, so the stack-allocation claims for
  matching are unmeasured. **Action:** add a `bench/` executable using core_bench to
  [order-book](../../../repos/order-book.md) that measures submit and cancel against a book with
  1000 resting levels, and record time and minor words per run in the README as the baseline.
- **Performance:** Words-per-run output turns allocation-free claims into checkable numbers.
  **Action:** add a core_bench case for `Quoter.quote` in [mm-core](../../../repos/mm-core.md) with
  a typical `Market_state` and record its minor words per run.

Tags: `performance`, `allocation`, `gc`, `testing`
