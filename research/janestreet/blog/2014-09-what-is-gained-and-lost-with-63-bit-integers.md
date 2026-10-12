# What is gained and lost with 63-bit integers?

- Source: <https://blog.janestreet.com/what-is-gained-and-lost-with-63-bit-integers/>
- Published: 2014-09-29
- Kind: blog post

## Summary

- OCaml stores an `int` as `(x << 1) | 1`, so the low tag bit separates immediates from
  word-aligned pointers.
- Benefits: no allocation, no header, no dereference, less GC work and fragmentation, and
  generic traversals (hash, compare, GC) only test one bit; `int32`/`int64` stay boxed.
- Cost: arithmetic must fix up the tag bit, for example addition becomes `x + y - 1` and
  multiplication needs a shift and decrement, though chains of additions need only one fix.
- A Sandy Bridge microbenchmark showed tagged arithmetic roughly 2 to 4 times slower than
  untagged 64-bit operations, worse for dependent chains; `LEA` helps but is slow on newer
  cores.
- Ends with an open question about keeping unboxed ints with untagged arithmetic speed.

## Relevance to us

- **OCaml practice:** Tagged ints cost one bit of range, so 10^-8 units top out near 4.6 * 10^10 and
  the limit should be visible in code. **Action:** add an expect test in
  [fixed-decimal](../../../repos/fixed-decimal.md) that pins the largest representable value
  (`46116860184.27387903`) and shows that `of_string` rejects the next unit up.
- **Market making and trading systems:** The range limit currently makes one oversized field discard
  a whole Hyperliquid clearinghouse snapshot. **Action:** decode `liquidationPx` in
  [hl-protocol](../../../repos/hl-protocol.md) as an option that becomes `None` when it does not
  fit, so [hl-mm](../../../repos/hl-mm.md) keeps the rest of the snapshot.
- **Performance:** Tag fix-ups make tagged multiplication several times slower than untagged, which
  matters for fixed-point `mul` and `div`. **Action:** add a core_bench executable to
  [fixed-decimal](../../../repos/fixed-decimal.md) timing `mul`, `div` and `Product.mul` against
  plain `Int.( * )`, and confirm zero words allocated per run.

Tags: `performance`, `ocaml-practice`, `trading`
