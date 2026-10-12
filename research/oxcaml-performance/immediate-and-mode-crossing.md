# Immediate types and mode crossing

Kind: reference.

## What it is

A type whose values are always tagged integers (`int`, `bool`, `char`, constant-only
variants) has kind `immediate`. Exporting that kind from an abstract type tells the
compiler, and every caller, that the type is never a pointer: no write barrier on stores,
no GC scanning, and the type crosses modes, so a local or contended value of it can be
used as if global and uncontended.

## When it pays

Abstract numeric types in a signature (`Price.t`, `Size.t`, `Order_id.t` as int). Without
the kind, a caller holding a `local` `Price.t` cannot store it, and stores into mutable
fields pay the `caml_modify` barrier. fixed-decimal already declares `type t : immediate`.

## Syntax on 5.2.0+ox (verified)

```ocaml
module Px : sig
  type t : immediate
  val of_int : int -> t
end = struct
  type t = int
  let of_int = Fn.id
end

module Px2 : sig
  type t [@@immediate]          (* older spelling, also accepted *)
  val of_int : int -> t
end = ...
```

## Measured

Not separately benchmarked. The order-book `-O3` gain (match one fill 66 to 37 ns) comes
from inlining fixed-decimal comparisons, which the immediate kind makes allocation-free.

## Pitfalls

- `type t [@@immediate]` in a signature can trigger the unused-type warning in a
  signature-only module; add `[@@warning "-unused-type-declaration"]` (GOTCHAS.md).
- A `local_` option of an abstract type that is not exported immediate is useless to
  callers that need to keep the payload.
- Mode crossing also applies to deeply immutable types (contention) and types without
  functions (portability); see [parallelism](parallelism.md).

## Sources

- <https://oxcaml.org/documentation/kinds/intro/>
- <https://oxcaml.org/documentation/modes/intro/> (mode crossing).
- Our note [2024-08 ICFP 2024](../janestreet/blog/2024-08-icfp-2024.md).
