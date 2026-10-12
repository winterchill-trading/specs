# Stack allocation: `local`, `stack_` and `exclave_`

Kind: reference.

## What it is

A value at mode `local` may live on a separate stack instead of the minor heap; it is
freed when its region (function body, loop body) ends and never triggers a GC. `stack_`
forces stack allocation of one allocation site or fails to compile; `exclave_` ends the
current region early so a function can return a local value into its caller's region.
The [oxcaml-modes skill](https://github.com/winterchill-trading/oxcaml-claude-skills/tree/main/skills/oxcaml-modes)
covers the mode rules and error texts; this note covers when it pays.

## When it pays

Short-lived values on a per-message or per-order path: an option or small record returned
and immediately matched, a context record passed down a recursive sweep, a closure passed
to an iterator. It does not pay for values that end up stored in a heap structure (a fill
list, a table): those must be `global` anyway.

## Syntax on 5.2.0+ox (verified)

```ocaml
let best_local (a : int array) : int option @ local =
  if Array.length a = 0 then exclave_ None else exclave_ Some a.(0)

let spread bid ask =
  let q = stack_ { bid; ask } in
  q.ask - q.bid
```

No extension flag is needed.

## Measured

`best_bid`-style lookup, `[@inline never]`, words per call (all builds):

| Return type | Words | Time (dev) |
| --- | ---: | ---: |
| `int option` | 2 | 3.91 ns |
| `int option @ local` with `exclave_` | 0 | 3.96 ns |
| `int or_null` ([or_null](or-null.md)) | 0 | 3.59 ns |

The time barely moves in a microbenchmark because the minor heap is hot; the gain is
fewer minor collections and less promotion under load.

## Pitfalls

- `stack_` on a value that escapes fails with `This value is "local" because it is
  "stack_"-allocated`; `local` alone silently falls back to heap allocation where the
  compiler cannot prove it safe, so use `stack_` when the point is a guarantee.
- A local value passed to a call in tail position needs `[@nontail]` or a `let` binding.
- A `local` option of an abstract non-immediate type is useless to callers that need to
  store the payload; `or_null` is simpler for `value` payloads.
- Mutable fields and arrays hold only global values; `ppx_globalize` copies a local value
  to the heap when one must escape.

## Sources

- <https://oxcaml.org/documentation/stack-allocation/intro/>
- <https://oxcaml.org/documentation/stack-allocation/reference/>
- <https://oxcaml.org/documentation/stack-allocation/pitfalls/>
- <https://blog.janestreet.com/oxidizing-ocaml-locality/>; our note
  [2023-05 locality](../janestreet/blog/2023-05-oxidizing-ocaml-locality.md).
