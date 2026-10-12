# The `zero_alloc` checker

Kind: reference.

## What it is

`[@zero_alloc]` on a function makes the compiler prove that the function and everything it
calls perform no heap allocation on normal return paths, or fail the build. The check runs
in the backend after Flambda 2, has no runtime cost, and is on by default for annotations
without the `opt` payload.

## When it pays

On a function that must stay allocation-free across refactors and compiler upgrades: the
per-frame scanner of a venue normalizer, fixed-point arithmetic, a book-level accessor.
It replaces a words-per-call expect test with a compile error that names the allocation.

## Syntax on 5.2.0+ox (verified)

```ocaml
let[@zero_alloc] add_mul a b c = (a + b) * c

let[@zero_alloc] sum (a : int array) =
  let mutable acc = 0 in
  for i = 0 to Array.length a - 1 do acc <- acc + Array.unsafe_get a i done;
  acc

(* relaxed (default): allocation on a path that raises is ignored *)
let[@zero_alloc] check_qty q =
  if q <= 0 then failwith (Printf.sprintf "bad qty %d" q) else q

(* strict: no allocation on any path *)
let[@zero_alloc strict] check_qty_strict q = if q <= 0 then failwith "bad" else q
```

In an `.mli`, `val sum : int array -> int [@@zero_alloc]` is accepted and enforced: an
implementation without the attribute that allocates fails. The oxcaml.org page writes
`val[@zero_alloc] f : ...`; both forms work here.

## Measured

The failure is a compile error with the allocation site and size:

```text
Error: Annotation check for zero_alloc failed on function ...spread_ratio (...).
Error: allocation of 16 bytes for float
```

`(ask -. bid) /. bid` returning a boxed `float` fails; the same function over `float#`
passes. The hand-written trade-frame scanner in [zero-copy parsing](zero-copy-parsing.md)
passes with `[@zero_alloc]` on every function.

## Pitfalls

- Indirect calls (closures, functor arguments not inlined, `List.iter`) count as
  allocating. `Map`, `Hashtbl`, `Queue` and `Yojson` paths cannot be annotated.
- `[@zero_alloc strict]` with `failwith (sprintf ...)` fails with `allocation of 24 bytes on
  a path to exceptional return`; a literal message passes because the exception is static.
- Without `-g` every `raise` behaves like `raise_notrace` and relaxed annotations fail on
  error paths (unverified here; the dune dev and release profiles both pass `-g`).
- Results depend on inlining; annotate functions that pass in the dev profile. Use
  `[@zero_alloc opt]` for those that pass only optimised, checked with
  `-zero-alloc-check all`.
- A value binding `let[@zero_alloc] f = g` triggers warning 53; write the arguments out.
- The checker treats poll points as non-allocating, so it does not prove the absence of a
  GC slice or a signal handler run.

## Sources

- <https://oxcaml.org/documentation/miscellaneous-extensions/zero_alloc_check/>
- <https://blog.janestreet.com/oxidizing-ocaml-locality/> ("zero-allocation" code at the
  source firm).
- <https://www.tunbury.org/2026/03/13/oxcaml-inference/> (third-party use with SIMD).
