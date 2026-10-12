# Introducing OxCaml

- Source: <https://blog.janestreet.com/introducing-oxcaml/>
- Published: 2025-06-14
- Kind: blog post

## Summary

- Jane Street names its compiler branch OxCaml and launches oxcaml.org with install
  instructions, tutorials and documentation of the extensions.
- OxCaml is both the firm's production compiler and a laboratory for performance-oriented
  extensions, which it hopes to upstream to OCaml over time.
- Design goals: safe, convenient (keep OCaml's type inference, avoid annotation overload) and
  predictable control over performance, by making key performance details explicit in types.
- The control is pay-as-you-go: code that does not use an extension pays no complexity for it,
  and every valid OCaml program remains a valid OxCaml program.
- Extension areas: type-level data-race freedom ("fearless concurrency"), layouts and native
  SIMD, allocation control to cut GC pressure and improve cache behaviour and determinism,
  and quality-of-life features (polymorphic parameters, include functor, labeled tuples,
  immutable arrays).
- It is built on the Flambda2 middle-end, which improves optimization and powers several of
  the new features.
- Tooling comes with it: opam and dune compatible packages, an LSP server and a formatter.
- The extensions carry no stability or backward-compatibility promise; Jane Street libraries
  ship in an extension-stripped form for upstream OCaml and a full form for OxCaml, and some
  libraries exist only for OxCaml.

## Relevance to us

- **Build and deploy:** every repository builds on the `5.2.0+ox` switch, and CI workflows
  add the `ox` opam repository without a commit, while the
  [infra](../../../repos/infra.md) base image already pins one. **Action:** pin the `ox`
  repository URL to the same commit as the base image in each repository's CI workflow,
  starting with [fixed-decimal](../../../repos/fixed-decimal.md), so an upstream change
  cannot break every build at once.
- **OCaml practice:** the "no stability promise" caveat means agent-written OxCaml code can
  break on upgrade. **Action:** record the pinned `ox` commit and the extensions we
  actually use in [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md), next to
  the gotchas log.
- **Performance:** allocation control and layouts are the extensions that would matter for
  [order-book](../../../repos/order-book.md) and [mm-core](../../../repos/mm-core.md) hot
  paths; concrete steps are in the locality and ICFP 2024 notes.

Tags: `oxcaml`, `build`, `performance`, `allocation`
