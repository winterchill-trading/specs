# How to Build an Exchange

- Source: <https://blog.janestreet.com/how-to-build-an-exchange/>
- Published: 2017-01-11
- Kind: blog post

## Summary

- Announces the first in a planned series of public tech talks in the New York office
  (February 2, 2017), later fully booked.
- Topic: the architecture of a modern exchange, inspired by JX, Jane Street's crossing
  engine, and by the speaker's experience going back to the Island ECN, which the author
  regards as the birth of the modern exchange.
- JX replicates state with a simple scheme over reliable multicast that depends critically
  on components having high throughput and low, deterministic latency.
- The author's point: performance work here is less about end-to-end latency than an
  "architectural superpower" that allows a simpler and more reliable design.

## Relevance to us

- **Logs and state machines:** sequencer-plus-replication designs rely on every component
  being a deterministic function of its input; [exchange-core](../../../repos/exchange-core.md)
  says its engine never reads the wall clock for exactly this reason, but no test asserts
  it. **Action:** add an expect test in `exchange-core` that drives two engines with the same
  seeded `Market_sim` and order sequence and checks their event streams are equal as sexps.
- Context: the simulators ([hl-sim](../../../repos/hl-sim.md) and siblings) inherit this
  property, which the planned replay server on the [roadmap](../../../roadmap.md) will
  depend on.

Tags: `architecture`, `sequencer`, `multicast`, `trading`
