# Unboxed tuples and unboxed records

Kind: reference.

## What it is

`#(a, b)` is a tuple with no block: its components travel in registers. `#{ f = ... }` is
the same for a record type declared with `type t = #{ ... }`, and every ordinary record
type `t` also has an implicit unboxed version `t#`. Labeled unboxed tuples
(`#(~bid:..., ~ask:...)`) combine this with [labeled tuples](labeled-tuples.md).

## When it pays

Functions that return two or three results on a hot path and are not inlined: a mid and
microprice pair, a quotient and remainder in fixed-point division, a parse result and the
next position in a scanner. Inlined calls often have the tuple removed by Flambda 2 anyway.

## Syntax on 5.2.0+ox (verified)

```ocaml
let[@zero_alloc] div_mod a b = #(a / b, a mod b)
let use_div_mod a b = let #(q, r) = div_mod a b in q + r

let[@zero_alloc] bid_ask px = #(~bid:(px - 1), ~ask:(px + 1))
let width px = let #(~bid, ~ask) = bid_ask px in ask - bid

type level = #{ price : int; qty : int }
let[@zero_alloc] add_level (a : level) (b : level) =
  #{ price = a.#price; qty = a.#qty + b.#qty }

type px_qty = { px : int; q : int }
let unbox_it (r : px_qty) : px_qty# = #{ px = r.px; q = r.q }
```

## Measured

Mid and microprice from four ints, `[@inline never]`:

| Return | Words per call | Time (dev / release) |
| --- | ---: | ---: |
| `int * int` | 3 | 3.75 / 3.36 ns |
| `#(int * int)` | 0 | 3.37 / 3.08 ns |

## Pitfalls

- Unboxed record fields cannot be `mutable` (`Unboxed record labels cannot be mutable`);
  put the unboxed record inside a boxed mutable record field instead.
- An unboxed tuple cannot be stored in a list, option or other `value` container.
- On OxCaml, `List.split_n` already returns an unboxed tuple; code written for upstream
  OCaml that destructures it as a boxed pair fails (GOTCHAS.md).
- A third-party zero-allocation HTTP parser uses `#{ off : int16#; len : int16# }` spans
  and `#(span * int16#)` returns throughout; it reports 0 heap words per request.

## Sources

- <https://oxcaml.org/documentation/unboxed-types/intro/>
- <https://anil.recoil.org/notes/oxcaml-httpz> (third-party, measured with core_bench).
