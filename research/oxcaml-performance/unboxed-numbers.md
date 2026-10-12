# Unboxed numbers: float#, int64#, int32#, nativeint#

Kind: reference.

## What it is

Types with a non-`value` layout (`float#` is `float64`, `int64#` is `bits64`, and so on)
that live in registers and in record fields without a box. They never allocate when passed
to or returned from a function, unlike `float`, `Int64.t` and `Int32.t`, which are boxed
whenever they cross a non-inlined call or are stored in a polymorphic structure.

## When it pays

Floating-point state updated per message (mm-core `Market_state` variance and alpha, the
quoter's model terms), float accumulators in loops, and boxed `Int64` fields (exchange
timestamps if they were `int64`). Integer prices that already fit in an immediate `int`
(fixed-decimal) gain nothing.

## Syntax on 5.2.0+ox (verified)

```ocaml
module F = Stdlib_upstream_compatible.Float_u      (* library stdlib_upstream_compatible *)
module I64 = Stdlib_upstream_compatible.Int64_u

let notional (px : float#) (qty : float#) : float# = F.mul px qty
let one_bp = #0.0001
let ts : int64# = #1_700_000_000_000_000_000L
let next_ts (t : int64#) = I64.add t #1L
let boxed px qty = F.to_float (notional (F.of_float px) (F.of_float qty))
```

`Float_u` with `compare`, `equal`, `sexp_of_t` and quickcheck also exists in the opam
library `unboxed.float_u` (likewise `unboxed.int64_u`, `unboxed.int32_u`), and is what
`[@@deriving compare, equal]` needs on a `Float_u.t` field. No extension flag is needed.

## Measured

| Case | Words per call | Time (dev) |
| --- | ---: | ---: |
| sum 1000 floats, recursive, `float` accumulator | 2000 | 776 ns |
| sum 1000 floats, recursive, `float#` accumulator | 2 | (not timed) |
| sum 1000 floats, `let mutable` `float#` accumulator | 2 | 678 ns |
| `(ask -. bid) /. bid` under `[@zero_alloc]` | fails: 16 bytes | |
| same over `float#` under `[@zero_alloc]` | passes | |

## Pitfalls

- `float#` cannot appear in a tuple, an `option`, a list or any type parameter expecting
  `value`: `float# option` fails with `The layout of float# is float64 ... But the layout of
  float# must be a value layout`. Use an unboxed tuple or record instead.
- `exception E of float#` fails (`Extensible types can't have fields of unboxed type`).
- A variant constructor with an `int64#` argument (`K of int64#`) compiles on this switch,
  although the oxcaml.org page lists it as a restriction.
- `ppx_jane` derivers look for `compare_float_u` and friends; use `Float_u.t` from the
  `unboxed.float_u` library as the field type, not `float#`.
- Converting at every boundary (`F.of_float` in, `F.to_float` out) gives the boxing back;
  keep the unboxed value through the hot function.

## Sources

- <https://oxcaml.org/documentation/unboxed-types/intro/>
- Tech talk, Unboxed Types for OCaml: <https://www.janestreet.com/tech-talks/unboxed-types-for-ocaml/>
- <https://blog.janestreet.com/icfp-2024-index/>; our note
  [2024-08 ICFP 2024](../janestreet/blog/2024-08-icfp-2024.md).
