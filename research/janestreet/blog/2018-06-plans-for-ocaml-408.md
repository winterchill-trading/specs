# Plans for OCaml 4.08

- Source: <https://blog.janestreet.com/plans-for-ocaml-408/>
- Published: 2018-06-29
- Kind: blog post

## Summary

- Jane Street's Tools and Compilers group lists work it aimed to land upstream for OCaml
  4.08, under the six-month time-based release cycle, as part of being more transparent
  about compiler work.
- GADT constructors in or-patterns, without yet using the type equations they introduce in
  the shared branch.
- Type propagation in lets: an explicit AST form for `let pat : typ = exp`, checked in the
  order type, expression, pattern.
- Shadowing of items that came from `include`, to make extending a module concise.
- `private` structure items (local helper types and modules not exported), also usable in
  signatures, and a way to fix `ocamlc -i` printing incorrect interfaces.
- Module system strengthening, accepting short-term breakage: transparent ascription
  (restrict to a signature but keep type equalities), aliases to functor parameters,
  `with module` producing an alias plus new forms to extend a submodule's signature, and
  `module type of` returning the strengthened type with a `[@weak]` escape hatch.
- Flambda: benchmark `-Oclassic` as a possible default, and give recursion inlining
  controls such as `[@unroll]` and max depth a defined meaning; flambda 2.0 underway.
- Better DWARF and GDB support, moving the parser to Menhir for better syntax errors, and
  unsigned operations on existing integer types.

## Relevance to us

- Historical background for the OxCaml branch we build on (`5.2.0+ox`); most items shipped
  long ago or evolved. **Action:** none.

Tags: `ocaml-practice`, `oxcaml`
