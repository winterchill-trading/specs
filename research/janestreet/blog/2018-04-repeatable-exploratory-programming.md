# Repeatable exploratory programming

- Source: <https://blog.janestreet.com/repeatable-exploratory-programming/>
- Published: 2018-04-22
- Kind: blog post

## Summary

- Expect tests had been hard to try outside Jane Street; dune (then invoked as jbuilder)
  now supports them, so the author shows them used for exploratory programming.
- Setup: a library stanza with `inline_tests` and the ppx_jane preprocessor; a
  `let%expect_test` that prints, run with auto-promote, gets its output written back into
  the source under `[%expect]`.
- Example task: find internal links on a website using the lambdasoup HTML library, with
  `expect_test_helpers_kernel` and `print_s` over `[%sexp]` for readable output.
- Probing an edge case (an anchor without `href`) shows the raised exception in the
  captured output; switching the selector to `a[href]` fixes it, and the diff shows that.
- Real data enters by saving a downloaded page beside the test and declaring it as a
  dependency of the inline tests in the build file.
- Filtering by host with the uri library yields only internal links.
- The result is lightweight and repeatable: the exploration is committed, others can extend
  it, and it stays as a regression test during later refactors.

## Relevance to us

- **Testing and simulation:** expect tests over checked-in real captures catch venue quirks
  that hand-written JSON samples miss, and none of our test stanzas declare a captured data
  file. **Action:** check a few dozen real Hyperliquid websocket lines (one raw minute
  file excerpt) into `hl-client` tests as an `inline_tests` dependency and add an expect
  test that decodes every line and prints per-channel counts and any parse failures.
- **Research tooling:** the same pattern turns one-off data checks into committed,
  rerunnable notebooks. **Action:** add an expect test in
  [market-data](../../../repos/market-data.md) that runs the minute-to-candle aggregation
  over a small real recorded event log fixture and prints the resulting candles.
- Context: we already use ppx_expect everywhere, including
  [hl-protocol](../../../repos/hl-protocol.md) codec tests; the gap is real data, not tooling.

Tags: `expect-tests`, `testing`, `market-data`, `research-tooling`
