# The Future of Programming

- Source: <https://signalsandthreads.com/future-of-programming/>
- Published: 2023-05-18
- Kind: Signals and Threads episode 16

## Summary

- The guest is a long-time GHC contributor, GHC Steering Committee member and Haskell
  Foundation chair. He was a high school teacher and a professor before joining Jane
  Street's OCaml front-end team, after declining the first offer.
- Dependent types let a program carry a proof that the compiler checks. Example: a sort
  whose type says the output is non-descending and a permutation of the input, which rules
  out the always-empty answer that a weaker specification allows.
- Proofs are costly, so dependent types must be opt-in: prove only the parts where bugs are
  expensive enough to justify it, a matter of taste and cost versus testing and debugging.
  OCaml's module system is already partly dependently typed; Coq, Agda, Idris and Lean go
  all the way.
- His principle: types should structure thought and catch errors at compile time, and a
  type feature that slows the running program is a design mistake.
- He is working on unboxed types, which inline nested records so that reaching a trade's
  price does not chase several pointers. They make performance decisions explicit in types
  rather than invisible.
- Compiler optimizations give broad gains of around 20%, while tools for performance
  engineering let one engineer make one program 5x to 100x faster. Languages must expose
  enough low-level detail for that without exposing everything.
- Unboxed layouts break uniform polymorphism (one `List.length` for any element), so the
  plan is to generate code per layout, probably at compile time, giving up a few rare
  idioms.
- Rust gives up garbage collection, so every program pays for memory control everywhere.
  OCaml keeps GC by default and adds control where needed, a kind of per-file or
  per-package pay as you go. Polyglot systems (Python with OCaml) offer the same split, with
  interop work growing quadratically in the number of languages.
- Making boxing an explicit operation that is normally inserted silently means a compiler
  flag could require every allocation to be written out, without going as far as Rust.
- Gradual or optional typing tends to bring complexity; C and C++ types can be cast away
  freely. Uniform choices, such as types everywhere in OCaml and Haskell, are a reasonable
  design point.
- OCaml grew out of Inria research; Jane Street benefits from upstream work such as OCaml
  5 multicore and contributes back. The guest sees not owning the language as a strength.
- Jane Street prototypes language features internally, where a tree smash (one diff across
  the whole codebase) can change syntax everywhere at once, as happened when the local
  allocation syntax changed. Features go upstream once proven; public talks from the start
  guard against overfitting to Jane Street's style.
- Open-source languages cannot easily undo a released mistake, because some users depend
  on it.
- Haskell is more explicit about compile time (signatures next to code, which encourage
  comments; typeclasses, which hide which operation runs). OCaml is more explicit about run
  time: strict evaluation in source order is easier to predict than laziness, though GHC
  optimizes harder. Interface files hold OCaml's types apart from the code.
- Both compilers contain old code written before anyone knew the language well.
- Haskell began as a committee standard with several compilers, hence about 150 extensions.
  Newcomers cannot tell experimental ones from long-standing or dangerous ones, and the
  guest wants them consolidated to a handful while keeping old code working.
- On AI assistants: a big step but not a break. Programming languages exist for precise
  communication, now also from machine to human, so languages should favor reading over
  writing, with searchable words rather than clever symbols.
- Dependent types could serve as precise specifications given to a model, with the
  compiler checking the implementation so it need not be read. Letting the model write the
  specification too is the danger, because then nobody checks it. It is too early to design
  a language around AI.

## Relevance to us

- Most of our code is written by agents following
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md). The episode's point is
  that the reviewable artifact should be a precise specification (`.mli` types and
  properties), not the implementation.
- Our distinct `Price`, `Size` and `Usd` types in
  [exchange-core](../../../repos/exchange-core.md) are a small instance of putting
  intent in types at no run-time cost.
- **OCaml practice:** when an agent writes the code, a checked specification is what a
  human can actually review. **Action:** add a rule to the `janestreet-ocaml-style` skill
  that any agent change to a public `.mli` must add or update a Base_quickcheck property
  stating the function's contract in the same commit, in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).
- **OCaml practice:** OCaml interfaces tend to carry too little documentation, and docs
  live in `.mli` files. **Action:** add a CI step running `dune build @doc` with warnings
  as errors, and doc comments on every exported value, in
  [fixed-decimal](../../../repos/fixed-decimal.md) as the pilot.
- **OCaml practice:** owning every repo lets us make coordinated changes everywhere at
  once, like a tree smash, instead of carrying compatibility shims. Context only; the local
  workspace with sibling repos already supports this.

Tags: `ai-tools`, `oxcaml`, `property-testing`, `ocaml-practice`
