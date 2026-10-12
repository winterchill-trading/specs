# Multicast and the Markets

- Source: <https://signalsandthreads.com/multicast-and-the-markets/>
- Published: 2020-09-23
- Kind: Signals and Threads episode 3

## Summary

- The guest has about 20 years in market infrastructure, including early exchange systems at
  Island and Instinet (whose technology underlies Nasdaq's) and work at trading firms, and now
  focuses on low-latency networking at Jane Street.
- Exchanges moved over 10 to 15 years from rules that tolerated slow floor participants to
  always-accessible electronic quotes; participants now include traders, clearing firms, other
  exchanges (which must respect each other's quotes) and market data vendors.
- The message set is small: orders (buy or sell up to a size at no worse than a price, filled
  immediately, resting, or cancelled), cancels and executions reported to both sides.
- The core is a book of resting orders; reliability is critical, since losing or half-reporting
  an execution is unacceptable, and so is fair dissemination to competing participants.
- Island's early design gave each client similar hardware and paths but used thousands of
  mostly idle machines; when connections were shared, serial fan-out in connection order caused
  races to connect first, and round-robin led clients to open many ports and take the fastest.
- Colocation and private cross-connects made UDP multicast viable: one packet is replicated by
  switches to all subscribers instead of the sender writing a copy per TCP connection.
- TCP's congestion and network-health heuristics add latency variance; kernel maintainers
  advised UDP for latency-sensitive traffic on controlled networks.
- Order entry still uses TCP (a UDP order protocol saw little uptake because a firm connected
  to 60 venues must handle TCP anyway); public market data uses multicast.
- Colocation makes competition between professionals fairer by controlling how participants
  connect; bilateral markets (currencies, RFQ in fixed income) work differently from the US
  equity model.
- Multicast failed on the open internet and in clouds but dominates trading, because everyone
  wants the same few live streams at once.
- Inside exchanges, the matching engine is essentially a sequencer that funnels requests to one
  place, assigns a total order and publishes it; downstream applications compute executions,
  regulatory reports and public data, and some exchanges separate sequencing from matching.
- Multicast is neither reliable nor ordered, so the sequencer numbers each message, receivers
  reorder and detect gaps, and retransmission servers fill them.
- General reliable-multicast protocols were rejected because a slow receiver can throttle the
  publisher; with thousands of receivers someone always has a problem, so stragglers recover
  separately.
- Domain knowledge lets a late joiner load a compact state snapshot instead of replaying the
  whole day, and lets queued order/cancel pairs cancel out instead of being sent, which TCP's
  byte buffers cannot do.
- Market fragmentation across many venues rewards speed and determinism with better prices:
  routers probe venues in turn, and market makers simulate an any-one-venue order by
  quoting everywhere and pulling quotes quickly after a fill.
- Nasdaq ran every transaction through one Java program on a single core; a single stream
  removes partitioning problems once each event is made fast and uniform.
- The guest's *mechanical sympathy* means knowing what the hardware can theoretically do, so
  you can check whether a design can work at all and how far you are from optimal.
- Building that intuition takes careful experiments, since modern CPUs make naive benchmarks
  misleading; scalability is not the same as efficiency.
- I/O moved from interrupts to polling on spare cores, and from copying socket reads to
  zero-copy rings where the NIC writes into memory the application polls (25 Gbps means copying
  25 gigabits per second otherwise).
- A founding engineer of an early exchange held that any component you cannot rewrite correctly
  in a weekend is too complex; applications were around 2000 lines and the exchange four or
  five of them.
- With 12 to 17 US equity venues near 10 Gbps each and a rule requiring consolidation,
  10 Gbps NICs are a mismatch; FPGA NICs can filter by content, such as specific securities.
- Switch latency fell from 7 to 10 us (store-and-forward) to 300 to 500 ns (cut-through) to
  3 to 5 ns (layer 1 crosspoints that replicate electrically); core-to-core is about 100 ns,
  PCIe through a tuned NIC 300 to 600 ns, and a context switch a microsecond or two.
- Serialization costs about 1 ns per byte at 10 Gbps: unicasting a 1000-byte message to 600
  clients puts the last one about 600 us behind and caps throughput near 2000 messages per
  second, while multicast reaches all in about a microsecond.
- InfiniBand pioneered hardware reliability, zero-copy and RDMA, but its hardware flow control
  let oversubscribed receivers silently slow market data; Ethernet's drop-fast model is easier
  to debug, and RoCE stayed partly proprietary.
- Commodity hardware usually wins (a software product on a cheap card replaced most of a
  specialized telephony line), though specialization is returning with GPUs and FPGAs.
- Expected trends: io_uring and similar polling, zero-copy APIs becoming standard, and 25 Gbps
  networking, whose forward error correction adds latency.
- Crypto venues, on the open internet, use websockets and JSON instead, which the guest calls
  "the exception that proves the rule".

## Relevance to us

- The engine in [exchange-core](../../../repos/exchange-core.md) is the single-threaded
  sequencer of this episode, and [binance-sim](../../../repos/binance-sim.md) and
  [bybit-sim](../../../repos/bybit-sim.md) already emit update ids that the client local books
  use to detect gaps and resync from a snapshot.
- **Logs and state machines:** Receivers must know when they lost messages, but client
  reconnects and resyncs are invisible through `Market_data.Feed.t`, so recorded data hides its
  gaps. **Action:** add a gap or reconnect event to `Market_data.Feed.t`, emitted by each
  client's `Live_feed` on resync, and write it as a disconnect line, covered by an expect test
  that forces a Bybit sequence gap, in [market-data](../../../repos/market-data.md) and
  [market-recorder](../../../repos/market-recorder.md).
- **Logs and state machines:** A sequenced event stream lets any consumer rebuild state by
  replay, but engine events carry no sequence number. **Action:** add a monotonically
  increasing sequence number to the engine's `Event` and an expect test that replays drained
  events into a fresh book and compares the L2 snapshot, in
  [exchange-core](../../../repos/exchange-core.md).
- **Data platform:** A late joiner should load a compact snapshot rather than replay from the
  start of the day, and our event logs only hold snapshots at connect and resync. **Action:**
  write a periodic L2 snapshot event (for example each minute) into the event log so
  `Replay_feed` can start mid-day, in [market-recorder](../../../repos/market-recorder.md).
- **Performance:** A publisher must never slow down for one slow consumer. **Action:** add a
  test that a websocket subscriber which never reads does not delay order acknowledgements for
  other clients, in [hl-sim](../../../repos/hl-sim.md).
- Our `Reconciler` in [mm-core](../../../repos/mm-core.md) already does the domain-aware
  coalescing described: it computes a minimal plan from resting orders rather than replaying
  every intermediate order and cancel.
- The cross-venue quoting problem (quote everywhere, pull elsewhere after a fill) applies to
  [market-maker](../../../repos/market-maker.md) running on three venues, but changing that is a
  strategy decision rather than a small change.

Tags: `multicast`, `sequencer`, `market-data`, `networking`, `latency`
