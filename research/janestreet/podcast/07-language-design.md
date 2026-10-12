# Language Design

- Source: <https://signalsandthreads.com/language-design/>
- Published: 2020-10-21
- Kind: Signals and Threads episode 7

## Summary

- The guest, a compiler front-end engineer, frames language design as mathematics plus
  aesthetics (closer to architecture than to an experimental science), since controlled
  studies of professional programmers over long periods are impractical.
- OCaml's identity: general purpose, predictable performance (an experienced reader can
  guess the assembly), a strong type system, and a serious module system with separate
  interface files and functors; every new feature must be expressible in signatures.
- Type classes are called anti-modular: only one instance per type may exist in a program,
  and clashes surface at link time. Modular implicits keep ad-hoc polymorphism but allow
  several instances, resolve them by simple lexical scope, and reject ambiguity outright.
- Gaps versus C++ and Rust: control of memory layout (every record field takes a word, a
  boxed `Int32` costs several words), stack allocation that cannot leak, and resource
  handling for files and connections. Unboxed types were the planned answer; these later
  became OxCaml features.
- Phantom read/write type parameters are an awkward encoding that is easy to get silently
  wrong; dependent types would let a type be indexed by a real variant value instead.
- Jane Street prefers upstreaming over a full fork to keep expert review and the wider
  ecosystem, but carries a growing internal patch branch; an OCaml RFCs repository moves
  design discussion before code.
- Staged macros can turn a pipeline of map/filter/fold stages into one loop at compile time,
  giving the library author explicit control over performance; algebraic effects unify
  async/await, generators and coroutines under one typed feature.

## Relevance to us

- Our conventions already lean on the episode's advice: distinct `Fixed_decimal.Make ()`
  types for `Price`, `Size` and `Usd` in [exchange-core](../../../repos/exchange-core.md),
  and the `Mm_core.Venue.S` signature in [mm-core](../../../repos/mm-core.md) with one
  adapter per venue.
- The memory-layout and stack-allocation gaps it lists are what OxCaml now addresses, which
  matters for hot paths in [order-book](../../../repos/order-book.md).
- **Action:** when EIP-712 signing lands in [hl-client](../../../repos/hl-client.md) (see
  [roadmap](../../../roadmap.md)), give the client handle a phantom permission parameter so
  a read-only client, as used by `market-recorder`, cannot be passed to order endpoints.

Tags: `ocaml-practice`, `oxcaml`, `architecture`, `education`
