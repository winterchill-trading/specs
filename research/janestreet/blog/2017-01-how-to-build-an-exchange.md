# How to Build an Exchange

- Source: <https://blog.janestreet.com/how-to-build-an-exchange/>
- Published: 2017-01-11
- Kind: blog post

## Summary

- Announces the first public Jane Street tech talk (February 2, 2017, later fully booked):
  an overview of modern exchange architecture.
- The talk draws on JX, Jane Street's crossing engine, and on the speaker's experience
  going back to the Island ECN.
- The post's own point: JX replicates state with a simple scheme over reliable multicast
  that depends on components having high throughput and low, deterministic latency.
- Performance work there is less about end-to-end latency and more an "architectural
  superpower" that permits a simpler, more reliable design.

## Relevance to us

- Directly touches the engine behind our simulators:
  [exchange-core](../../../repos/exchange-core.md) states that the engine never reads the
  wall clock so runs are deterministic, the property that sequencer-plus-replication
  designs rely on. No test asserts it.
- **Action:** add an expect test in `exchange-core` that drives two engines with the same
  seeded `Market_sim` and order sequence and checks that their event streams are equal as
  sexps.

Tags: `architecture`, `sequencer`, `multicast`, `trading`
