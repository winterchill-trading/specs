# What the interns have wrought, 2021 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2021/>
- Published: 2021-08-09
- Kind: blog post

## Summary

- The 2021 cohort had 87 dev interns across New York, London and Hong Kong; the post covers
  three projects and lists others (an Intel processor trace visualizer, graph-node fusion and
  distributed sort in a graph-computation system, a meta-PPX, trading-limit abstractions).
- `ppx_typed_fields`: derives a GADT of first-class record fields with typed `get`, `set` and
  `name`, which makes generic code such as per-field validators with good error messages
  easy. An intern added support for parameterized records, nested-record field paths and a
  sibling extension for variants.
- Historical atop: atop snapshots from every production host are logged every ten seconds
  and kept 30 days; an intern built CLI and web tools to pull per-process time series across
  days into a spreadsheet, with simple regex and expert boolean filters and incremental
  downloads.
- Datafetcher: a desk-built, Haxl-like embedded language for data-loading jobs whose leaves
  are fetches. It runs in production, test (read stored data) and record (run for real and
  save the data) modes, and batches and caches fetches.
- An intern added memoization of intermediate computations, not only leaf fetches, by
  minting identifiers for subcomputations, then wrote a style guide for its users.

## Relevance to us

- **Testing and simulation:** Datafetcher's record and replay modes make data-dependent code
  cheap to test against real inputs; our client tests run only against simulators, not
  against captured real venue responses. **Action:** add a record mode to the
  [venue-net](../../../repos/venue-net.md) HTTP layer that saves request/response pairs to a
  fixture file, and one ppx_expect test in [hl-client](../../../repos/hl-client.md) that
  decodes a recorded real Hyperliquid `info` response from it.
- **Testing and simulation:** the same applies to websocket feeds, where we already keep
  every raw frame. **Action:** add an expect test in
  [binance-client](../../../repos/binance-client.md) that feeds one recorded
  `market-recorder` raw minute file through the `Live_feed` parser and prints event counts
  per stream.
- **OCaml practice:** `ppx_typed_fields` gives first-class record fields, which make generic
  per-field validation with good error messages easy. **Action:** none; our
  [market-maker](../../../repos/market-maker.md) config validation is small enough to write
  by hand.
- **Build and deploy:** per-process host metrics kept for 30 days answered questions the
  live view could not. **Action:** none; Prometheus scraping in the
  [roadmap](../../../roadmap.md) AWS setup would cover this.

Tags: `testing`, `ppx`, `observability`, `culture`
