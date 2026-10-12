# OxCaml performance

Kind: reference.

Technique notes on writing fast OxCaml the way its authors do, checked on our own
`5.2.0+ox` switch, and an [audit](audit.md) of the organization's hot paths against them.
The [performance theme](../themes/performance.md) covers measurement, GC and latency
practice from the blog and podcast; this directory covers the language and compiler
features, and does not repeat that theme.

## How the notes were checked

- Every snippet marked "verified" compiled in a scratch dune project with
  `opam exec --switch 5.2.0+ox -- dune build`, dev profile, no extension flags. Snippets
  that must fail were compiled with `ocamlfind ocamlopt -c` and the error text recorded.
  The examples now live in the `oxcaml-performance` skill of
  [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md), where CI builds them.
- Numbers come from one arm64 macOS laptop: `core_bench` with `-quota 1`, and exact words
  per call from a `Gc.minor_words` loop over 10,000 calls. Each case was built three ways:
  dev, `--profile release`, and release with `OCAMLPARAM='_,O3=1'`.
- Claims taken from documentation and not reproduced here are marked "unverified".

## The switch

`ocamlopt -config` on `5.2.0+ox`: `flambda2: true`, `stack_allocation: true`,
`runtime5: true`, `probes: false`, `with_frame_pointers: false`, architecture `arm64`
locally (CI and deployment are amd64). The default extension universe enables layouts,
modes, uniqueness, small numbers, labeled tuples, `let mutable` and immutable arrays, so no
`-extension` flag is needed for anything below. Installed: `stdlib_stable`,
`stdlib_upstream_compatible`, `unboxed` (`Float_u`, `Int64_u`, ...), `ocaml_intrinsics`,
`core_bench`, `capsule`, `portable`. Not installed: `ocaml_simd*`, `parallel`, a
`Multicore` library, `ocaml-probes`. No org repository sets `ocamlopt_flags`; `-O3` has
been used only through `OCAMLPARAM`.

## Notes

| Note | One line | Verdict for us |
| --- | --- | --- |
| [Measuring](measuring.md) | `core_bench` plus words-per-call loops, three builds | Do first, always |
| [Flambda 2 and -O3](flambda2-and-o3.md) | `-O3` inlines across functors; little else | Release builds of order-book, engine |
| [Inlining attributes](inlining-attributes.md) | `[@inline]`, `[@unrolled n]`, `[@@loop]` | Cold paths `[@inline never]` |
| [Stack allocation](stack-allocation.md) | `local`, `stack_`, `exclave_` | Order-book, engine contexts |
| [zero_alloc checker](zero-alloc-checker.md) | Compile-time proof of no allocation | Scanners, fixed-decimal |
| [Unboxed numbers](unboxed-numbers.md) | `float#`, `int64#` in registers and fields | mm-core float state |
| [Unboxed products](unboxed-products.md) | `#(a, b)`, `#{ ... }`, `t#` | Multi-result helpers |
| [Mixed blocks](mixed-blocks.md) | Records with flat `float#` fields | mm-core `Market_state` |
| [or_null](or-null.md) | Option without a box | `best_bid`, table lookups |
| [let mutable](let-mutable.md) | Unboxed local variables | Loops, scanners |
| [Immediate types](immediate-and-mode-crossing.md) | `type t : immediate`, mode crossing | Price, size, ids |
| [Labeled tuples](labeled-tuples.md) | `~min:a, ~max:b` | Readability only |
| [Small numbers and iarray](small-numbers-and-iarray.md) | `int8#`, `int16#`, `float32#`, `iarray` | Rare |
| [Templates](templates.md) | One source, local and global copies | Library helpers |
| [Uniqueness](uniqueness.md) | `@ unique` in-place APIs | API discipline only |
| [Parallelism](parallelism.md) | `portable`, `contended` | Day close; gated |
| [SIMD and intrinsics](simd-and-intrinsics.md) | Vectors, clz, popcount, prefetch | SIMD gated |
| [Zero-copy parsing](zero-copy-parsing.md) | Hand scanners, Bigstring, Iobuf | Normalizers, biggest win |
| [Probes](probes.md) | `[%probe]` static tracing | Gated |

## Results at a glance

Words per call are identical in dev, release and release `-O3` for every case; times are
dev. Details and pitfalls in each note.

| Case | Before | After |
| --- | --- | --- |
| Binance trade frame: Yojson tree to hand scanner | 298 words, 2417 ns | 0 words, 261 ns |
| `best_bid`: `option` to `or_null` or local option | 2 words, 3.9 ns | 0 words, 3.6 ns |
| two results: tuple to unboxed tuple | 3 words, 3.8 ns | 0 words, 3.4 ns |
| float state update: boxed copy to mutable `float#` | 8 words, 5.9 ns | 0 words, 4.4 ns |
| sum 1000 floats: recursion to `let mutable` | 2000 words, 776 ns | 2 words, 675 ns |

Two lessons carry over to every note. Removing allocation barely moves a microbenchmark
on a hot minor heap; it shows up as fewer minor collections, less promotion and shorter
tails under load, so pin words per call rather than nanoseconds. And the largest win
available (an order of magnitude on the normalizers) is not a language feature but not
building the intermediate structure at all.

## Where it applies

[audit.md](audit.md) lists the org's hot paths with file and line, the technique that
applies, and an estimated win and risk. The ordered actions are in
[roadmap.md](../../roadmap.md#performance-from-oxcaml-research).

## Sources

- OxCaml documentation index: <https://oxcaml.org/documentation/>
- <https://blog.janestreet.com/introducing-oxcaml/>
- Oxidizing OCaml series: <https://blog.janestreet.com/oxidizing-ocaml-locality/>,
  <https://blog.janestreet.com/oxidizing-ocaml-ownership/>,
  <https://blog.janestreet.com/oxidizing-ocaml-parallelism/>
- <https://blog.janestreet.com/icfp-2024-index/>
- Tech talks: <https://www.janestreet.com/tech-talks/making-ocaml-safe-for-performance-engineering/>,
  <https://www.janestreet.com/tech-talks/unboxed-types-for-ocaml/>
- Flambda 2 series: <https://ocamlpro.com/blog/2024_03_18_the_flambda2_snippets_0/>
