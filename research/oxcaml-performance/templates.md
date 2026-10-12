# Mode and kind templates (ppx_template)

Kind: reference.

## What it is

`ppx_template` (part of `ppx_jane` on this switch) generates several copies of a
definition, one per mode or kind, from one source. It is how Base ships both a heap and a
local version of the same function without writing it twice.

## When it pays

When a hot-path helper is needed both for local callers (stack-allocated result) and for
callers that store the result: write it once with `[@mode m = (global, local)]` and call
`f [@mode local]` from the hot path.

## Syntax on 5.2.0+ox (verified)

```ocaml
type pair = { a : int; b : int }

let%template[@mode m = (global, local)] swap (p : pair @ m) : pair @ m =
  { a = p.b; b = p.a } [@exclave_if_local m]

let use_local x =
  let p = stack_ { a = x; b = 1 } in
  let q = (swap [@mode local]) p in
  q.a

let use_global x = (swap { a = x; b = 2 }).a
```

`[@exclave_if_local m]` inserts `exclave_` only in the local copy. Instantiation outside a
`%template` block compiled here, although the oxcaml.org page says it must be inside one.

## Measured

Not benchmarked; each copy behaves like the hand-written version
([stack allocation](stack-allocation.md)).

## Pitfalls

- `(swap [@mode local]) p |> fun q -> q.a` fails: the local argument reaches a call in
  tail position. Bind with `let` first or add `[@nontail]`.
- `[@kind k = (value, float64)]` templates over layouts were not exercised here
  (unverified).

## Sources

- <https://oxcaml.org/documentation/templates/intro/>
- <https://oxcaml.org/documentation/templates/reference/>
