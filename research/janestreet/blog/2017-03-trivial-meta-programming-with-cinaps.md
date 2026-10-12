# Trivial meta-programming with cinaps

- Source: <https://blog.janestreet.com/trivial-meta-programming-with-cinaps/>
- Published: 2017-03-20
- Kind: blog post

## Summary

- Repetitive code usually calls for a generator such as a ppx, but generators are harder to
  review and add syntax to learn, which is not worth it for patterns local to one library.
- Macro preprocessors (cpp, cppo) hurt readability, give misleading error locations and
  break Merlin.
- For a local pattern of reasonable size, committing and reviewing the generated code is
  fine; cinaps ("Cinaps Is Not A Preprocessing System") supports exactly that.
- Special comments embed OCaml that prints text; cinaps checks that the text following the
  comment equals the output, like an expect test, and can rewrite files in place. Syntaxes
  exist for OCaml, C and S-expression files.
- Example: older C bindings exposing several sets of open flags through `Core.Flags`, each
  needing external declarations, values, a known-flags list and C stubs.
- A shared helper file (not a module of the library) lists flag names once and defines a
  printer; the OCaml and C files each call it, and adding a flag is one list edit plus a
  regeneration rule in the build.
- Taken further: cinaps also writes a C program that prints flag values as OCaml
  constants, so flags become static instead of initialized at runtime.
- Generated code can be piped through ocp-indent via a styler option.
- Origin: replaced a cpp-like ad hoc DSL in ocaml-migrate-parsetree that made sources hard
  to read; the post notes ctypes is usually the better choice for new bindings.

## Relevance to us

- Our repetition is handled by ppx_jane derivations, and the per-venue codecs in
  [hl-protocol](../../../repos/hl-protocol.md) and its siblings differ too much for shared
  generated code. Worth recalling if enum tables multiply across the planned `*-feed`
  repositories. **Action:** none.

Tags: `ppx`, `ocaml-practice`, `build`
