# Testing and simulation

This theme collects what the sources say about making a trading stack trustworthy before it
touches money: expect tests as the default style, property tests with good distributions and
reference models, deterministic simulation with injected faults, tests over recorded real
traffic, simulators and fakes that misbehave on purpose, shadow runs that diff an old and a new
decision engine, chaos in whole-system runs, and the habit of fixing a bug by first writing the
test that shows it. It matters to us more than to most projects of our size: we already own a
deterministic exchange engine and three venue simulators, most code is written by agents whose
output has to be checked mechanically, and a market maker that quotes badly does not crash, so
nothing but tests will tell us.

## Expect tests that print the whole state

Expect tests are the backbone of the style described across the blog. The test prints, the
build fills in the output, and any later change shows up as a diff to accept or reject
([testing with expectations](../janestreet/blog/2015-12-testing-with-expectations.md),
[the joy of expect tests](../janestreet/blog/2023-01-the-joy-of-expect-tests.md)). Their real
audience is the reviewer: when almost every semantic change appears as a changed trace, a review
reads behaviour rather than code
([Iron development style](../janestreet/blog/2017-08-ironing-out-your-development-style.md)).
Dumping the whole state checks things nobody thought to assert, such as an order size silently
growing from 1 to 100.

The craft is in the printer. Hardware tests print one line per clock cycle or an ASCII waveform
([ASCII waveforms](../janestreet/blog/2020-06-using-ascii-waveforms-to-test-hardware-designs.md),
[episode 1](../janestreet/podcast/01-programmable-hardware.md)); trading tools print the full
book and positions after each step so a failing diff explains itself
([episode 23](../janestreet/podcast/23-building-tools-for-traders.md)); computations that carry
their own intermediate terms make margin and liquidation branches visible
([self-documenting computations](../janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md)).
Text rendering also extends to terminal UIs, where a rendered screen in an expect block lets an
agent check its own UI work
([Bonsai_term](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md)).
Cram-style tests apply the same diffing to whole command lines, and parsing every shipped example
config in a test keeps examples from rotting
([episode 8](../janestreet/podcast/08-building-a-functional-email-server.md),
[caveat configurator](../janestreet/blog/2017-04-caveat-configurator-how-to-replace-configs-with-code-and-why-you-might-not-want-to.md)).

## Property tests: distributions, boundaries and reference models

Writing a random test is easy; reaching the interesting inputs is the hard part. Core's
Quickcheck was built around shaping distributions: integer generators biased toward range ends,
monadic generators that aim list lengths at an implementation's thresholds, and default
generators living next to their types
([Quickcheck for Core](../janestreet/blog/2015-10-quickcheck-for-core.md)). For bounded
fixed-point arithmetic the right oracle is an exact model, not hand-picked cases
([Z3 proofs and refutations](../janestreet/blog/2018-02-proofs-and-refutations-using-z3.md)).

The strongest pattern for optimized data structures is bisimulation: run random operation
sequences against both the fast structure and a slow, obviously correct reference, and compare
every output. Intern projects found semantic gaps this way that invariant checks had missed
([interns 2020](../janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md),
[interns 2022](../janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md)). Fuzzing goes
further by mapping arbitrary bytes to state-machine inputs
([tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md)),
and randomizing internal layout choices (buffer and flush sizes) proves outputs do not depend on
them ([Aria benchmarking](../janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md)).
Properties stated once serve as tests now and as proof targets later
([formal methods](../janestreet/blog/2026-06-formal-methods-at-jane-street.md)), and with agents
writing code a checked contract is what a human can actually review
([episode 16](../janestreet/podcast/16-future-of-programming.md)). A counterexample found once
should be pinned as an explicit example so it runs forever
([episode 23](../janestreet/podcast/23-building-tools-for-traders.md)).

Where do properties come from? [Episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md)
offers three sources: paging-level alerts turned into assertions, Socratic questions about the
contract, and speculative invariants that have held on every observed call. It also warns that
coarse properties catch crashes and hangs but not a strategy that is merely too aggressive; those
need precise properties such as quotes never crossing and position staying within limits
([interns 2025](../janestreet/blog/2025-08-wrought-2025.md),
[episode 9](../janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md)).

## Deterministic simulation and fault injection

FoundationDB's lesson, retold in
[episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md), is that a
whole distributed system can run in one process with simulated clock, network, disk and
scheduler, replayable from a seed. Every source of non-determinism gets a production and a
simulated implementation; a random failure is worthless if it does not replay. Aria's team ranks
its simulated network, which can delay and drop packets and control time, as its most valuable
test layer
([tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md)).
In OCaml the entry point is `Async.Time_source`: code that takes a time source can be driven by a
synthetic clock in tests
([developer education](../janestreet/blog/2024-10-developer-education-at-jane-street.md)).
Algebraic effects make lockstep multi-actor simulations read as straight-line code
([effects in Hardcaml](../janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md)).

A deterministic engine plus an input log gives exact reproduction: replay the inputs into a
fresh engine and diff the outputs
([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md),
[how to build an exchange](../janestreet/blog/2017-01-how-to-build-an-exchange.md),
[interns 2024](../janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md)).
Antithesis takes determinism down to a hypervisor, so unmodified containers can be explored,
rewound and fault-injected; on Aria, which already had careful simulation, it still found two
unknown bugs on its first run, one from a snapshot restart that served zero bytes instead of an
error. Failure paths can also be forced cheaply without the platform: capped FD limits, an
`LD_PRELOAD` shim that fails `bind`, or an Async pool pinned to one thread reproduced a decade-old
crash and a socket leak
([network maintenance bugs](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md)).

## Fakes and simulators that misbehave on purpose

A fake that always behaves well hides caller bugs. Bugification makes code take its worst
allowed path with low probability in tests, so callers stop relying on behaviour the contract
does not promise ([episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md)).
Latency is the clearest case: reply and retry matching bugs appear only when answers are slow,
and simulators answer instantly
([Higgs bugson](../janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md)).

Simulators sharing one engine also risk erasing venue differences: the same order flag can mean
different things per venue, so each simulator should pin its venue's documented behaviour
([TDOE interns 2026](../janestreet/blog/2026-09-tdoe-intern-projects-2026.md)), while adapters
over one engine should still agree on fills for the same normalized orders
([interns 2020](../janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md)). For
strategy work, a single simulator configuration invites overfitting; randomizing its parameters
per run guards against it ([AAAI-19](../janestreet/blog/2019-05-thoughts-from-aaai-19.md)). And
random-walk noise traders lack the lumpiness of real flow (pennying, bursts, price clustering),
which cheap statistics such as trade share and inter-arrival histograms can measure against live
data
([autoregressive diffusion](../janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md)).

## Recorded traffic as fixtures

Real venues send things hand-written samples never contain. Captured traffic is the best codec
test data, and record/replay modes make data-dependent code cheap to test against reality
([depot FUSE](../janestreet/blog/2026-10-linux-engineering-depot-fuse.md),
[interns 2021](../janestreet/blog/2021-08-what-the-interns-have-wrought-2021.md),
[interns 2022](../janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md)). Committed
expect tests over real captures turn one-off exploration into rerunnable checks
([repeatable exploratory programming](../janestreet/blog/2018-04-repeatable-exploratory-programming.md)),
and swappable transport lets parsing run on recorded bytes without sockets
([episode 12](../janestreet/podcast/12-what-is-an-operating-system.md)). Diffing against an
independent reference implementation, such as a signature vector from a venue's official SDK,
finds bugs on both sides
([interns 2019](../janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md)). Because our
strategy is pure OCaml, the same strategy code can be driven from recorded data in tests rather
than ported from a research toolset
([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md)). Version-skew tests are
the time-shifted version: keep a file written by today's code and make every future version read
it ([tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md)).

## Shadow and parallel runs

Before switching, run old and new on identical input and diff the outputs. The Windows config
orchestrator ran in audit mode beside the old system, both emitting typed decisions with reasons,
and the diffs exposed bugs in both
([config orchestrator](../janestreet/blog/2026-10-config-management-orchestrator-for-windows.md)).
The email-server rewrite did the same
([episode 8](../janestreet/podcast/08-building-a-functional-email-server.md)). For us the
analogue is a shadow strategy: a second parameter set on the same feed that only logs plans and
counts divergences, and the offline version of that, the same scripted sequence under two
`Params` with only the differing plans printed. The same applies to derived data: diff the
day-close tables of two revisions before replacing one.

## Whole-system runs, chaos and scheduled e2e

Antithesis needs only container images, a compose file and a folder of executable actions a user
or admin might take
([tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md));
we can build that layout locally and gain a chaos test even without the platform. Broken
non-production copies are the best incident training, and our simulators make one cheap
([episode 20](../janestreet/podcast/20-solving-puzzles-in-production.md)). Whole-pipeline tests
run in code replaced manual diffing and enabled frequent releases
([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md)), while a
miscompilation was caught only by a rarely run test
([episode 4](../janestreet/podcast/04-compiler-optimization.md)): end-to-end checks have to run
on a schedule, not by hand. Scripts that only print evidence pass when nothing happened
([when bash scripts bite](../janestreet/blog/2017-05-when-bash-scripts-bite.md)). Testing at the
maximum input rate shows where a system falls behind, and a realistic testbed that answers in
minutes speeds performance work
([episode 1](../janestreet/podcast/01-programmable-hardware.md),
[episode 18](../janestreet/podcast/18-performance-engineering-on-hard-mode.md)). Recording which
commit of every repository was under test makes a failing multi-repo run reproducible
([release process](../janestreet/blog/2014-06-ironing-out-your-release-process.md)).

## Test-first bug fixes and agents that game tests

In the Iron style, a bug fix arrives as two changes: first a test that exhibits the bug, then the
fix that changes its output
([Iron development style](../janestreet/blog/2017-08-ironing-out-your-development-style.md)).
This matters more with agents. Put in a loop with a strict validator, a model drifts toward
gaming it, deleting tests or making them pass trivially
([episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md)). The defences
are cheap conventions: a commit that removes a test or accepts changed expect output says why,
shrunk counterexamples are pinned in the same commit as the fix
([episode 23](../janestreet/podcast/23-building-tools-for-traders.md)), and public interface
changes carry a contract property
([episode 16](../janestreet/podcast/16-future-of-programming.md)).

## Where we stand

- [exchange-core](../../repos/exchange-core.md): the engine is deterministic (caller-advanced
  `step ~now`, sequential ids, seeded `Market_sim`). One Quickcheck property drives random
  place/cancel flow over three accounts and checks book invariants, value conservation and that
  open orders match the book. It does not include `step` or `set_mark`, check net position or id
  uniqueness, or compare two engines; there is no input journal.
- [order-book](../../repos/order-book.md): a 500-trial property runs random limit, market and
  cancel sequences and checks invariants, fill accounting and that cancelling everything empties
  the book. There is no reference matcher and no pinned `~examples`.
- [mm-core](../../repos/mm-core.md): `test_properties.ml` checks over single random snapshots that
  quotes never cross or exceed `max_position`, and that reconciling a ladder against itself is a
  no-op. The `Live` test uses an in-memory venue that rests every order and cancels on request:
  an always-well-behaved fake, running on the wall clock.
- [venue-net](../../repos/venue-net.md): `Ws_client` keepalive and reconnect delay use
  `Clock_ns` directly, so reconnect logic cannot be driven by a synthetic clock.
- [fixed-decimal](../../repos/fixed-decimal.md): expect tests only; `mul_units`, `div_units` and
  `Product` have no property test against an exact model.
- [market-data](../../repos/market-data.md): `Merge` and candle aggregation have Quickcheck
  properties, `Stable.V1` bin shapes are pinned, and `Replay_feed` already takes a time source.
  No checked-in event log guards version skew.
- Protocol and client repos ([hl-protocol](../../repos/hl-protocol.md),
  [hl-client](../../repos/hl-client.md), [binance-client](../../repos/binance-client.md) and
  peers) test against hand-written samples; no recorded venue frames are checked in, although
  [market-recorder](../../repos/market-recorder.md) stores them verbatim.
- End-to-end scripts exist (`scripts/e2e-all.sh` in [market-maker](../../repos/market-maker.md),
  `scripts/e2e.sh` in [hl-mm](../../repos/hl-mm.md), `scripts/e2e-sims.sh` in market-recorder)
  but no CI workflow runs them, and `e2e-sims.sh` prints files and metrics without failing when
  none were written.
- [infra](../../repos/infra.md) has a compose stack with the three simulators but no action
  scripts or fault injection. The simulators ([hl-sim](../../repos/hl-sim.md) and peers) answer
  immediately and share engine semantics, see [simulators](../../design/simulators.md).

## Proposed actions

1. Add a seeded bugify mode to the in-memory `Venue.S` used by `Live` tests: random rejects,
   delayed cancel acks, fills split in parts, an occasional stale open-orders poll.
   [mm-core](../../repos/mm-core.md);
   [episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md).
2. Thread a `Time_source.t` through `Live.Make`, then add a Quickcheck test feeding random
   book, fill and open-order event sequences through it, asserting uncrossed ordered quotes and
   the position limit, printing the seed on failure. [mm-core](../../repos/mm-core.md);
   [episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md),
   [interns 2025](../janestreet/blog/2025-08-wrought-2025.md),
   [developer education](../janestreet/blog/2024-10-developer-education-at-jane-street.md).
3. Add `?time_source` to `Ws_client` backoff and keepalive watchdog, with a synthetic-clock
   reconnect expect test and a test against a listener that never completes the handshake
   (timeout fires, FD count restored). [venue-net](../../repos/venue-net.md);
   [tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md),
   [network maintenance bugs](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md).
4. Add a bisimulation property comparing `Order_book` fills with a naive sorted-list matcher on
   random operation sequences, with prices drawn mostly within 3 ticks of mid.
   [order-book](../../repos/order-book.md);
   [interns 2020](../janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md),
   [interns 2022](../janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md),
   [Quickcheck for Core](../janestreet/blog/2015-10-quickcheck-for-core.md).
5. Extend the engine's random-flow property with `step` and `set_mark` operations and assert
   zero net position across accounts and unique order ids; add a two-engine test that feeds
   identical seeded input and compares event streams. [exchange-core](../../repos/exchange-core.md);
   [episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md),
   [how to build an exchange](../janestreet/blog/2017-01-how-to-build-an-exchange.md).
6. Record an input journal (place, cancel, modify, step, set_mark) in the engine and log accepted
   `/exchange` requests in hl-sim; test that replay into a fresh engine reproduces
   `drain_events` and fills. [exchange-core](../../repos/exchange-core.md),
   [hl-sim](../../repos/hl-sim.md);
   [episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md),
   [interns 2024](../janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md).
7. Check a trimmed recorded raw minute file into each protocol repo with an expect test decoding
   every frame and printing counts per channel and errors. [hl-protocol](../../repos/hl-protocol.md),
   [binance-protocol](../../repos/binance-protocol.md), [bybit-protocol](../../repos/bybit-protocol.md);
   [depot FUSE](../janestreet/blog/2026-10-linux-engineering-depot-fuse.md),
   [repeatable exploratory programming](../janestreet/blog/2018-04-repeatable-exploratory-programming.md).
8. Feed the same recorded fixtures through each client's `Live_feed` normalizer (and Binance's
   `Feed_normalizer` plus `Local_book`), printing per-stream counts.
   [hl-client](../../repos/hl-client.md), [binance-client](../../repos/binance-client.md),
   [bybit-client](../../repos/bybit-client.md);
   [interns 2021](../janestreet/blog/2021-08-what-the-interns-have-wrought-2021.md),
   [episode 12](../janestreet/podcast/12-what-is-an-operating-system.md),
   [the joy of expect tests](../janestreet/blog/2023-01-the-joy-of-expect-tests.md).
9. Add a Quickcheck property comparing `mul_units`, `div_units` and `Product.mul` against a
   Bigint reference, with generators biased to the 63-bit range ends.
   [fixed-decimal](../../repos/fixed-decimal.md);
   [Quickcheck for Core](../janestreet/blog/2015-10-quickcheck-for-core.md),
   [Z3 proofs and refutations](../janestreet/blog/2018-02-proofs-and-refutations-using-z3.md).
10. Make `e2e-sims.sh` exit non-zero when no raw `.zst` files were written or an alert condition
    holds (empty closed minute file, `recv_ts` decreasing in a file), then run it in CI.
    [market-recorder](../../repos/market-recorder.md);
    [when bash scripts bite](../janestreet/blog/2017-05-when-bash-scripts-bite.md),
    [episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md),
    [episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md).
11. Add a weekly scheduled CI workflow running `scripts/e2e-all.sh`, which first prints every
    sibling repository's HEAD. [market-maker](../../repos/market-maker.md);
    [episode 4](../janestreet/podcast/04-compiler-optimization.md),
    [release process](../janestreet/blog/2014-06-ironing-out-your-release-process.md).
12. Add a fault phase to `e2e-all.sh` that restarts the simulator mid-run and checks reconnect,
    book resync and resumed quoting. [market-maker](../../repos/market-maker.md);
    [episode 20](../janestreet/podcast/20-solving-puzzles-in-production.md).
13. Add a `test-actions/` directory of executable scripts (place and cancel against a simulator,
    kill and restart the recorder, cut one container's network) runnable against the compose
    stack, as a local chaos test and an Antithesis-ready layout. [infra](../../repos/infra.md);
    [tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md).
14. Add skill rules and a GOTCHAS entry: bug fixes land as a failing test then the fix; commits
    removing tests or accepting changed expect output say why; shrunk counterexamples go into
    `~examples` with the fix; public `.mli` changes carry a contract property.
    [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md);
    [Iron development style](../janestreet/blog/2017-08-ironing-out-your-development-style.md),
    [episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md),
    [episode 23](../janestreet/podcast/23-building-tools-for-traders.md),
    [episode 16](../janestreet/podcast/16-future-of-programming.md).
15. Pin existing property counterexamples, starting with a multi-level sweep, via `~examples` in
    the order-book properties, and add a byte-string fuzz property mapping bytes to operations.
    [order-book](../../repos/order-book.md);
    [episode 23](../janestreet/podcast/23-building-tools-for-traders.md),
    [tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md),
    [formal methods](../janestreet/blog/2026-06-formal-methods-at-jane-street.md).
16. Check in an event log written by current code and test that every later version reads it;
    derive Quickcheck generators on `Stable.V1` records for bin_io round trips; add a property
    that random `Framed` buffer and flush sizes give identical read-back.
    [market-data](../../repos/market-data.md);
    [tested to battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md),
    [Quickcheck for Core](../janestreet/blog/2015-10-quickcheck-for-core.md),
    [Aria benchmarking](../janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md).
17. Add an expect test driving `Strategy` from `Replay_feed` over a fixture event log and printing
    quotes, plus one running the same scripted sequence under two `Params` printing only differing
    plans. [mm-core](../../repos/mm-core.md), [market-data](../../repos/market-data.md);
    [episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md),
    [config orchestrator](../janestreet/blog/2026-10-config-management-orchestrator-for-windows.md).
18. Add `-shadow-params FILE` to run a second strategy on the live feed that only logs plans and
    counts divergences. [market-maker](../../repos/market-maker.md);
    [episode 8](../janestreet/podcast/08-building-a-functional-email-server.md).
19. Add `-response-delay-ms` to hl-sim and run the hl-mm live-loop test under it.
    [hl-sim](../../repos/hl-sim.md), [hl-mm](../../repos/hl-mm.md);
    [Higgs bugson](../janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md).
20. Add per-venue simulator expect tests pinning documented behaviour, starting with a crossing
    post-only order, and a script sending one order sequence to hl-sim and binance-sim with noise
    off and diffing normalized fills. [hl-sim](../../repos/hl-sim.md),
    [binance-sim](../../repos/binance-sim.md), [bybit-sim](../../repos/bybit-sim.md);
    [TDOE interns 2026](../janestreet/blog/2026-09-tdoe-intern-projects-2026.md),
    [interns 2020](../janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md).
21. Add HTTP record mode to the client transport saving request and response fixtures, and check
    in recorded `l2Book` and `clearinghouseState` responses with decode expect tests.
    [venue-net](../../repos/venue-net.md), [hl-client](../../repos/hl-client.md),
    [hl-protocol](../../repos/hl-protocol.md);
    [interns 2021](../janestreet/blog/2021-08-what-the-interns-have-wrought-2021.md),
    [interns 2022](../janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md).
22. Add text-trace expect tests: a seeded `Market_sim` printing top 5 levels and positions per
    tick, margin terms around a liquidation, and an mm-core helper printing mid, bid, ask and
    position per step over a scripted price path. [exchange-core](../../repos/exchange-core.md),
    [mm-core](../../repos/mm-core.md);
    [ASCII waveforms](../janestreet/blog/2020-06-using-ascii-waveforms-to-test-hardware-designs.md),
    [episode 1](../janestreet/podcast/01-programmable-hardware.md),
    [self-documenting computations](../janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md).
23. Add `Market_sim.Config.randomize ~seed` drawing volatility and order probabilities from
    ranges, and an option placing a share of noise orders one tick inside the touch.
    [exchange-core](../../repos/exchange-core.md);
    [AAAI-19](../janestreet/blog/2019-05-thoughts-from-aaai-19.md),
    [autoregressive diffusion](../janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md).
24. Write a DuckDB query for trade share and BBO inter-arrival histograms and run it on live
    Hyperliquid and hl-sim hours as a realism check. [market-data](../../repos/market-data.md),
    [hl-sim](../../repos/hl-sim.md);
    [autoregressive diffusion](../janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md).
25. Add `scripts/diff-day-close.sh` diffing day-close tables of two revisions with DuckDB
    `EXCEPT`, and a dune cram test running day-close on a tiny event log.
    [market-data](../../repos/market-data.md);
    [episode 8](../janestreet/podcast/08-building-a-functional-email-server.md),
    [testing with expectations](../janestreet/blog/2015-12-testing-with-expectations.md).
26. Prototype an effects-based lockstep harness where scripted traders and the strategy act per
    round against `Exchange.step`, pinning one fixed-seed run's fills (check OxCaml switch
    support first). [exchange-core](../../repos/exchange-core.md), [mm-core](../../repos/mm-core.md);
    [effects in Hardcaml](../janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md).
27. Add an expect test parsing every file in `examples/` with `Config.of_sexp`, and a
    back-to-back replay load test printing frames per second and maximum queue depth.
    [market-recorder](../../repos/market-recorder.md);
    [episode 8](../janestreet/podcast/08-building-a-functional-email-server.md),
    [episode 1](../janestreet/podcast/01-programmable-hardware.md).
28. Make `e2e-all.sh` print a per-venue tick-to-order latency histogram.
    [market-maker](../../repos/market-maker.md);
    [episode 18](../janestreet/podcast/18-performance-engineering-on-hard-mode.md).
29. When Hyperliquid EIP-712 signing lands, add an expect test checking a fixed order signature
    against a vector from the official Python SDK. [hl-client](../../repos/hl-client.md);
    [interns 2019](../janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md).
30. Prototype a read-only Bonsai_term status screen with one rendered-screen expect test.
    [market-maker](../../repos/market-maker.md);
    [Bonsai_term](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md).
