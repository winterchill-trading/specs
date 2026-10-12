# Compiler Optimization

- Source: <https://signalsandthreads.com/compiler-optimization/>
- Published: 2020-09-30
- Kind: Signals and Threads episode 4

## Summary

- The guest did a PhD in software verification, worked on program analysis at IBM Research and
  on the GCC ARM backend at ARM, taught compilers at a London university, and joined Jane
  Street's OCaml compiler team in 2018.
- Verification proves programs meet a specification; the guest found full verification hard to
  apply because it is undecidable in general and many users value performance over proven
  correctness, while compilers combine both concerns with a measurable goal.
- Specifications written separately from code, like documentation, drift as code evolves; OCaml
  instead makes types the specification.
- Testing and formal methods help each other: concrete runs are abstracted to cover sets of
  states, solvers report states not yet covered, and tests speed up proofs.
- The host describes types plus a few tests as making a program "snap into place", beyond what
  either gives alone.
- A traditional compiler is a chain of intermediate representations and passes (instruction
  selection, register allocation, scheduling); passes share invariants, so getting a specific
  better output by changing one pass is hard.
- Superoptimization searches for the cheapest instruction sequence equivalent to a given one;
  the 1982 original tested candidates, and later work proved equivalence of straight-line code
  with solvers.
- It is too slow for everyday builds, but useful for compiler and hardware designers to see how
  far generated code is from optimal, and it could derive a backend from a formal model of new
  hardware, possibly specialized once per language and target pair.
- Performance-critical code might deserve a different backend or heavier optimization than the
  rest of a program.
- Jane Street added feedback-directed optimization to OCaml: sampled hardware profiles (no
  instrumentation, so the measured code is unchanged) guide the layout of functions and basic
  blocks so hot code sits together in the instruction cache.
- Critical programs ran 10 to 20 percent faster just from code layout.
- FDO also made performance stable: a slowdown caused by an unrelated library change vanished
  under FDO because layout no longer shifted, and stable timings make small improvements
  measurable.
- The team considered adding FDO to its compiler benchmarking to reduce noise; the opposite
  approach (from university research) randomizes layout, even every few seconds at run time,
  and uses statistics.
- Optimization is split between hardware (sees the recent past), compilers (see program
  structure) and JITs (pay at run time); hardware gains help every compiler, compiler gains
  help one community.
- For many programs memory access, data layout and garbage collection dominate instruction
  micro-optimizations; Spacetime and memtrace help find allocation and access patterns.
- The guest found OCaml far better suited to compiler and analysis code than Java (pattern
  matching instead of visitors) and the type checker a reliable guard against silly mistakes,
  while tests remain necessary.
- OCaml's backend deliberately emits simple, readable, portable code and leaves much to the
  hardware; architecture-specific code is small, and passes cannot be added or configured,
  which hindered FDO.
- Compilers are described as front end (parsing, type checking), middle end (inlining and
  other language-independent transformations) and back end (target-specific code generation).
- The ARM backend received less attention: generic scheduling for each ARM generation and
  inflexible register handling; register allocation on AMD64 is also simple-minded.
- A small optimization by the guest caused a miscompilation caught only by a rarely run test;
  affected teams rolled back, the rarely run tests became routine within weeks, and the
  incident was treated as a learning event without blame.
- Upstreaming changes to OCaml is hard when the motivation is internal and large-scale; sharing
  tools and benchmarks (such as the Sandmark suite), engaging other industrial users, and a more
  modular backend that can hold experimental passes would help.

## Relevance to us

- We build with the OxCaml `5.2.0+ox` compiler, a descendant of this line of work, and have no
  performance baseline for any hot path except a benchmark directory in
  [parquet](../../../repos/parquet.md).
- **Performance:** Single timing runs are dominated by layout noise, so a baseline must repeat
  runs and report spread. **Action:** add a `bench/` executable that times insert, cancel and
  match over a fixed seeded order stream, repeated with median and spread printed, in
  [order-book](../../../repos/order-book.md).
- **Performance:** Optimization settings should be judged on real workloads, not assumed.
  **Action:** once the order-book benchmark exists, compare the default release build with
  `-O3` ocamlopt flags and record the result in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md) `GOTCHAS.md`.
- **Testing and simulation:** A miscompilation was caught only by a rarely run test, and our
  end-to-end scripts (`scripts/e2e-all.sh`) run only by hand. **Action:** add a weekly
  scheduled CI workflow that runs the three-venue end-to-end script in
  [market-maker](../../../repos/market-maker.md).
- **Build and deploy:** Compiler changes should arrive deliberately, and CI follows the moving
  `ox` opam repository while the base image pins it to a commit. **Action:** pin the `ox`
  repository to the same commit as the base image in the CI workflow of
  [fixed-decimal](../../../repos/fixed-decimal.md) first, then the rest.

Tags: `performance`, `oxcaml`, `formal-methods`, `testing`, `build`
