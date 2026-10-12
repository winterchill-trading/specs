# What the interns have wrought, 2022 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2022/>
- Published: 2022-08-25
- Kind: blog post

## Summary

- The 2022 program had 122 developer interns from 42 schools in 13 countries; each intern
  works in two areas over the summer, and three projects are highlighted.
- magic-trace, which uses Intel Processor Trace to record every branch in roughly the last
  10 ms before an event and shows it in a modified Perfetto viewer, gained a sampling mode
  covering the last 20 seconds or even 20 minutes, which also works on AMD machines.
- Much of that work was choosing good defaults per workload and hardware (sampling rate, LBR
  versus DWARF stack unwinding); the market data team already used it to find a
  per-packet allocation that kept a packet-processing application busy in the GC.
- Other magic-trace additions: multi-process traces to follow data between programs on one
  box, CPU frequency transition reporting (an AVX2 use causing a 14 µs stall), and a perf
  dlfilter backend that sped up decoding by 10-50%.
- Datafetcher, a library for testable data-loading jobs that batches requests and records
  external data for replay in tests, was combined with Incremental so jobs can react to live
  market data instead of rerunning from scratch.
- That needed a state type for in-flight asynchronous results, user-chosen memoization for
  intermediate nodes, mandatory memoization of fetch nodes for consistent results, testing
  support, and automatic conversion of batch jobs into polling incremental ones.
- Quickcheck gained a `[@@contract]` annotation on interface values so properties (such as a
  string round-tripping through a char list) drive generated tests with no per-test
  boilerplate, with annotations to customize argument distributions.
- A bisimulation mode then tests two implementations of the same API against each other by
  generating sequences of operations, which suits optimized data structures that have a
  simple, slow reference version.

## Relevance to us

- **Testing and simulation:** bisimulation against a slow reference is the right test for a
  price-time priority book, and [order-book](../../../repos/order-book.md) has only
  scenario expect tests. **Action:** add a Base_quickcheck test in `order-book` that
  generates sequences of `add_limit`, `cancel` and `market` operations and compares
  `Order_book` fills and `l2` output after each step with a naive list-based reference
  book in the test directory.
- **Testing and simulation:** Datafetcher's record-then-replay of external data is how real
  venue responses should enter our tests; protocol codec tests use hand-written JSON.
  **Action:** check in one recorded real Hyperliquid `/info` `l2Book` response and one
  `clearinghouseState` response as fixtures in [hl-protocol](../../../repos/hl-protocol.md)
  and add expect tests that decode them.
- **Performance:** the market data team's finding (one allocation per packet showing up as GC
  time) is the typical failure of a feed handler. **Action:** add a `Gc.minor_words`
  per-message measurement to the `Live_feed` test in
  [binance-client](../../../repos/binance-client.md) and print it, so a regression shows up
  as an expect diff.

Tags: `property-testing`, `testing`, `performance`, `observability`, `market-data`
