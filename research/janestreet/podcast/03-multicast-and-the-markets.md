# Multicast and the Markets

- Source: <https://signalsandthreads.com/multicast-and-the-markets/>
- Published: 2020-09-23
- Kind: Signals and Threads episode 3

## Summary

- An exchange reduces to a small core: orders, cancels and executions against a book, plus
  fair dissemination to many competing consumers (traders, clearing firms, other exchanges,
  data vendors).
- Early exchanges fanned data out over TCP connections serially, which created races to be
  first in line; colocation and private networks made UDP multicast practical, letting
  switches copy each packet to all subscribers in hardware.
- Order entry stays on TCP (a UDP order protocol saw little uptake because firms must support
  TCP for every other venue anyway), while public market data goes out over multicast.
- Inside exchanges the matching engine is essentially a sequencer: one process, often on a
  single core, assigns a total order and publishes it; downstream applications rebuild state
  from that stream, with sequence numbers for reordering and gap detection and retransmit
  servers to fill gaps.
- General reliable-multicast protocols were rejected because slow receivers can throttle the
  publisher; instead stragglers recover on their own, and domain knowledge allows a compact
  state snapshot so a late joiner starts mid-day without replaying everything.
- Simplicity is a design goal: a founding engineer of an early exchange held that any component
  you cannot rewrite correctly in a weekend is too complex, and its applications were around
  2000 lines.
- Numbers: store-and-forward switch 7 to 10 us, cut-through 300 to 500 ns, layer 1 crosspoint
  3 to 5 ns; PCIe NIC path 300 to 600 ns; serialization about 1 ns per byte at 10 Gbps, so
  unicasting 1000 bytes to 600 clients puts the last one 600 us behind.
- The guest notes crypto venues, living on the open internet, use websockets and JSON instead,
  "the exception that proves the rule".

## Relevance to us

- The engine in [exchange-core](../../../repos/exchange-core.md) is the single-threaded
  sequencer of this episode; the simulators publish its events to websocket subscribers, and
  [binance-sim](../../../repos/binance-sim.md) and [bybit-sim](../../../repos/bybit-sim.md)
  already emit sequence ids that the client local books use to detect gaps and resync from a
  snapshot.
- The weak spot is downstream: reconnects and gaps inside the clients are invisible through
  `Market_data.Feed.t`, so [market-recorder](../../../repos/market-recorder.md) does not mark
  them in raw files (a known gap in [market-data](../../../repos/market-data.md)).
- **Action:** add a gap or reconnect event to `Market_data.Feed.t`, emitted by the three
  clients' `Live_feed` on resync, and have `market-recorder` write a disconnect line for it,
  covered by an expect test that forces a Bybit sequence gap.

Tags: `multicast`, `sequencer`, `market-data`, `networking`, `latency`
