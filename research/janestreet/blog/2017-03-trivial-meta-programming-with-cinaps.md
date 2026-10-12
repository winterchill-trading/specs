# Trivial meta-programming with cinaps

- Source: <https://blog.janestreet.com/trivial-meta-programming-with-cinaps/>
- Published: 2017-03-20
- Kind: blog post

## Summary

- Introduces cinaps ("Cinaps Is Not A Preprocessing System"), a tool for repetitive code
  that is too local to justify a ppx and too annoying for cpp-style macros, which hurt
  readability, error locations and Merlin.
- Special comments embed OCaml code that prints text; cinaps checks that the text after the
  comment matches the output, exactly like an expect test, and can rewrite files in place.
  Works for OCaml, C and S-expression files.
- The generated code is committed and reviewed as ordinary code; regeneration is a build
  rule plus a diff.
- Example: C bindings exposing several sets of open flags through `Core.Flags`. A shared
  helper file lists the flag names once and generates both the OCaml modules and the C
  stubs; adding a flag is one list edit.
- Extended to generate a C program that prints the flag values as OCaml constants, making
  them static rather than initialized at runtime; generated code can be run through
  ocp-indent.
- Origin: replaced an ad hoc preprocessor DSL in ocaml-migrate-parsetree.

## Relevance to us

- Low: our repetition is handled by ppx_jane derivations, and the per-venue codecs in
  [hl-protocol](../../../repos/hl-protocol.md) and siblings differ enough that generated
  code would not help much. Worth remembering if venue enum tables multiply with the
  planned `*-feed` repositories.
- **Action:** none.

Tags: `ppx`, `ocaml-practice`, `build`
