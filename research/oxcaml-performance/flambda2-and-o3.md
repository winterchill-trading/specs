# Flambda 2 and -O3

Kind: reference.

## What it is

The `5.2.0+ox` compiler is built with Flambda 2 (`ocamlopt -config` reports
`flambda2: true`, `flambda: false`). Flambda 2 inlines, specialises and unboxes across
modules and libraries; `-O3` raises its inlining budget and enables unrolling. `-Oclassic`
makes inlining decisions at definition time, like the old compiler.

## When it pays

When the hot path crosses a functor or a library boundary that hides a cheap operation.
The org's measured case is order-book: comparisons on `Price.t` come from
`Comparable.Make` in fixed-decimal, and only `-O3` inlines them into the matching loop.
It does not pay for code that is already allocation-free and local: the benches in this
directory moved by under 10% between dev, release and `-O3`.

## Syntax on 5.2.0+ox (verified)

- Per build: `OCAMLPARAM='_,O3=1' dune build --profile release`. It applies to everything
  compiled from source in that build, not to opam libraries (Core, Base, Yojson keep the
  flags they were installed with).
- Per library: `(ocamlopt_flags (:standard -O3))` in a `library` stanza compiles in all
  profiles on this switch.
- `dune build --release` implies `--root .` and cannot be combined with `--root`; use
  `--profile release`.
- No repository sets `ocamlopt_flags` today; the root `dune-workspace` has no profiles.

## Measured

| Case (this directory's bench) | dev | release | release `-O3` |
| --- | ---: | ---: | ---: |
| `best_bid` returning `option` | 3.91 ns | 3.90 ns | 3.63 ns |
| two results, boxed tuple | 3.75 ns | 3.36 ns | 3.37 ns |
| state record copy, boxed floats | 5.87 ns | 5.28 ns | 5.41 ns |
| trade frame through Yojson | 2417 ns | 2419 ns | 2406 ns |
| trade frame, hand scanner | 261 ns | 261 ns | 262 ns |

Words per call were identical in all three builds for every case. From the order-book
bench ([repos/order-book.md](../../repos/order-book.md)): match one fill 74 ns (dev),
66 ns (release), 37 ns (release `-O3`), 27 to 22 words.

## Pitfalls

- `-O3` does not unbox a `float` accumulator in a self-tail-recursive function on this
  switch, even with `[@@loop]`: summing 1000 floats allocates 2000 words in every build.
  Use `let mutable` or a `float#` accumulator; see [inlining attributes](inlining-attributes.md).
- Because opam libraries keep their own flags, `-O3` cannot inline into Core or Yojson
  internals; a Yojson-bound path gains nothing.
- Inlining decides whether an allocation disappears, so a compiler upgrade or a refactor
  that moves code across a module can bring allocations back. Pin words per call in expect
  tests ([measuring](measuring.md)).
- `[@zero_alloc]` checks run after Flambda 2, so a function can pass at `-O3` and fail in
  dev; prefer annotations that pass in dev ([zero-alloc checker](zero-alloc-checker.md)).

## Sources

- <https://blog.janestreet.com/introducing-oxcaml/> (Flambda 2 as the OxCaml middle end).
- <https://ocamlpro.com/blog/2024_03_18_the_flambda2_snippets_0/> (series index).
- <https://blog.janestreet.com/flambda/>; our note
  [2016-02 Flambda](../janestreet/blog/2016-02-flambda.md).
- Signals and Threads, compiler optimization:
  [episode 4 note](../janestreet/podcast/04-compiler-optimization.md).
