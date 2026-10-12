# What if writing tests was a joyful experience?

- Source: <https://blog.janestreet.com/the-joy-of-expect-tests/>
- Published: 2023-01-09
- Kind: blog post

## Summary

- Expect tests (snapshot tests elsewhere, inspired by Mercurial's test format and cram) let
  you print a value under an empty `[%expect]` block; the build produces a diff with the
  actual output, which the editor accepts in place, so writing a test feels like a REPL.
- Printing a small table of inputs and outputs while iterating on a function doubles as
  documentation and as a regression guard: "regressions are just diffs".
- Against assertion-style tests the argument is that choosing and typing each assertion
  discourages testing and checks less; dumping state asserts everything implicitly, for
  example catching an order size silently changing from 1 to 100.
- The craft is in concise output: helpers and custom printers that tell a story and elide
  noise, so diffs stay meaningful; tests live in their own directory against the public
  interface or a `For_testing` module.
- Examples: Bonsai UI tests that drive inputs and show DOM diffs, magic-trace's demangler and
  trace output, a market data processor printing an order book after each event, and
  Hardcaml's ASCII waveforms.
- Expect tests now form most of Jane Street's suite, with property tests as a complement and
  classic assertions a small remainder; sexp printers from `ppx_sexp_conv` make it cheap.

## Relevance to us

- Our repositories already follow this style: [order-book](../../../repos/order-book.md)
  tests print L2 after each step, and [mm-core](../../../repos/mm-core.md) reconciler and
  risk tests are all expect tests.
- The missing piece is an end-to-end snapshot over real recorded data: raw frames from
  [market-recorder](../../../repos/market-recorder.md) are never pushed through a client's
  normalizer and local book in a test.
- **Action:** in [binance-client](../../../repos/binance-client.md), check in a short raw
  minute-file fixture of depth frames and add an expect test that feeds it through
  `Feed_normalizer` and `Local_book`, printing the top three levels per side at the end.

Tags: `expect-tests`, `testing`, `market-data`, `replay`
