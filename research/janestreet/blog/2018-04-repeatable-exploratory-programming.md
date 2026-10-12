# Repeatable exploratory programming

- Source: <https://blog.janestreet.com/repeatable-exploratory-programming/>
- Published: 2018-04-22
- Kind: blog post

## Summary

- With expect test support now in dune (then still invoked as jbuilder), the author shows
  using `let%expect_test` as a REPL-like loop for exploratory programming.
- Workflow: write code that prints, run the tests with auto-promote, and the captured
  output is written back into the source file under `[%expect]`.
- Worked example: extracting links from HTML with lambdasoup. A test case with an anchor
  lacking `href` exposed an exception in the captured output, fixed by changing the CSS
  selector.
- Real data enters the loop by saving a fetched page next to the test and declaring it as
  a dependency of `inline_tests` in the build file.
- Filtering to internal links with the uri library completes the task; the experiments
  remain in the repository as regression tests for later refactors.

## Relevance to us

- We use ppx_expect everywhere, but our protocol and client tests use inline sample JSON;
  none of the test stanzas in [hl-protocol](../../../repos/hl-protocol.md) or
  [market-data](../../../repos/market-data.md) declare a captured data file as a dependency.
- Real recorded frames from [market-recorder](../../../repos/market-recorder.md) would
  catch venue quirks that hand-written samples miss.
- **Action:** check a small captured raw minute file (a few dozen real Hyperliquid
  websocket lines) into `hl-client` tests as an `inline_tests` dependency and add an expect
  test that decodes every line and prints a per-channel count plus any parse failures.

Tags: `expect-tests`, `testing`, `market-data`
