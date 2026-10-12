# Why ML Needs a New Programming Language

- Source: <https://signalsandthreads.com/why-ml-needs-a-new-programming-language/>
- Published: 2025-09-03
- Kind: Signals and Threads episode 25

## Summary

- The guest, an outside compiler and language designer (LLVM, Clang, MLIR, Swift), explains
  why Modular built Mojo: every GPU vendor ships its own stack (CUDA, ROCm, XLA), so nobody
  is paid to build a portable layer across accelerators.
- Modular's stack has three layers: Mojo (the language), MAX (single-node serving, a
  PyTorch or vLLM replacement) and Mammoth (Kubernetes cluster management). The language is
  free; revenue comes from enterprise platform services.
- Hardware context: GPU streaming multiprocessors run 32-thread warps in lockstep with cheap
  context switches; tensor cores are dedicated matmul units whose layouts differ by vendor,
  generation and data type, and new generations (Blackwell vs Hopper) break kernel
  compatibility.
- The guest rejects "sufficiently smart compiler" designs (auto-parallelization, Triton
  giving up roughly 20% of peak) because one small change can turn a 100x speedup into a
  100x slowdown; predictability and programmer control matter more than magic.
- Mojo keeps Python syntax but adds real types and compile-time metaprogramming in the same
  language as runtime code (inspired by Zig), so layout logic such as `LayoutTensor` lives
  in libraries, is debuggable, and boils away at compile time.
- Traits give checked generics: generic code is type-checked once without instantiation,
  unlike C++ templates, which behave like macros, give poor errors and recompile the same
  code repeatedly.
- Mojo packages stay target-independent (like Java bytecode, unlike PTX) and are
  specialized per device later; a plain build still yields a normal executable.
- On complexity: a small core team, Python as the reference surface, and a Go-style
  "80% of features for 20% of complexity" stance; versioning plans let 1.0 and 2.0
  packages link together, avoiding a Python 2-to-3 style migration.
- Both speakers report that a strong type system plus agentic coding tools works well for
  large refactors: change a type, let the agent chase the type errors.

## Relevance to us

- Weak relevance: we write no GPU or ML code. The general points (prefer explicit control
  over clever compilers, keep the language surface small) match how we already use OxCaml.
- The type-errors-guide-the-agent workflow is already how agents work across our repos; it
  is a habit, not a deliverable.
- **Action:** none.

Tags: `ml`, `hardware`, `performance`, `ai-tools`
