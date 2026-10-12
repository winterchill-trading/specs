# fixed-decimal

Fixed-point decimal numbers for trading systems. A value is an `int` counting 10^-8
units, so arithmetic is exact and allocation-free.

| | |
| --- | --- |
| Repository | `winterchill-trading/fixed-decimal` |
| opam package | `fixed-decimal` |
| Library | `fixed-decimal` (module `Fixed_decimal`) |
| Binaries | none |
| Status | done |

## Key modules

`lib/fixed_decimal.mli` is the only interface:

- `Fixed_decimal.S`: signature of a fixed-point type: `zero`, `one`, `of_int`,
  `of_units`/`to_units`, `of_float`/`to_float`, `of_string`/`to_string`, `+`, `-`,
  `neg`, `abs`, `scale`, `sum`, `mul`, `div`, `div_int`, `round_down`, `round_nearest`,
  `Comparable`, sexp and yojson (decimal string; JSON numbers accepted on input).
- `Fixed_decimal.Make ()`: a generative functor; every application is a distinct type,
  which is how `Price`, `Size` and `Usd` stay apart at compile time.
- `Fixed_decimal.Product (A) (B) (C)`: mixed products and quotients
  (`Price.t -> Size.t -> Usd.t`) without overflowing intermediates.
- `mul_units`, `div_units`: the raw helpers.

## Dependencies

- Depends on: no org package (core, ppx_jane, ppx_yojson_conv, yojson).
- Used by: `exchange-core`, `exchange-core-engine`, `order-book`, `hl-protocol`,
  `binance-protocol`, `bybit-protocol`, `hl-sim`, `binance-sim`, `bybit-sim`,
  `market-data`, `mm-core`, `hl-mm`, `binance-client`.

## CI pin order

None; `opam install . --deps-only --with-test`.

## Known gaps

- More than 8 fractional digits are truncated toward zero on parse; protocol libraries
  inherit this.
- The range is that of a 63-bit `int` in 10^-8 units, about 4.6 * 10^10. Larger values
  fail to parse: hl-mm logs and skips Hyperliquid clearinghouse snapshots whose
  `liquidationPx` has 11 integer digits.
- `mul`, `div` and `div_int` truncate toward zero; division by zero raises.
