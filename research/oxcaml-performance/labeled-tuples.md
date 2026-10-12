# Labeled tuples

Kind: reference.

## What it is

Tuples whose components carry labels: `~min:1, ~max:9` has type `min:int * max:int`.
They allocate exactly like ordinary tuples; the gain is readability of multi-result
functions without declaring a record. The unboxed form `#(~bid:b, ~ask:a)` combines labels
with no allocation (see [unboxed products](unboxed-products.md)).

## When it pays

Not a performance feature by itself. Use the unboxed labeled form for hot multi-result
returns, the boxed form where a record type would be noise.

## Syntax on 5.2.0+ox (verified)

```ocaml
let min_max (a : int array) : min:int * max:int =
  Array.fold a ~init:(~min:Int.max_value, ~max:Int.min_value)
    ~f:(fun (~min, ~max) x -> ~min:(Int.min min x), ~max:(Int.max max x))

let range a = let ~min, ~max = min_max a in max - min
```

## Measured

Not benchmarked: same representation as a tuple.

## Pitfalls

- Partial patterns (`let ~y, .. = t`) need the type known from context.
- No projection by label; no reordering in expressions.

## Sources

- <https://oxcaml.org/documentation/miscellaneous-extensions/labeled-tuples/>
- Labeled Tuples, ML workshop 2024:
  <https://icfp24.sigplan.org/details/mlworkshop-2024-papers/2/Labeled-Tuples-Informed-Position->
