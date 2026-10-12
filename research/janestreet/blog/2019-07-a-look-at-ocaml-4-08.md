# A look at OCaml 4.08

- Source: <https://blog.janestreet.com/a-look-at-ocaml-4.08/>
- Published: 2019-07-12
- Kind: blog post

## Summary

- A retrospective on the Tools and Compilers team's plan for OCaml 4.08; the freeze came
  late, and features not ready by the original October date were mostly set aside.
- Landed as planned: GADT constructors in or-patterns (only when the cases need no type
  equations), and shadowing of items brought in by `include`, replacing an awkward
  signature-constraint workaround.
- Private items: after debate, two features merged. `open struct ... end` hides helper
  definitions in structures, and `type t := ...` / `module M := ...` defines local aliases
  in signatures, styled after destructive substitution.
- Not landed: checking `let p : t = e` in the order t, e, p (needed for better constructor
  disambiguation), and transparent ascription in the module system (about 80 percent done,
  with supporting refactors merged).
- Flambda: `-Oclassic` was not made the default because it handled recursive functions
  worse than the regular compiler; Flambda 2.0 is expected to replace it. Intern work on
  inlining heuristics for recursion slipped to 4.10, and DWARF/gdb improvements stalled over
  upstream concerns about scope.
- The parser moved to Menhir (error messages not yet improved), and unsigned operations were
  added to `Int32`, `Int64` and `Nativeint`.
- Unplanned work: binding operators (`let*`, `let+`) bring ppx_let-style syntax into the
  language; a GADT soundness bug in 4.07.0 forced an internal rollback to 4.06.1 and was
  fixed by splitting the type checker's "stamp" into stamp and scope.
- More unplanned work: Dynlink made sound (then loosened for Coq plugins), class signature
  representation reworked, Stdlib modules no longer shadow same-named external modules,
  exception patterns under or-patterns restored, and patches toward reproducible builds to
  support build caching.
- From others: generalized alerts (`[@@alert name "msg"]`, with `deprecated` now sugar for
  one), new Stdlib modules `Fun`, `Bool`, `Int`, `Option`, `Result`, better type error
  messages, and an autoconf-based configure.

## Relevance to us

- **OCaml practice:** named alerts let a library flag risky functions at every call site
  without deprecating them. **Action:** add `[@@alert lossy "..."]` to `of_float` in
  [fixed-decimal](../../../repos/fixed-decimal.md) and mark the intended call sites with
  `[@alert "-lossy"]`, so new float conversions of prices and sizes are visible in review.
- **OCaml practice:** `open struct ... end` keeps helpers out of a module's exported surface
  even without an `.mli`. **Action:** none; our convention of an `.mli` for every module
  already covers this.
- Most of the post is compiler history; our `5.2.0+ox` switch includes all of these
  features.

Tags: `ocaml-practice`, `build`
