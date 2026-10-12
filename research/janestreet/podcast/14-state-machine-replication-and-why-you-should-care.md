# State Machine Replication, and Why You Should Care

- Source: <https://signalsandthreads.com/state-machine-replication-and-why-you-should-care/>
- Published: 2022-04-20
- Kind: Signals and Threads episode 14

## Summary

- Concord was built for Jane Street's bilateral client trading, where the firm runs
  exchange-like matching against its own desks' orders. That makes it a service provider:
  it needs uptime, fast turnaround and an audit trail for regulators.
- Requirements: a client that reconnects after a network or server failure must learn
  whether its order traded; processes must move to new boxes within minutes; and peak days
  are orders of magnitude busier. All public market data is on the system too, for
  regulatory reasons.
- FIX sequence numbers persist across a whole day and allow resend requests after a
  reconnect. This is a reliability layer above TCP, which guarantees nothing once a
  connection or host is lost.
- The core abstraction is a replicated state machine: a module holding state that
  processes one message at a time, synchronously and deterministically, never blocking on
  network or disk. Replaying the same messages always yields the same state.
- On restart, every process replays the day's transaction log from the start and ends up as
  an exact copy of itself before the crash.
- The log is distributed by UDP multicast, where switches copy packets in hardware. It is
  rare on the internet but common in finance, and easy to run within one hardware cabinet.
- Every packet carries a sequence number, so a gap (45 then 47) triggers a request to a
  retransmitter. Retransmitters are ordinary processes that record the stream and ask each
  other, or finally the sequencer. Most drops come from slow consumers, not the network.
- Appending works by multicasting a proposal. A single sequencer stamps a sequence number
  and timestamp and rebroadcasts it, turning an unordered input into one canonical order.
  Failover to a backup sequencer is deliberately manual so people can check state first.
- The single choke point scales well enough: a 10 Gbit network, disk writes, 8 to 12
  microseconds round trip (within 10x of the PCIe floor of about 1 to 1.5 microseconds),
  baseline over 100,000 messages per second with 3x to 5x on busy days, and over 400 GB in
  one trading day. Encoding effort goes into the most frequent messages.
- Apps are written in an inverted style: the framework asks each app what it wants to
  sequence next, rather than the app pushing. This moves hidden state out of threads and
  stacks into explicit data, and lets tests feed messages in any order to reproduce races.
- Processes are built from smaller state machines. Instead of messaging another process,
  an app embeds the same state machine and reaches the same conclusions from the same
  inputs. That makes splitting or merging processes easy.
- Costs: every process must keep up with every message, so the message type is a tree that
  allows cheap early discarding, and hot code is written to avoid allocation.
- Versioning is brittle: one global message type, with a digest in the first message so
  that apps which do not recognize it refuse to start. Since logs must stay readable,
  message-only changes are rolled separately from riskier logic changes. Broadcast leaves no
  room for version negotiation.
- Each Concord instance needs its own sequencer, retransmitters, config and hardware
  cabinet, so new instances are rare and small apps are impractical.
- Aria generalizes this as a shared service run by one team. Users bring a box and talk to
  the core through a proxy. Payloads are opaque bytes, so the core mainly copies bytes and
  writes them to disk.
- Aria topics form a hierarchical namespace with subtree subscriptions and one total order
  across all topics. That keeps cross-topic decisions reproducible, unlike Kafka's
  per-partition order, where replay skews small topics ahead of large ones.
- Protocols are per topic, so publishing V2 and V3 side by side works like negotiation, but
  order is lost between versions. Code that interprets messages is itself an implicit
  version: a new binary can reach a different state from the same log.
- Write permissions are granted per topic subtree. Multicast cannot enforce read
  permissions, so client libraries check reads on trust; internal topics are hidden so
  others cannot depend on them. Config and permission changes are messages in the stream.
- Gaps: no rate limiting yet, so a runaway client can slow shared sequencers, proxies and
  disks. No snapshots either, so a late starter replays from the start of the day, or of
  the week if sessions grow.
- Snapshots are application specific: the open-orders snapshot an exchange publishes cannot
  rebuild a count of the day's orders. Aria plans client-built snapshot servers that reuse
  other teams' state machine libraries.
- Adoption is through patterns such as the injector, documentation and a bootcamp. A
  typical injector bug is failing to update state after a proposal is sequenced, so it
  re-proposes forever. Libraries such as a pipe-backed injector make this hard to get wrong.

## Relevance to us

- `exchange-core-engine` in [exchange-core](../../../repos/exchange-core.md) is already a
  deterministic state machine (caller-driven clock, sequential ids, seeded noise traders),
  and [market-data](../../../repos/market-data.md) `Merge` already orders many streams
  deterministically.
- **Logs and state machines:** a deterministic engine can be rebuilt exactly by replaying
  its inputs, which makes every simulator session reproducible. **Action:** add an input
  journal that records every `place`/`cancel`/`modify`/`step`/`set_mark` call, plus an
  expect test that replays it into a fresh engine and checks `drain_events` output is
  identical, in [exchange-core](../../../repos/exchange-core.md).
- **Market making and trading systems:** in the problem-solver style, an app that does not
  update its state after acting re-sends the same message forever; our `Reconciler` is that
  style. **Action:** add a Base_quickcheck property that applying a reconcile plan to the
  resting orders and reconciling again yields only `Keep` actions, in
  [mm-core](../../../repos/mm-core.md).
- **Market making and trading systems:** a runaway injector with no rate limit hurts
  everyone downstream. **Action:** add an actions-per-second cap to `Mm_core.Risk` that
  trips the kill switch when the live loop exceeds it, in
  [mm-core](../../../repos/mm-core.md).
- **Logs and state machines:** an unrecognized format digest at the start of a log should
  stop a reader before it decodes anything. **Action:** write a header frame with the
  `bin_shape` digest of `Event.Stable.V1` at the start of each `Event_log` file and fail
  readers on a mismatch, in [market-data](../../../repos/market-data.md).
- **Data platform:** replay must keep one global order across streams, or small streams
  run ahead of big ones as in Kafka. **Action:** add an expect test where `Replay_feed`
  replays a 10-event and a 10,000-event stream together and checks the output is sorted
  by `recv_ts`, in [market-data](../../../repos/market-data.md).
- **Data platform:** replay from the start of the day does not scale, and snapshots are
  specific to each consumer. **Action:** let `Replay_feed` start at the last L2 `Snapshot`
  event at or before the requested start time instead of the beginning of the file, in
  [market-data](../../../repos/market-data.md).
- **Data platform:** sequence numbers plus retransmitters, and peers that fill each other's
  gaps, is the shape of our planned two-region replication. **Action:** specify gap
  detection by venue sequence fields (Binance `pu`/`u`, Bybit `seq`) and gap fill from the
  peer collector in `design/cloud-sinks-and-replication.md` in `specs`.

Tags: `state-machines`, `sequencer`, `replay`, `architecture`, `multicast`
