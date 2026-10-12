# Market making and trading systems

This theme collects what the Jane Street blog and Signals and Threads say about the systems
that sit between a trading decision and a fill: how exchanges are built, how order gateways
and risk checks behave under failure, how market data feeds lose and recover messages, why
venue semantics differ under identical names, where latency hides in the trading loop, and
how engineers and traders work together. It matters to us because we own both sides of the
wire: a deterministic exchange engine with three venue simulators, and a venue-neutral market
maker that runs on Hyperliquid, Binance and Bybit. Most lessons below map to a concrete test
or guard in [mm-core](../../repos/mm-core.md),
[exchange-core](../../repos/exchange-core.md) or [venue-net](../../repos/venue-net.md).

## An exchange is a sequencer wrapped around a deterministic state machine

Several sources describe the same core shape. A matching engine funnels every request to one
place, stamps a total order on it and publishes the result; downstream applications derive
executions, public data and regulatory reports from that sequenced stream
([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md)). The firm's crossing
engine replicated its state over multicast with a simple scheme that only works because each
component is fast and deterministic, which the author frames as an "architectural
superpower" rather than a latency trophy
([How to Build an Exchange](../janestreet/blog/2017-01-how-to-build-an-exchange.md)). Concord
takes it further: every process is a state machine that consumes one message at a time,
never blocks, and is rebuilt after a crash by replaying the day's log
([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).
The single-dealer platform on the options side has the same outline, an order book and
matcher with exchange-style protocols, but clients trade only against the firm
([episode 23](../janestreet/podcast/23-building-tools-for-traders.md)).

Determinism is what makes this testable as well as replicable. A simulation framework that
injects clock, network and scheduler from the library level lets a failing seed reproduce
exactly ([episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md)),
and an input log plus a deterministic engine turns a simulator incident into a replay
([2024 intern projects](../janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md)).
A stepped harness in which scripted traders and the exchange advance in lockstep is a clean
way to pin a whole multi-actor run
([algebraic effects in Hardcaml](../janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md)).

## Market data: sequence numbers, gaps, snapshots and slow consumers

Multicast is neither reliable nor ordered, so the sequencer numbers every message, receivers
detect gaps and ask retransmitters to fill them, and a late joiner loads a compact snapshot
instead of replaying from midnight
([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md),
[episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).
General reliable-multicast protocols were rejected because one slow receiver can throttle the
publisher; stragglers must recover on their own. Most drops come from slow consumers, not
from the network. Gord, the firm's trading-activity pipeline, learned the same lesson the
hard way: push over TCP disconnected slow clients, and a pull model that lets them lag
visibly replaced it ([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md)).

Crypto venues are the odd case: public websockets and JSON rather than colocated multicast,
which the guest of episode 3 calls the exception that proves the rule. The underlying problem
is unchanged. Our clients already detect Binance and Bybit sequence breaks and resync from a
snapshot, but that recovery is invisible to anyone reading the normalized feed, so a recorded
day cannot say where it is incomplete
([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md)). Reconnection itself
is a hazard: after a network partition, many clients in one process reconnecting on the same
schedule produced a surge of hundreds of thousands of connections, and a timeout that did not
cancel the underlying attempt let all the queued work fire at once on recovery
([recurring network maintenance](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md)).
Behaviour like frame loss on reconnect cannot be expressed in a type and belongs in the
interface's doc comment ([episode 10](../janestreet/podcast/10-writing-technically.md)).

## Order gateways: ambiguous outcomes and reconciliation

The order path has one failure mode that recurs across very different systems: an ambiguous
result followed by a retry. In the kernel bug behind a rare NFS failure, a late reply to a
retransmitted request failed verification, which triggered another retransmission, so the
fault fed itself under high latency
([Higgs-bugson](../janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md)). An order
place that times out is the trading version: if the order later shows up resting, the
gateway must adopt it by client id rather than place a twin. FIX sequence numbers that
persist across a reconnect exist so a client can learn whether its order traded
([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).

The same episode names the classic bug of the problem-solver style that our `Reconciler`
follows: an app that does not update its view after acting re-proposes the same message
forever. Domain-aware coalescing helps in the other direction, since a queued order and its
cancel can annihilate rather than both being sent
([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md)). Reconciliation also
runs after the fact: matching internal trade records against anonymous public prints by
time, size and price catches booking errors before official confirmations arrive
([TDOE intern projects](../janestreet/blog/2026-09-tdoe-intern-projects-2026.md)), which for
us needs the market maker's own order lifecycle recorded somewhere queryable
([2023 intern projects](../janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md)).

## Risk checks live outside the strategy and must cover every path

Risk systems cap a strategy from outside, and they are only as good as the inputs they
trust. Contract metadata is the main trap: futures quoted per unit but delivering 1,000
barrels mean a units mix-up trades a hundred times the intended size
([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)), and crypto has the
same issue with `1000PEPEUSDT` and `kPEPE`. A single out-of-range field can drop a whole
account snapshot ([63-bit integers](../janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md)),
and a NaN passes any float check phrased as a failing condition
([None versus NaN](../janestreet/blog/2010-07-making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null.md)).

Every order path needs the same checks, including manual and emergency ones; an intern
project routed manual price requests through the automated RFQ checks they had bypassed
([episode 9](../janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md)).
The same episode describes soft limits that a trader may bump a fixed number of times on a
busy day while hard limits stay sticky. Overrides for special dates need an owner and an
expiry, or they lapse unnoticed at the worst moment or linger long after
([Strategy and Product interns](../janestreet/blog/2026-09-wrought-2026-sp.md)). A runaway
client without a rate limit degrades shared infrastructure for everyone
([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).
Finally, a market maker that quotes too aggressively never crashes, so its safety properties
have to be written down explicitly rather than inferred from coarse crash detection
([episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md)).

## Venue semantics differ under the same names

An order attribute with one name on two US venues rests at the best bid on one and a tick
behind with discretion on the other; the intern who encoded it kept the two meanings
separate in the types instead of collapsing them
([TDOE intern projects](../janestreet/blog/2026-09-tdoe-intern-projects-2026.md)). Gord's
history shows the cost of normalizing too eagerly: it invented orders for orphan fills and
encoded rejects as fake orders plus closes, and consumers came to rely on the fabrications
([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md)). Our
three simulators share one engine, so any real difference between Hyperliquid `Alo`, Binance
`GTX` and Bybit `PostOnly`, or between their market-order slippage rules, is currently hidden
behind a single semantics.

## Latency in the trading loop is mostly about where the send waits

For trading systems, hard-mode performance is latency at the moments that matter, and the
most expensive bug in episode 18 was not slow code: deciding and sending were both cheap, but
an older API deferred the network write to idle time, adding 200 microseconds that no profile
could show ([episode 18](../janestreet/podcast/18-performance-engineering-on-hard-mode.md)).
Tails are usually the median repeated during a burst, and the standard fix is to batch when
behind; it is the tail rather than the median that fails when markets are busy
([episode 1](../janestreet/podcast/01-programmable-hardware.md)). In a single-threaded Async
program, one long cycle stalls every feed and every quote at once
([magic-trace](../janestreet/blog/2022-01-magic-trace.md)), and per-tick allocation decides
whether locality and stack allocation are worth adopting in the quoter
([locality](../janestreet/blog/2023-05-oxidizing-ocaml-locality.md)).

Latency also shapes which price to trust. Correlated futures move together at close to the
speed of light between exchanges, so the venue that leads carries the information
([information propagation](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md)).
Physical placement is a latency decision too: failing over to a more distant site is a
latency change rather than a transparent swap, which is why the firm invests in per-site
resilience ([episode 24](../janestreet/podcast/24-the-thermodynamics-of-trading.md)).

## Traders and engineers: dense tools, fast feedback and humans in the loop

Trading is more manual than outsiders expect: phone trades, manual orders, and validation
failures frozen until a trader approves them
([episode 9](../janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md)). The
firm moved from central teams to developers embedded on each desk, who translate trader
requirements into data models and show traders with high pain thresholds what better tools
would look like ([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)).
Trader-tool engineers sit an aisle away, learn enough options theory to build features, and
are told to overreact to complaints because traders under-report pain
([episode 23](../janestreet/podcast/23-building-tools-for-traders.md)). Expert users want dense
keyboard-driven screens with every state field visible
([episode 19](../janestreet/podcast/19-from-the-lab-to-the-trading-floor.md)), and when a data
center's cooling failed, the useful output for the desk was a number: how long they could keep
trading ([episode 24](../janestreet/podcast/24-the-thermodynamics-of-trading.md)).

For an automated strategy the equivalent is legibility. Simple models can be adjusted by hand
when a regime changes ([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md));
a shadow instance run on live input, with its decisions diffed against production, reveals
behaviour changes before they cost money
([episode 8](../janestreet/podcast/08-building-a-functional-email-server.md),
[config orchestrator](../janestreet/blog/2026-10-config-management-orchestrator-for-windows.md));
and computations that print each intermediate term, or sample outputs shipped with a model,
make a parameter change visible in review
([self-documenting computations](../janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md),
[episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md)).

## Where we stand

- [exchange-core](../../repos/exchange-core.md) already has the sequencer shape: the engine
  takes a caller-advanced nanosecond clock, assigns sequential ids and drains an event log,
  but no test asserts that two runs on identical input produce identical events, and engine
  `Event` values carry no sequence number.
- [mm-core](../../repos/mm-core.md) has Base_quickcheck properties over `Quoter` (quotes never
  cross, ladders strictly ordered, filling every quote cannot pass `max_position`, tick and lot
  aligned) and over `Reconciler` (reconciling a ladder against itself is a no-op). Nothing yet
  drives `Strategy` through random sequences of book, fill and open-order events, and the
  reconciler property does not start from arbitrary resting orders.
- `Mm_core.Risk` covers sticky halts on position and drawdown and non-sticky pauses on missing
  or stale data; there is no order-rate limit, no soft limit, and parameters are static for a
  run. `Params.validate` phrases its float checks so that NaN fails, but no test pins this.
- `Live.Make` already coalesces work: ticks, plan execution and polls share one Async
  sequencer and at most one tick waits in the queue, so a burst collapses to one quote on the
  latest state. Within a plan, cancels are awaited before places are sent. `Live.Report`
  counts plans, orders and rejections but records no latency.
- A failed `place` is logged and the next `open_orders` poll picks up whatever is resting, so
  a timed-out order that later appears would be seen; no test covers that path, and the
  simulators answer instantly ([design/market-making.md](../../design/market-making.md)).
- [venue-net](../../repos/venue-net.md) `Ws_client` doubles its backoff from 0.5 s to 30 s
  with no jitter, and its page notes that `send` drops frames while disconnected and callers
  must resync after reconnects.
- [market-data](../../repos/market-data.md) `Feed.S` exposes trades, BBO, L2 and funding pipes
  only, so client resyncs and reconnects leave no mark in recorded data.
- The three simulators share one semantics ([design/simulators.md](../../design/simulators.md));
  per-venue differences live only in each adapter's error and status mapping.
- [hl-mm](../../repos/hl-mm.md) logs and skips clearinghouse snapshots whose `liquidationPx`
  exceeds the `fixed-decimal` range, and [market-maker](../../repos/market-maker.md) runs are
  not bit-repeatable with a fixed seed because request timing changes matching order.

## Proposed actions

1. Add a Base_quickcheck test that drives `Strategy` with random book, fill and open-order
   events over many seeds and asserts quotes never cross, stay ordered and cannot exceed
   `max_position`, in [mm-core](../../repos/mm-core.md)
   ([episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md)).
2. Add a seeded bugify mode to the in-memory `Venue.S` test fake (rejects, delayed cancel
   acks, split fills, stale open-order polls) and an expect test where a timed-out place later
   appears and is adopted by client id, in [mm-core](../../repos/mm-core.md)
   ([episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md),
   [Higgs-bugson](../janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md)).
3. Record a histogram from a book event's `recv_ts` to the order send it triggers in
   `Live.Make`, report p50, p99 and max in `Live.Report`, and print it per venue from
   `scripts/e2e-all.sh`, in [mm-core](../../repos/mm-core.md) and
   [market-maker](../../repos/market-maker.md)
   ([episode 18](../janestreet/podcast/18-performance-engineering-on-hard-mode.md),
   [episode 1](../janestreet/podcast/01-programmable-hardware.md)).
4. Add a gap or reconnect event to `Market_data.Feed.t`, emitted by each client's `Live_feed`
   on resync and written as a disconnect line, with an expect test forcing a Bybit sequence
   gap, in [market-data](../../repos/market-data.md),
   [market-recorder](../../repos/market-recorder.md) and the three clients; document frame loss
   on reconnect in the `Ws_client.messages` doc comment in
   [venue-net](../../repos/venue-net.md)
   ([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md),
   [episode 10](../janestreet/podcast/10-writing-technically.md)).
5. Add a property that applying a reconcile plan to arbitrary resting orders and reconciling
   again yields only `Keep`, in [mm-core](../../repos/mm-core.md)
   ([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).
6. Add an actions-per-second cap to `Mm_core.Risk` that trips the kill switch when the live
   loop exceeds it, in [mm-core](../../repos/mm-core.md)
   ([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).
7. Add random jitter to the `Ws_client` exponential backoff and log the chosen delay; audit
   every `with_timeout` in venue-net and the clients for attempts that keep running after the
   timeout, in [venue-net](../../repos/venue-net.md),
   [hl-client](../../repos/hl-client.md), [binance-client](../../repos/binance-client.md) and
   [bybit-client](../../repos/bybit-client.md)
   ([network maintenance](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md)).
8. Add a `-response-delay-ms` flag to `hl-sim` and run the `hl-mm` live-loop test under it to
   check no double placement while acks are outstanding, in [hl-sim](../../repos/hl-sim.md)
   and [hl-mm](../../repos/hl-mm.md)
   ([Higgs-bugson](../janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md)).
9. Add a table to [design/simulators.md](../../design/simulators.md) mapping each `Tif` and
   market-order slippage rule to each venue's wire value and semantics, then pin each
   difference with an expect test in [hl-sim](../../repos/hl-sim.md),
   [binance-sim](../../repos/binance-sim.md) and [bybit-sim](../../repos/bybit-sim.md),
   starting with a crossing post-only order
   ([TDOE intern projects](../janestreet/blog/2026-09-tdoe-intern-projects-2026.md)).
10. Add an expect test showing `Params.for_instrument` and the `max_position` check on a
    `1000PEPEUSDT`-style instrument, documenting contracts versus tokens, in
    [mm-core](../../repos/mm-core.md); add a `units_per_contract` table and DuckDB view in
    [market-data](../../repos/market-data.md)
    ([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)).
11. Add an expect test that drives two engines with the same seeded `Market_sim` and order
    sequence and compares event streams, add a sequence number to engine `Event`, and journal
    `place`/`cancel`/`modify`/`step`/`set_mark` inputs with a replay test, in
    [exchange-core](../../repos/exchange-core.md); log accepted `hl-sim` requests for the same
    replay ([How to Build an Exchange](../janestreet/blog/2017-01-how-to-build-an-exchange.md),
    [episode 3](../janestreet/podcast/03-multicast-and-the-markets.md),
    [episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md),
    [2024 intern projects](../janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md)).
12. Add a Base_quickcheck test of random `place`/`cancel`/`step` sequences on `Exchange`
    asserting zero net position across accounts, an uncrossed book and unique order ids, in
    [exchange-core](../../repos/exchange-core.md)
    ([episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md)).
13. Add a Base_quickcheck property that `Risk.flatten` only ever places reduce-only orders over
    random positions, mids and open orders, in [mm-core](../../repos/mm-core.md)
    ([episode 9](../janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md)).
14. Add `-shadow-params FILE` to the binary, running a second `Strategy` on the same feed that
    only logs plans and counts divergences, plus an expect test printing only the differing
    plans of two `Params` over one scripted sequence, in
    [market-maker](../../repos/market-maker.md) and [mm-core](../../repos/mm-core.md)
    ([episode 8](../janestreet/podcast/08-building-a-functional-email-server.md),
    [config orchestrator](../janestreet/blog/2026-10-config-management-orchestrator-for-windows.md)).
15. Add a `-params FILE` sexp flag re-read on SIGHUP and applied only after `Params.validate`;
    when per-run overrides arrive, require an expiry and reject expired ones in `validate`, in
    [market-maker](../../repos/market-maker.md) and [mm-core](../../repos/mm-core.md)
    ([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md),
    [Strategy and Product interns](../janestreet/blog/2026-09-wrought-2026-sp.md)).
16. Write the market maker's order lifecycle events to an event log, then add a DuckDB query
    joining its fills to recorded public trades by price, size and time window, in
    [market-maker](../../repos/market-maker.md) and [market-data](../../repos/market-data.md)
    ([2023 intern projects](../janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md),
    [TDOE intern projects](../janestreet/blog/2026-09-tdoe-intern-projects-2026.md)).
17. Drive `Strategy` against the engine through a deterministic stepped harness and pin one
    fixed-seed run's fills in an expect test, in [mm-core](../../repos/mm-core.md) and
    [exchange-core](../../repos/exchange-core.md)
    ([algebraic effects in Hardcaml](../janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md)).
18. Add a fault phase to `scripts/e2e-all.sh` that restarts the simulator mid-run and checks
    reconnect, resync and quoting resume, in [market-maker](../../repos/market-maker.md)
    ([episode 20](../janestreet/podcast/20-solving-puzzles-in-production.md)).
19. Log a warning from the binary when an Async cycle exceeds 20 ms, in
    [market-maker](../../repos/market-maker.md)
    ([magic-trace](../janestreet/blog/2022-01-magic-trace.md)).
20. Add an optional `soft_max_position` with a bump budget to `Params` and `Risk` that pulls
    only the position-growing side instead of halting, in [mm-core](../../repos/mm-core.md)
    ([episode 9](../janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md)).
21. Add a `Quoter.For_testing.explain` tree printer with one expect test, and have the quoter
    return a typed reason for each side it does not quote, in [mm-core](../../repos/mm-core.md)
    ([self-documenting computations](../janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md),
    [config orchestrator](../janestreet/blog/2026-10-config-management-orchestrator-for-windows.md)).
22. Add an expect test driving `Strategy` from a `Replay_feed` over a small fixture event log,
    and one printing quotes for a fixed market state and inventory under each `Params`
    preset, in [mm-core](../../repos/mm-core.md)
    ([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md),
    [episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md)).
23. Send one scripted order sequence to `hl-sim` and `binance-sim` with noise off and diff the
    normalized fills, in a script next to `e2e-all.sh` in
    [market-maker](../../repos/market-maker.md)
    ([2020 intern projects](../janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md)).
24. Add a test that a websocket subscriber which never reads does not delay order
    acknowledgements for other clients, in [hl-sim](../../repos/hl-sim.md)
    ([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md)).
25. Decode `liquidationPx` as an option that is `None` when out of range, so one field no
    longer drops a whole snapshot, in [hl-protocol](../../repos/hl-protocol.md) and
    [hl-mm](../../repos/hl-mm.md)
    ([63-bit integers](../janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md)).
26. Add a lead-lag DuckDB query (mid moves above 1 bp within 5 ms) and record the median lag
    per venue pair in the market-making design notes before any cross-venue fair value, in
    [market-data](../../repos/market-data.md) and [mm-core](../../repos/mm-core.md)
    ([information propagation](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md)).
27. Specify gap detection by venue sequence fields, gap fill from the peer collector, and
    tagging each event with its collector and region in
    [design/cloud-sinks-and-replication.md](../../design/cloud-sinks-and-replication.md)
    ([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md),
    [episode 24](../janestreet/podcast/24-the-thermodynamics-of-trading.md)).
28. Write periodic L2 snapshot events so `Replay_feed` can start mid-day from the last
    snapshot, in [market-recorder](../../repos/market-recorder.md) and
    [market-data](../../repos/market-data.md)
    ([episode 3](../janestreet/podcast/03-multicast-and-the-markets.md),
    [episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).
29. Add an expect test printing minor words per quote computation and a `core_bench` case for
    `Quoter.quote`, in [mm-core](../../repos/mm-core.md)
    ([locality](../janestreet/blog/2023-05-oxidizing-ocaml-locality.md),
    [core_bench](../janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md)).
30. Add a test that NaN in each float `Params` field makes `validate` fail, in
    [mm-core](../../repos/mm-core.md)
    ([None versus NaN](../janestreet/blog/2010-07-making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null.md)).
