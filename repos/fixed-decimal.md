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
- `mul_units`, `div_units`: the raw helpers, and `mul_units_round_nearest`,
  `div_units_round_nearest`.
- Added for the opam-readiness audit: `of_string_or_error`, `of_string_exact` (an error
  instead of truncating past 8 decimals), `div_or_error`, and `mul_round_nearest`,
  `div_round_nearest` on `S` and `Product` (half away from zero). Audit:
  [research/opam-readiness/fixed-decimal.md](../research/opam-readiness/fixed-decimal.md).

`S.t` is declared `[@@immediate]`, so values are unboxed `int`s and can cross modes.
`of_float` rounds to the nearest unit, raises on NaN, infinities and out-of-range values,
maps `-0.0` to zero and carries a `lossy` alert; wire values go through `of_string`.

- `of_substring_exn s ~pos ~len` and `blit_to_bytes t buf ~pos` parse and print without
  allocation; every arithmetic and comparison function carries `[@@zero_alloc]`, and
  `Fixed_decimal.Reference` keeps the old parser and printer for property tests.

## Tests and performance

Expect tests, a property test of `mul_units`, `div_units` and `Product` against exact
zarith arithmetic, a must-fail compile check (`test/must_fail`) that a `Price.t` is not a
`Size.t`, an expect test pinning zero minor words for `mul`, `div` and `Product`, and
expect tests that keep the README's `ocaml` blocks identical to `test/test_readme.ml`
(mdx is not available for the OxCaml compiler). `bench/bench.exe` (core_bench), Apple
M-series laptop:

| Operation | Time/run |
| --- | ---: |
| `mul` | 5-8 ns |
| `div` | 26-31 ns |
| `Product.mul` | 7 ns |
| `Product.div` | 27 ns |
| empty closure (baseline) | 2.4 ns |

Every row shows the harness's own 3 minor words, the same as the empty closure.

The property test found a real bug: `div_units` overflowed `r * 10` in its long division
when the divisor was above `max_value / 10`, returning wrong quotients (`10^18 / (3 *
10^18)` gave `-98999` units instead of `33333333`). Fixed in commit `016ab09` with a slow
path that adds the remainder ten times modulo the divisor. `of_string` also rejected
in-range values with 11 integer digits; it now accepts any integer part that fits.

## Dependencies

- Depends on: no org package (core, ppx_jane, ppx_yojson_conv, yojson; zarith and
  core_bench for tests and benchmarks).
- Used by: `binance-client`, `binance-protocol`, `binance-sim`, `bybit-protocol`, `bybit-sim`,
  `cboe-sim`, `cme-sim`, `equities-core`, `exchange-core`, `hl-copy-core`, `hl-mm`, `hl-protocol`,
  `hl-sim`, `investing-core`, `market-data`, `mm-core`, `money`, `nyse-sim`, `order-book`,
  `price-anchor`.

## CI pin order

None; `opam install . --deps-only --with-test`.

## Known gaps

- The range is that of a 63-bit `int` in 10^-8 units, about 4.6 * 10^10. Larger values
  fail to parse: hl-mm logs and skips Hyperliquid clearinghouse snapshots whose
  `liquidationPx` is out of range. A wider range needs a second representation; design
  decision.
- The scale is fixed at 8 fractional digits for every instance; a per-instance scale is a
  design change.
- Closed 2026-10-14: digits past the eighth are still truncated by `of_string` (protocol
  libraries inherit this), but `of_string_exact` rejects them; `mul_round_nearest` and
  `div_round_nearest` round instead of truncating; `div_or_error` returns an error on a
  zero divisor.
