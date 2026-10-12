# Mixed blocks: records with unboxed fields

Kind: reference.

## What it is

An ordinary (boxed) record may hold `float#`, `int64#` and other unboxed fields next to
`value` fields. The compiler reorders fields so the `value` fields come first and the GC
scans only that prefix; the unboxed fields are stored flat. Fields may be `mutable`.

## When it pays

State records with float or `int64` fields that are updated per event. Today each `float`
field in a record that also holds non-float fields is a pointer to a separate 2-word box,
and every functional update `{ t with var = ... }` allocates new boxes. mm-core
`Market_state.t` and `Quoter.Model.t` are this shape.

## Syntax on 5.2.0+ox (verified)

```ocaml
type fill =
  { symbol : string; price : float#; qty : float#; exch_ts : int64#; mutable seq : int }

type st_mut = { mutable mvar : float#; mutable malpha : float#; mutable mcount : int }
let step_mut s x =
  s.mvar <- F.add (F.mul #0.9 s.mvar) (F.mul #0.1 (F.mul x x));
  s.mcount <- s.mcount + 1

(* deriving needs the Float_u.t alias from library unboxed.float_u *)
type t = { a : int; b : Float_u.t } [@@deriving sexp, compare, equal]
```

## Measured

Per-event update of a 3-field state (two floats and a count), `[@inline never]`:

| Shape | Words per call | Time (dev) |
| --- | ---: | ---: |
| immutable record, `float` fields, copy | 8 | 5.87 ns |
| immutable record, `float#` fields, copy | 4 | 4.93 ns |
| mutable record, `float#` fields, in place | 0 | 4.41 ns |

## Pitfalls

- Polymorphic compare and hash raise at run time on a mixed block:
  `Invalid_argument("compare: mixed block value")`. `=` on such a record compiles. Use
  derived `compare`/`equal`.
- `[@@deriving compare, equal, hash, bin_io]` on a `float#` field fails with
  `Unbound value "compare_float_u"` (and `equal_`, `hash_fold_`, `bin_shape_`); write the
  field type as `Float_u.t` from `unboxed.float_u`, which provides compare, equal and sexp.
  `bin_io` was not checked with `Float_u.t` (unverified).
- `[@@deriving sexp]` with a bare `float#` field compiles.
- Marshal and polymorphic hashing of mixed blocks raise; event logs must go through
  bin_prot.
- Block indices (`(.field.#sub)`, `Idx_mut`) give interior pointers into such records;
  the modules exist in `stdlib_stable` but were not exercised here (unverified).

## Sources

- <https://oxcaml.org/documentation/unboxed-types/intro/> (mixed block layout).
- Mixed Blocks: Storing More Fields Flat, OCaml workshop 2024:
  <https://icfp24.sigplan.org/details/ocaml-2024-papers/7/Mixed-Blocks-Storing-More-Fields-Flat>
- <https://oxcaml.org/documentation/unboxed-types/block-indices/>
