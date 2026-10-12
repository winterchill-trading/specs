# SIMD and CPU intrinsics

Kind: reference.

## What it is

- SIMD: 128-bit and 256-bit vector types (`int8x16#`, `float64x2#`, `int32x8#`, ...) and
  intrinsics libraries `ocaml_simd`, `ocaml_simd_sse`, `ocaml_simd_avx`, with `ppx_simd`
  for shuffle and blend masks. Vectors load from strings, bytes, bigstrings and unboxed
  arrays.
- `ocaml_intrinsics`: single instructions exposed as functions: count leading or trailing
  zeros, population count, prefetch, the timestamp counter, native pointers, CRC, fences.

## When it pays

SIMD: byte scanning (finding `"` or `\n` in a frame, validating ASCII digits) and column
kernels in the Parquet writer (min/max, bit packing). Intrinsics: bit tricks in encoders
(bit widths for RLE/bit packing), cheap timestamps for latency histograms, prefetching
the next price level.

## Syntax on 5.2.0+ox (verified)

```ocaml
let clz x = Ocaml_intrinsics.Int.count_leading_zeros x          (* clz 1 = 62 *)
let pop x = Ocaml_intrinsics.Int.count_set_bits x               (* pop 255 = 8 *)
let cycles () = Ocaml_intrinsics.Perfmon.rdtsc ()                (* int64 *)
let prefetch_arr (a : int array) =
  Ocaml_intrinsics.Prefetch.value a ~operation:Read ~temporal_locality:High
```

Library `ocaml_intrinsics` (installed). The vector type `int64x2#` itself type-checks with
no flag, but no SIMD intrinsics library is installed.

## Measured

Not benchmarked. `rdtsc` returns a counter on arm64 macOS too (consecutive reads differed
by about 40 ticks).

## Pitfalls

- SIMD is gated for us: `ocaml_simd*` is not installed on the switch, the oxcaml.org page
  covers amd64 up to AVX2 only and lists NEON as future work, and development machines
  are arm64 while CI and deployment are amd64. Code using it would need a scalar fallback
  selected at build time.
- `Perfmon.rdpmc` returns 0 on non-amd64 targets; `rdtsc` returns a boxed `int64` unless
  inlined.
- Prefetching helps only for a known next address that is not already in cache; measure.

## Sources

- <https://oxcaml.org/documentation/simd/intro/>
- <https://www.tunbury.org/2026/03/13/oxcaml-inference/> (third-party SIMD use with
  `[@zero_alloc]`).
- `ocaml_intrinsics` interfaces on the switch (`perfmon.mli`, `prefetch.mli`).
