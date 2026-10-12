# Building Tools for Traders

- Source: <https://signalsandthreads.com/building-tools-for-traders/>
- Published: 2025-05-28
- Kind: Signals and Threads episode 23

## Summary

- The guest came from consumer software (Trello's iOS and web front end, then iOS at
  another retailer) and was drawn to Jane Street by functional programming: functional
  reactive UI libraries on iOS, live music coding in Clojure, then Haskell.
- First role was the firm's single-dealer platform. It looks like an exchange (order
  book, matching engine, trades printed to a public tape, exchange-style protocols over
  UDP multicast) but clients trade only against Jane Street.
- On that platform latency was measured in microseconds, and a millisecond was
  shorthand for disaster. The code is imperative, made safe with phantom type parameters
  on GADTs so serialization stays efficient; tests and tooling around the hot loop are
  written in a high-level style in the same language and types, with no FFI boundary.
- Now on the options desk's trader-tools team. Options multiply symbols (hundreds of
  strikes and expiries per underlying), and traders think in a low-dimensional
  volatility surface but must act through individual order books.
- Two classes of tool: exploration (intraday charts, views across all options of an
  underlying and expiry) and attention management (alerts on opportunities, routing
  each to the right trader, which is unglamorous but very important).
- Rich UIs on the desk are only a few years old; a bespoke curses app was long the main
  interface and still exists.
- Internal users sit an aisle away, give immediate feedback and patiently explain the
  domain. Senior traders with UX sense help with design, and engineers must learn enough
  options theory to build features while specialist teams own pricing and implied vol.
- Expert UI norms: very high information density, everything on the keyboard, little
  investment in discoverability or tutorials; tooltips and wiki links appear as more
  people use the tools.
- Internal software skips accounts, login, payments and CDNs, so new apps are cheap
  to start, and the firm avoids the churn of npm dependency upgrades by vetting and
  wrapping external libraries.
- Everything is OCaml end to end. Shared types and derived stable serializers mean a new
  server field reaches the client with about one line, and computation can move between
  server and client.
- Transport is streaming RPC over raw sockets, not HTTP, REST or GraphQL; the firm owns
  all browsers and forces refreshes on upgrade, so versioning is rarely a concern.
- Bonsai, the firm's web UI framework, is a general incremental state-machine graph where
  virtual DOM is just one kind of value. Dependencies are explicit and checked by the
  type system rather than hidden hooks, which allows fine-grained recomputation under
  constantly ticking data.
- Sum types and exhaustive pattern matching model UI states (loaded, loading, error,
  unsynced). The host compares the explicitness trade-off to C versus Rust.
- Alert tuning balances missed opportunities against noise. It uses an interestingness
  score, stateful damping (raise the bar after each alert, time-based limits) and
  trader-adjustable thresholds for busy days. Per-user knobs were cut back in favour of
  desk-wide ones because people next to each other ended up with different tools.
- The host notes traders under-report pain, so developers should overreact to
  complaints.
- Side project: a live-coding web app for 3D shapes built on signed distance functions
  that compose by function composition and render by ray marching on the GPU. Once
  transformed, the functions are only approximate distances, which brings artifacts.
- It is written in the Janet Lisp compiled to WebAssembly, using macros for concise
  notation. Janet's image-based compilation (snapshotting a runtime state) contrasts with
  the host's mention of OxCaml work on more limited, static multi-stage programming.
- Expect tests are the guest's favourite practice: tests that write their output into
  the source, like a plain-text notebook that always reruns top to bottom. Printing full
  state (for example a board game's board) makes failures debuggable.
- Property tests record a found failing case back into the test source so it reruns on
  every future run.
- Good expect tests choose and minimize what to print; dumping everything is a known
  failure mode. The idea came from Mercurial's unified tests and Cram, and the guest
  reimplemented the workflow in Janet.

## Relevance to us

- Our [exchange-core](../../../repos/exchange-core.md) engine and the
  [hl-sim](../../../repos/hl-sim.md), [binance-sim](../../../repos/binance-sim.md) and
  [bybit-sim](../../../repos/bybit-sim.md) servers have the same shape as the
  single-dealer platform: an exchange-like API over a book and matcher.
- Shared types end to end are what our `*-protocol` plus client split and
  [market-data](../../../repos/market-data.md) `Stable.V1` bin types already give us.
- **Testing and simulation:** a property-test counterexample found once should rerun
  forever, yet none of our Base_quickcheck properties pass fixed `~examples`. **Action:**
  pass `~examples` with at least one hand-picked edge case (an aggressive order sweeping
  several price levels) to the properties in `test/test_order_book.ml`, in
  [order-book](../../../repos/order-book.md).
- **OCaml practice:** the pinning convention only helps if every agent follows it.
  **Action:** add a rule to the testing skill that each shrunk Quickcheck counterexample
  goes into `~examples` in the same change as the fix, in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).
- **Testing and simulation:** printing whole state makes expect-test diffs explain
  failures. **Action:** add an expect test that runs a seeded `Market_sim` for a few
  steps and prints the top five book levels per side plus each account's position after
  every step, in [exchange-core](../../../repos/exchange-core.md).
- **Logs and state machines:** alerts need stateful damping to stay useful. **Action:**
  log repeated warnings of the same kind (parse errors, upload retries) at most once a
  minute per stream with a suppressed-count field, in
  [market-recorder](../../../repos/market-recorder.md).

Tags: `expect-tests`, `property-testing`, `ui`, `ocaml-practice`, `simulation`
