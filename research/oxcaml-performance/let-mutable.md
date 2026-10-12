# `let mutable`

Kind: reference.

## What it is

`let mutable x = e in ... x <- e'` declares a local variable that can be assigned. It
formalizes the optimization that keeps a `ref` that never escapes in a register: the
compiler rejects any use that would require a box.

## When it pays

Loop accumulators and scanner positions. It matters most for `float` accumulators, which
self-tail recursion boxes on every iteration on this switch (see
[inlining attributes](inlining-attributes.md)), and it makes a scanner's state explicit
for `[@zero_alloc]`.

## Syntax on 5.2.0+ox (verified)

```ocaml
let[@zero_alloc] sum (a : int array) =
  let mutable acc = 0 in
  for i = 0 to Array.length a - 1 do acc <- acc + Array.unsafe_get a i done;
  acc
```

## Measured

Summing 1000 floats: recursion with a `float` accumulator 2000 words and 776 ns;
`let mutable acc = 0.` in a `for` loop 2 words (the boxed result) and 675 ns.

## Pitfalls

- A closure cannot capture it: `List.iter l ~f:(fun x -> s <- s + x)` fails with
  `Mutable variable cannot be used inside a function`. Use a `for`/`while` loop.
- It cannot be recursive, top-level, bound with `and`, or bound to a tuple pattern.
- With a plain `ref` that does not escape, Flambda 2 usually produces the same code; the
  gain of `let mutable` is that the compiler guarantees it.

## Sources

- <https://oxcaml.org/documentation/miscellaneous-extensions/let-mutable/>
