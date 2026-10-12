# Introducing OxCaml

- Source: <https://blog.janestreet.com/introducing-oxcaml/>
- Published: 2025-06-14
- Kind: blog post

## Summary

- Jane Street names its compiler branch OxCaml and launches oxcaml.org with install
  instructions, tutorials and extension documentation.
- OxCaml is both the firm's production compiler and a laboratory for performance-oriented
  extensions, intended to be upstreamed to OCaml over time.
- Design goals: safe, convenient (keep type inference, few annotations) and predictable
  control over performance, pay-as-you-go, and every valid OCaml program stays valid.
- Extension areas: data-race freedom in the type system, layouts and SIMD, allocation
  control to reduce GC pressure, and quality-of-life features (polymorphic parameters,
  include functor, labeled tuples, immutable arrays), all on top of the Flambda2 middle-end.
- It ships with tooling that works with dune and opam, an LSP server and a formatter.
- The extensions carry no stability or backward-compatibility promise; Jane Street libraries
  are released in an extension-stripped form for upstream OCaml and a full form for OxCaml,
  and some exist only for OxCaml.

## Relevance to us

- Our whole stack builds on the `5.2.0+ox` switch, so the "no stability promise" caveat
  applies to every repository; CI pulls the `ox` opam repository at whatever is current.
- The allocation-control and data-race extensions are the ones that would matter for
  [mm-core](../../../repos/mm-core.md) and [order-book](../../../repos/order-book.md) hot
  paths; we use none of them yet, and
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md) is where usage notes belong.
- **Action:** pin the `ox` opam repository to a fixed commit in each repository's CI
  workflow (and record that commit in `oxcaml-claude-skills`) so an upstream OxCaml change
  cannot break all builds at once.

Tags: `oxcaml`, `build`, `performance`, `allocation`
