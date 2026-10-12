# Language Design

- Source: <https://signalsandthreads.com/language-design/>
- Published: 2020-10-21
- Kind: Signals and Threads episode 7

## Summary

- The guest works on the compiler front end (type system and language features). They got
  into OCaml compiler work by adding a feature they wanted while writing a C compiler in
  OCaml during a PhD, which led to a research post at OCaml Labs and then Jane Street.
- Languages are mostly designed by compiler writers; the guest concedes OCaml is very good
  for writing compilers but argues most languages are not, so the bias is limited.
- Language design is framed as mathematics plus aesthetics, closer to architecture than to
  an experimental science: long controlled studies with professional programmers are
  impractical, and academic venues discuss aesthetics only informally, outside the talks.
- OCaml's identity: general purpose (scripting to low-level code), predictable performance
  (an experienced reader can roughly guess the generated assembly), a strong type system,
  and a serious approach to modularity.
- Strong types change habits: programmers structure code so the checker catches mistakes,
  and the guest notes feeling uneasy whenever two values of the same type are in scope,
  because those are the ones that can be swapped by accident.
- Modularity means swappable components behind interfaces. Everything lives in modules,
  functors parameterize any module over any other, and interfaces are separate files in
  their own language, so every new feature must be expressible in signatures. This
  constraint is compared with how laziness forced Haskell to stay pure.
- The guest sees the lack of a module system in Rust as a real shortcoming.
- Type classes (and Rust traits) are called anti-modular: only one instance per type may
  exist in a whole program, conflicts appear only at link time, and the choice leaks out of
  any abstraction boundary.
- Modular implicits allow several instances, search them by simple lexical scope, and make
  ambiguity an error; Scala implicits, by contrast, search many places and rank candidates,
  which makes code harder to reason about.
- "Mathematical simplicity" really means fewer sharp corners when features interact; C++ is
  the counterexample where templates, overloading and inheritance combine unpredictably.
  Simple formal semantics usually mean the feature is also easier for humans to reason
  about.
- GADTs, added with compiler-like uses in mind, proved valuable for performance work and
  for controlling memory representation, an example of well-founded features generalizing.
- Evolving an existing language is harder than designing a new one but is the only
  realistic way to reach users. Good ideas spread slowly: type inference, garbage
  collection (1950s, mainstream with Java) and sum types (1980s, still missing from Go).
- Popularity raises the cost of incompatible changes (Python 2 to 3 is the cautionary
  tale); compatible changes should be preferred whenever possible, and the goal is enough
  users for a healthy library ecosystem rather than maximum popularity.
- Gaps versus C, C++ and Rust: control of memory layout (each record field takes a word, a
  boxed 32-bit integer costs several words), GC-free code losing records and variants, safe
  stack allocation (which needs type-level control of escaping references) and resource
  management for files and connections. Unboxed types were in progress; these later became
  OxCaml features.
- Dependent types would replace encodings such as phantom read/write type parameters on file
  handles with indexing by real variant values. Such encodings are easy to get silently
  wrong, and GADT users reach for them immediately, which signals the real need.
- Working with upstream brings expert review and the open-source library ecosystem; Jane
  Street has sometimes developed features internally too long before sharing. An OCaml RFCs
  repository now lets designs be discussed before code.
- Forking would allow faster internal experiments (features can be changed across a
  monorepo), but the cost is rebasing large textual patches; Jane Street's internal branch
  was growing, and better internal compiler APIs would make that cheaper.
- Typed, Racket-style compiler extensibility is called an open research problem because
  extensions would need modular soundness proofs; the guest's own type-soundness proof in
  Coq took about two years of a longer project.
- Staged macros give the performance of low-level code with high-level descriptions: an
  intern's stream library turned a chain of map and filter stages into a single loop at
  compile time, putting optimization under the library author's control.
- Algebraic effects subsume async/await, generators, coroutines and backtracking in one
  mathematically grounded feature; they are as expressive as delimited continuations but
  can be typed.
- Implicitness is a trade-off: ad-hoc polymorphism needs some, and the design goal is the
  least possible; how much "rope" a feature gives depends also on library discipline.

## Relevance to us

- Our codebase already follows the episode's advice in places: `Price`, `Size` and `Usd` are
  distinct `Fixed_decimal.Make ()` types and `Order_id`, `Client_order_id` and `Trade_id`
  are separate modules in [exchange-core](../../../repos/exchange-core.md).
- **OCaml practice:** Phantom permission parameters are fragile, but a read-only versus
  trading client is still worth enforcing in types. **Action:** when EIP-712 signing lands
  (see [roadmap](../../../roadmap.md)), give the client handle in
  [hl-client](../../../repos/hl-client.md) a phantom `read_only`/`trading` parameter so the
  read-only clients used by [market-recorder](../../../repos/market-recorder.md) cannot be
  passed to order endpoints.
- **OCaml practice:** The recorder builds Binance configs with empty API keys to get a
  read-only client, which is the same permission question answered by convention.
  **Action:** add a key-less `Config.read_only` constructor to
  [binance-client](../../../repos/binance-client.md) and use it in
  [market-recorder](../../../repos/market-recorder.md) instead of `~api_key:""`.
- **OCaml practice:** Signatures are the unit of design; our `Mm_core.Venue.S` in
  [mm-core](../../../repos/mm-core.md) already lets one strategy run on three venues.
  **Action:** add a short "signature first" note to the skills in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md) telling agents to write
  the `.mli` and a functor seam before the implementation when adding a venue.
- **Performance:** The layout and stack-allocation gaps named here are what OxCaml's
  unboxed types and `local_` now address. **Action:** record in
  [order-book](../../../repos/order-book.md)'s README which hot-path records would benefit
  from unboxed fields, as a checklist for a later OxCaml pass.

Tags: `ocaml-practice`, `oxcaml`, `architecture`, `education`
