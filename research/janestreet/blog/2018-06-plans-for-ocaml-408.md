# Plans for OCaml 4.08

- Source: <https://blog.janestreet.com/plans-for-ocaml-408/>
- Published: 2018-06-29
- Kind: blog post

## Summary

- Jane Street's Tools and Compilers group lists the upstream compiler work it aimed to land
  in OCaml 4.08, as part of making its compiler work more transparent.
- Language items: GADT constructors inside or-patterns; type-checking `let pat : typ = exp`
  in the order type, expression, pattern; allowing shadowing of items brought in by
  `include`; and `private` structure items for local helper types and modules.
- Module system "strengthening": transparent ascription (restrict a module to a signature
  while keeping its type equalities), aliases to functor parameters, and making
  `with module` and `module type of` keep equalities, accepting some breakage.
- Flambda: benchmark `-Oclassic` with a view to making it the default, and give recursion
  inlining controls such as `[@unroll]` a defined meaning; flambda 2.0 is underway.
- Tooling: better DWARF/GDB output, moving the parser to Menhir for better syntax errors,
  and unsigned integer operations on existing int types.

## Relevance to us

- Historical background for the OxCaml branch we build on (switch `5.2.0+ox`); many of these
  items shipped long ago or evolved into OxCaml features. Nothing actionable for our repos.
- **Action:** none.

Tags: `ocaml-practice`, `oxcaml`
