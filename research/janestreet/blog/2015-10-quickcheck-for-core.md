# Quickcheck for Core

- Source: <https://blog.janestreet.com/quickcheck-for-core/>
- Published: 2015-10-26
- Kind: blog post

## Summary

- Announces a Quickcheck-style property testing library shipped in Core 113.00, integrated
  with sexp rendering of counterexamples and with Async for asynchronous tests.
- Motivation from the author's earlier research: writing random tests is easy, but writing
  distributions that actually reach interesting inputs is hard, so the library focuses on
  tools for shaping distributions.
- `Quickcheck.test` takes a generator and a function that raises on failure; an optional
  `sexp_of` prints the first failing input.
- Generators form a monad: binding a length generator into a list generator lets a test
  target list lengths around an implementation's chunking threshold (about 5000 elements in
  `List.append`).
- Combinators include `weighted_union`, `union`, `of_list`, `singleton`, lazy `of_fun`
  (deliberately not memoized to avoid space leaks) and `recursive` for tree-shaped types.
- `int_between` biases toward range boundaries, which is where off-by-one bugs live.
- Observers mirror generators so the library can produce random functions, modelled as
  random decision trees over the input.
- Planned direction: move default generators next to their types (`Int.gen`), which is
  what later became Base_quickcheck and `[@@deriving quickcheck]`.
- A generator is a probability distribution plus some metadata, the counterpart of Haskell's
  `Arbitrary`; the library also tries not to repeat values and can build sets or sorted lists that
  keep uniqueness.
- The author calls the design early and asks for feedback on how default distributions should be
  calibrated.

## Relevance to us

- **Testing and simulation:** Generators biased toward range boundaries find the overflow and
  rounding bugs that example tests miss. **Action:** add a Base_quickcheck test to
  [fixed-decimal](../../../repos/fixed-decimal.md) with a generator weighted toward the ends of the
  63-bit unit range, checking `of_string (to_string x) = x` and that `Product.mul` matches a widened
  reference whenever the result fits.
- **Testing and simulation:** Distributions should be shaped around the thresholds where an
  implementation changes behaviour, not left uniform. **Action:** add a generator in the
  [order-book](../../../repos/order-book.md) Quickcheck test that draws prices from at most three
  ticks around a mid, so most orders cross or queue at a shared level, and run the invariant check
  after every operation.
- **Testing and simulation:** Default generators belong next to their types so every type is cheap
  to test. **Action:** derive `quickcheck` on the `Stable.V1` records in
  [market-data](../../../repos/market-data.md) and add a property test that every generated event
  survives a bin_io round trip.

Tags: `property-testing`, `testing`, `ocaml-practice`
