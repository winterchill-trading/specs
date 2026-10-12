# Uniqueness for in-place updates

Kind: reference.

## What it is

A value at mode `unique` has no other live reference. A function taking `@ unique` may
consume it and return it, which lets an API expose an immutable-looking interface over a
value updated in place, and `borrow_` lends it for a read. The
[oxcaml-modes skill](https://github.com/winterchill-trading/oxcaml-claude-skills/tree/main/skills/oxcaml-modes)
has the verified syntax and every error text; this note does not repeat it.

## When it pays

Today, as an API discipline: a book or buffer handle that must not be aliased while it is
being mutated. The compiler does not yet reuse the memory of a consumed immutable value
("overwriting" is planned), so `@ unique` on an immutable record does not by itself save
the allocation of `{ t with ... }`.

## Syntax on 5.2.0+ox (verified in the skill)

```ocaml
val incr : counter @ unique -> counter @ unique
let peek_then_incr (c @ unique) = let seen = get (borrow_ c) in seen, incr c
```

## Measured

No allocation effect expected until overwriting lands; not benchmarked.

## Pitfalls

- See the skill; the commonest is using a unique value after passing it to an `@ local`
  parameter instead of borrowing it.
- The `overwriting` extension is listed by `ocamlopt -help` but was not tried
  (unverified).

## Sources

- <https://oxcaml.org/documentation/uniqueness/intro/>
- <https://oxcaml.org/documentation/modes/intro/> ("overwriting ... planned").
- <https://blog.janestreet.com/oxidizing-ocaml-ownership/>; our note
  [2023-06 ownership](../janestreet/blog/2023-06-oxidizing-ocaml-ownership.md).
