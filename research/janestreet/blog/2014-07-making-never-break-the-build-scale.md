# Making “never break the build” scale

- Source: <https://blog.janestreet.com/making-never-break-the-build-scale/>
- Published: 2014-07-06
- Kind: blog post

## Summary

- Discusses the "not rocket science rule": the main branch only advances to states that
  have built and passed tests, checked before integration rather than after.
- The naive scheme serializes merges, so n requests of m minutes each take n times m; with
  full builds over two hours, changes sometimes waited a day.
- Mitigations tried: testing requests in parallel when rejection rates are high, batching
  several requests into one speculative merge, a faster build system (Jenga) with reliable
  incremental builds, and fewer, larger integration requests.
- Moving code review before integration cut requests from hundreds a week to about 30 or
  40, because finished features land as one unit.
- These change constants, not asymptotics; a tree of release processes (hierarchical
  features in Iron) batches work so the central gate sees fewer requests.

## Relevance to us

- **Build and deploy:** With about 20 repositories pinned from GitHub, each repo can be green alone
  while a downstream repo breaks after an upstream push. **Action:** add a nightly scheduled
  workflow in [market-maker](../../../repos/market-maker.md) that pins every upstream repository at
  its current `main` and runs the build and tests.
- **Build and deploy:** A gate is only as good as what it pins; the [roadmap](../../../roadmap.md)
  lists missing `parquet` and `market-data` pins. **Action:** add `parquet` and `market-data` to the
  CI pin order of [hl-mm](../../../repos/hl-mm.md) and
  [market-maker](../../../repos/market-maker.md).

Tags: `build`, `testing`, `culture`
