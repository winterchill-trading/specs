# Small numbers and immutable arrays

Kind: reference.

## What it is

- `int8`, `int16` (tagged immediates) and their unboxed `int8#`, `int16#`; `float32` and
  `float32#`; `char#`. Arrays of the unboxed forms are packed (one byte per `int8#`).
- `iarray`: an immutable array, covariant, whose contents may be stack allocated and which
  crosses contention (safe to share between domains).

## When it pays

Packed arrays of small values (per-level flags, side bytes, `int16#` offsets into a
buffer under 32 KB as in a third-party HTTP parser), and read-only tables shared across
domains. Prices and sizes in this org are 63-bit fixed point and stay `int`.

## Syntax on 5.2.0+ox (verified)

```ocaml
let i8 : int8 = 42s
let i16u : int16# = #42S
let f32 : float32 = 1.5s
let i16_to_int x = Stdlib_stable.Int16_u.to_int x

let levels : int iarray = [: 1; 2; 3 :]
let second = Stdlib_stable.Iarray.get levels 1
```

Library `stdlib_stable`. No extension flag is needed (the default extension universe on
this switch includes `small_numbers`; `-extension-universe upstream_compatible` rejects
`float32`).

## Measured

Not benchmarked.

## Pitfalls

- Boxed `float32` is a custom block like `int32`; only `float32#` avoids allocation.
- `Iarray` is in `stdlib_stable`, not in Core's `Array`; most Core idioms do not apply.

## Sources

- <https://oxcaml.org/documentation/miscellaneous-extensions/small-numbers/>
- <https://oxcaml.org/documentation/miscellaneous-extensions/immutable-arrays/>
