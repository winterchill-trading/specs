# What the interns have wrought, 2020 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2020/>
- Published: 2020-08-17
- Kind: blog post

## Summary

- A remote internship year; each intern stayed on one team all summer instead of the usual
  two projects in different areas. Three projects are described.
- Wireshark dissector for Async-RPC: parses Heartbeat, Query and Response messages,
  reassembles messages split across packets and decrypts Kerberos-protected flows. The
  intern wrapped Wireshark's imperative C API in a monadic OCaml parsing library, so
  dissectors are testable apart from Wireshark and new protocols are cheap to add.
- Sharding by simulated annealing: trading systems that price ETFs need market data for all
  constituents, so packing ETFs with overlapping baskets onto the same instance saves
  resources. A solver (greedy, then simulated annealing with research-supplied cost
  functions) replaced hand sharding and was 10 to 20 percent more efficient.
- Replacing Re2 with the pure OCaml Re library: a drop-in `Re_replace_re2` reuses Re2's C++
  parser to build an OCaml AST, then translates it to Re. Semantic mismatches were found with
  Quickcheck bisimulation tests (run both engines and compare) and AFL fuzzing of the C++
  parsing glue; some fixes went upstream to Re.

## Relevance to us

- **Testing and simulation:** bisimulation (run an implementation and an independent
  reference on the same random inputs and compare) catches semantic gaps that invariant
  checks miss; the [order-book](../../../repos/order-book.md) quickcheck test checks
  invariants and size conservation but not fills against a model. **Action:** add a
  Base_quickcheck test in `order-book` that runs the same random op sequence through
  `Order_book` and a naive sorted-list matcher and asserts identical fills.
- **Testing and simulation:** the three simulators share one engine but each venue adapter
  translates requests and events differently. **Action:** add a script next to `scripts/e2e-all.sh`
  in [market-maker](../../../repos/market-maker.md) that sends one scripted order sequence
  to [hl-sim](../../../repos/hl-sim.md) and [binance-sim](../../../repos/binance-sim.md)
  with noise traders off and diffs the normalized fills.
- **Research tooling:** a protocol dissector written against a monadic parser stays testable
  without the host tool. **Action:** none; our wire formats are JSON text and readable as is.
- **Market making and trading systems:** packing symbols with overlapping data needs onto the
  same instance is an optimization problem, solved here by simulated annealing. **Action:**
  none; our symbol counts per `market-recorder` instance are small enough to set by hand.

Tags: `property-testing`, `testing`, `networking`, `culture`
