# `or_null`: an option that does not allocate

Kind: reference.

## What it is

`'a or_null` has constructors `Null` and `This x`. `Null` is the word 0, which no OCaml
value uses, so `This x` is represented as `x` itself and needs no box. It has layout
`value_or_null` and cannot nest (`t or_null or_null` is rejected). The `Or_null` module in
`stdlib_stable` mirrors `Option`.

## When it pays

Lookups on the hot path that return "maybe a value" for a `value` payload: best bid or ask,
a table lookup, the last BBO for an instrument. It is simpler than a local option because
the result can be stored and returned freely.

## Syntax on 5.2.0+ox (verified)

```ocaml
let best_or_null b : int or_null = if b.n = 0 then Null else This b.bids.(b.n - 1)

let use b = match best_or_null b with Null -> 0 | This x -> x
```

`or_null`, `Null` and `This` are in scope without an `open`.

## Measured

| Return type, `[@inline never]` | Words per call | Time (dev / `-O3`) |
| --- | ---: | ---: |
| `int option` | 2 | 3.91 / 3.63 ns |
| `int or_null` | 0 | 3.59 / 3.37 ns |
| `string option` | 2 | 3.20 ns |
| `string or_null` | 0 | 3.32 ns |

## Pitfalls

- `float or_null array` is forbidden (not separable); arrays of `or_null` need
  `any_non_null` element layouts.
- `or_null` cannot be a type argument where `value` is required, so an `or_null` cannot go
  into a `list` or `Map` directly.
- A third-party parser abandoned `or_null` after long layout-inference errors and used a
  local option instead; give `or_null` results an explicit type annotation.
- Core `Option` functions do not accept it; use `Stdlib_stable.Or_null` or match.

## Sources

- <https://oxcaml.org/documentation/unboxed-types/or-null/>
- A Non-allocating Option, OCaml workshop 2024:
  <https://icfp24.sigplan.org/details/ocaml-2024-papers/8/A-Non-allocating-Option>
- <https://anil.recoil.org/notes/oxcaml-httpz>
