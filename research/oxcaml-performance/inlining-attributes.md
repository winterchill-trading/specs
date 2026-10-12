# Inlining and loop attributes

Kind: reference.

## What it is

Attributes that steer Flambda 2 per function or per call: `[@inline]` and
`[@inline never]` on definitions, `[@inlined]` on call sites, `[@specialise]` for
higher-order functions, `[@unrolled n]` on a recursive call site, and `[@@loop]` asking
for a self-tail-recursive function to be compiled as a loop.

## When it pays

- `[@inline]` on a small accessor or arithmetic helper used through a functor or across
  libraries, where inlining exposes an allocation to removal (an option built and
  immediately matched, a closure passed to a fold).
- `[@inline never]` on cold paths (error formatting, logging) so the hot function stays
  small enough to be inlined itself.
- `[@specialise]` on a higher-order helper called with a known closure in a hot loop.

## Syntax on 5.2.0+ox (verified)

```ocaml
let[@inline] sq x = x * x
let[@inline never] cold_path x = failwithf "bad %d" x ()
let use_sq x = (sq [@inlined]) x + if x < 0 then cold_path x else 0
let[@specialise] apply_twice f x = f (f x)

let rec pow2 n = if n = 0 then 1 else 2 * pow2 (n - 1)
let pow2_unrolled n = (pow2 [@unrolled 3]) n        (* call-site attribute *)

let rec count_down n acc = if n = 0 then acc else count_down (n - 1) (acc + n)
[@@loop]
```

All compile in the dev profile without extension flags.

## Measured

Summing a 1000-element `float array` (words per call, every build including `-O3`):

| Form | Words | Time |
| --- | ---: | ---: |
| self-tail-recursive `go i acc` with `float` accumulator | 2000 | 773 ns |
| same with `[@@loop]` | 2000 | (not timed) |
| `for` loop with `let mutable acc = 0.` | 2 | 675 ns |
| recursive `go` with a `float#` accumulator | 2 | (not timed) |

The 2 remaining words are the boxed `float` result of a non-inlined function.

## Pitfalls

- `[@unrolled n]` on a definition (`... [@@unrolled 3]`) is rejected with warning 53
  (misplaced attribute), which the dev profile turns into an error. It belongs on the call.
- Loopification does not unbox a `float` loop variable here, contrary to what the
  Flambda 2 loopify article leads one to expect (unverified whether a flag enables it).
  Use `let mutable` or unboxed numbers in float loops.
- Attributes are hints; check the effect with a words-per-call test, not by reading the
  source.

## Sources

- OCaml manual, Flambda chapter (attribute semantics inherited by Flambda 2):
  <https://ocaml.org/manual/5.4/flambda.html>.
- Flambda 2 loopify: <https://ocamlpro.com/blog/2024_05_07_the_flambda2_snippets_2/>.
- Flambda 2 speculative inlining:
  <https://discuss.ocaml.org/t/blog-flambda2-ep-3-speculative-inlining-by-ocamlpro/15250>.
