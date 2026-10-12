# Why ML Needs a New Programming Language

- Source: <https://signalsandthreads.com/why-ml-needs-a-new-programming-language/>
- Published: 2025-09-03
- Kind: Signals and Threads episode 25

## Summary

- The guest is an outside compiler and language designer (LLVM, Clang, MLIR, OpenCL, Swift, now Mojo
  at Modular) who describes his niche as the hardware-software boundary, with each project built on
  what the previous one made possible.
- He judges language features by utility first: algebraic data types and pattern matching were
  obvious wins that C++, Java and C# still lacked around 2010. The host adds that features with a
  simple mathematical basis generalize and compose far beyond their first use.
- Swift began in 2010 as a side project after Clang shipped C++ support. The guest talks about small
  early design flaws, grains of sand in his phrase, that complicate a whole system; removing one
  relaxes many constraints at once, which is why he wants to redo designs rather than patch them.
- MLIR (described as LLVM 2.0 for accelerators) is used across the industry, yet the software stacks
  stay fragmented: CUDA, ROCm, XLA and others are each built by a hardware vendor for its own chips,
  so nobody has an incentive to build a shared portable layer.
- Stacking Python orchestration layers (the MLOps wave) on top of incompatible vendor stacks only
  adds duct tape; when something breaks you still debug the whole tower.
- Modular gives Mojo away and sells to platform teams running hundreds or thousands of GPUs. Its
  stack has Mojo (the language), MAX (single-node serving, a PyTorch or vLLM replacement) and
  Mammoth (a Kubernetes cluster layer). The goal is to beat vendors on their own hardware and ship
  AMD and Nvidia support in the same release.
- Hardware background: data-center CPUs have about 100 cores; GPU streaming multiprocessors run
  32-thread warps in lockstep, with extra registers so thread switches are nearly free and latency
  is hidden; tensor cores are dedicated matrix-multiply units; TPUs build the whole chip around
  large matmul units.
- GPU generations (Volta, Ampere, Hopper, Blackwell) change performance characteristics and memory
  models, and Blackwell broke compatibility with some Hopper kernels. The guest says CUDA, now about
  20 years old, was designed for a simpler machine.
- Triton is described as trading roughly 20% of peak performance for ease of use. The guest wants
  full performance plus portability, so users never hit a ceiling that forces a rewrite in another
  system.
- C++ undefined behaviour exists to help optimizers on legacy code and benchmark suites. For new GPU
  code you can change the code itself, so the language should give control and plain errors (for
  example, a compile error for an uninitialized variable).
- GPU programming has unusual economics: the programs are small, extremely valuable and written by a
  few experts, and there is little legacy code. AI tools that translate CUDA kernels into Mojo let
  hackathon newcomers ship GPU code within a day.
- Mojo uses Python syntax and adds types and Zig-inspired metaprogramming: almost any runtime code,
  including allocation, lists and strings, can also run at compile time. Hardware knowledge then
  lives in libraries instead of the compiler.
- The host frames metaprogramming as removing interpreter overhead by generating specialized code. C
  macros and C++ templates do this but are hard to reason about and give poor errors.
  Python-embedded DSLs have better compile times, but you have to inspect a value to learn whether
  it is static. In Mojo the syntax shows which values are compile-time.
- The sufficiently-smart-compiler trap: auto-parallelizers and magic DSLs work in demos, then one
  small edit turns a 100x speedup into a 100x slowdown and you end up reading compiler dumps.
  Predictability and control win.
- CPUs are a different kind of magic box: speculation and prefetching make sequential code fast at a
  high power cost. Accelerators are simpler and explicitly parallel, which makes them harder to
  program but more efficient.
- Portability comes from parametric specialization. Moving matmul from float32 to float16 doubles
  the effective cache size and changes the right access pattern. Matmul has become almost an
  operating system of special cases (shapes, dtypes such as float4 and float6, vendor tensor-core
  layouts, warp widths of 32 or 64). `LayoutTensor` describes memory layout and access declaratively
  at compile time.
- The guest's formula combines a sound type system, compile-time metaprogramming with no runtime
  cost, and domain experts. People who know the hardware but are not compiler engineers can write
  kernels that scale across hardware.
- Traits give checked generics: generic code (for example, over an iterator trait) is type-checked
  once without being instantiated. C++ templates behave like macros, fail deep inside expansions and
  regenerate the same code repeatedly, which slows compilation.
- Mojo parses code without knowing the target, so one function can run on a CPU or a GPU. A Mojo
  package stays target-independent, like Java bytecode, while a normal build still produces a plain
  executable. Unlike PTX (pointers and registers, compiled to SASS by the vendor), the package keeps
  the generic types and the programmer's specialization logic.
- Keeping complexity down: a small core team, Python as the reference surface for saying no, and
  Go's restraint (generics added late, roughly 80% of features for 20% of complexity). Swift's open
  proposal process let too many features in.
- The host notes Jane Street is extending OCaml with ideas from Rust while trying to keep its
  power-to-weight ratio. Internally they can try a feature and withdraw it, which a large
  open-source language cannot.
- Versioning plan: major versions may be incompatible but must link together, as C++ ABI stability
  allowed, instead of a Python 2-to-3 style migration that took about 15 years. Strong types plus
  agents make migrations practical: change a type and let the agent fix every type error.
- To use agents with a niche language, point them at a large public corpus: Modular has hundreds of
  thousands of lines of open Mojo code and publishes setup instructions for coding tools.
- Roadmap the guest gives: Mojo is already a simple way to speed up Python with no binding layer;
  dynamic traits within 6-9 months to compete with Rust; Python-like classes in 12-18 months;
  eventually something close to a Python superset.

## Relevance to us

- Weak overall: we write no GPU or ML code. The design stance (explicit control over clever
  compilers, a small language surface) matches how we use OxCaml, and our `Stable.V1`/`V2`
  convention in [market-data](../../../repos/market-data.md) already follows the rule that old and
  new versions must coexist.
- **OCaml practice:** Agents refactor well when a type change is made first and the compiler then
  lists every call site to fix. **Action:** add a short type-first refactor recipe (edit the `.mli`,
  run `dune build`, fix errors in dependency order, re-run expect tests) to the
  `janestreet-ocaml-style` skill in [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).
- **OCaml practice:** Agents write better code in a niche language when pointed at a corpus of real
  examples. **Action:** give each skill in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md) a reference-modules list of 3-5
  files from our repositories that show the pattern in use (for example `Live.Make` in mm-core for
  Async loops).

Tags: `ml`, `hardware`, `performance`, `ai-tools`, `oxcaml`
