# Formal methods and the future of programming

- Source: <https://blog.janestreet.com/formal-methods-at-jane-street-index/>
- Published: 2026-06-07
- Kind: blog post

## Summary

- For 25 years the firm said it was not interested in formal methods, despite valuing
  type systems (a lightweight formal method) highly; outside hardware synthesis the costs
  looked too high. seL4 is the benchmark: about 25 person-years to verify 8,700 lines of C,
  roughly 23 lines of proof and half a person-day per line.
- Agentic coding changed that view, and the firm is building a formal methods team aiming
  to make proofs as routinely useful as rich types are today.
- Cost side: models cannot produce arbitrary hard proofs alone, but they handle much of
  the encoding drudgery and widen who can use provers; humans still supply the high-level
  proof ideas.
- Benefit side, first reason: verification is the bottleneck. Agents reach the stated goal
  but tend toward overcomplicated code with odd corner-case bugs that ignore codebase
  invariants, so review is costly and formal guarantees could cut it.
- Second reason: agents thrive on feedback, both during RL training and while coding, and
  proofs are one more strong signal.
- Tests, property-based tests, fuzzing and expect tests remain valuable but cannot cover
  the state space. Universal type-level guarantees, such as OxCaml's data-race freedom or
  types that rule out cross-site scripting, have proven especially useful with agents.
- Escape hatches such as `Obj.magic` can be tracked and banned for most code, giving
  near-universal guarantees; proofs could even justify the remaining uses.
- Why in-house: control of the language allows modular specifications in types, ownership
  and mutability constraints that ease proofs, and proof techniques built into the
  language.
- And an internal user base that actively asks for new type-system features, which allows
  both near-term improvements and longer bets; the team will also look to integrate with
  Lean, Dafny, Rocq, Agda and Iris.

## Relevance to us

- **OCaml practice:** universal guarantees from types are the cheapest check on
  agent-written code, and escape hatches undo them. **Action:** add a rule and a one-line
  CI grep to [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md), reusable in
  every org repository's workflow, that fails the build on `Obj.magic` or `Obj.repr` outside
  an explicit allowlist.
- **OCaml practice:** distinct unit types already encode a key invariant (prices, sizes and
  USD cannot be mixed). **Action:** add a test in [fixed-decimal](../../../repos/fixed-decimal.md)
  (an expect test over a small file that must fail to compile, or a dune rule expecting a
  type error) proving `Price.t` cannot be passed where `Size.t` is expected.
- **Testing and simulation:** properties stated once can serve as both tests and future
  proof targets. **Action:** turn the [order-book](../../../repos/order-book.md) invariant
  check into a Base_quickcheck property run after every random sequence of submit and
  cancel operations, if it is not already exercised that way.

Tags: `formal-methods`, `ai-tools`, `oxcaml`, `ocaml-practice`
