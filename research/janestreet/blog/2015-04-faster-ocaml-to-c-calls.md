# Faster OCaml to C calls

- Source: <https://blog.janestreet.com/faster-ocaml-to-c-calls/>
- Published: 2015-04-09
- Kind: blog post

## Summary

- Covers external-call features missing from the official C interface documentation.
- A C stub that never allocates on the OCaml heap can skip the `CAMLparam`/`CAMLreturn`
  root registration and be declared `"noalloc"`; a float compare dropped from about 8.9 ns
  to 5.3 ns.
- Floats crossing into C are normally boxed, so a one-instruction `minsd` stub was slower
  (about 16 ns) than plain OCaml (about 6 ns).
- Declaring the external `"float"` with separate bytecode and native stubs lets C take and
  return raw doubles; the same min then cost about 2 ns.
- For functions returning an int, returning a double and converting in OCaml avoids boxing
  as well (about 3.7 ns for compare).
- Modern compilers spell these as `[@@noalloc]` and `[@unboxed]` attributes.

## Relevance to us

- None of our repositories write their own C stubs; zstd and OpenSSL come through existing bindings
  used by [market-recorder](../../../repos/market-recorder.md) and
  [venue-net](../../../repos/venue-net.md), off the hot path.
- **Action:** none.

Tags: `performance`, `allocation`, `ocaml-practice`
