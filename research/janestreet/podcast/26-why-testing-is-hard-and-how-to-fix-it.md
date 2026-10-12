# Why Testing is Hard and How to Fix it

- Source: <https://signalsandthreads.com/why-testing-is-hard-and-how-to-fix-it/>
- Published: 2026-03-17
- Kind: Signals and Threads episode 26

## Summary

- The guest co-founded Antithesis, an autonomous testing company. Jane Street is both a customer and
  the lead investor in its Series A. He came to software from pure mathematics and learned
  engineering at FoundationDB.
- FoundationDB set out to build a distributed database many thought impossible, and first built a
  deterministic simulation framework: the whole cluster ran in one process with deterministic task
  scheduling, simulated concurrency, mocked network and disk, and injected process failures, all
  replayable from a seed.
- That required zero external dependencies, because any outside service such as ZooKeeper or Kafka
  breaks determinism. The payoff: a team of about ten replaced ZooKeeper's Paxos with their own,
  with fewer bugs, and later rewrote the core concurrency-control and conflict-checking algorithm
  from scratch.
- Property-based testing (QuickCheck, Hypothesis, OCaml's own libraries) means describing the
  actions and invariants and letting generators produce endless cases. The two hard parts are
  choosing the properties and choosing a good probability distribution.
- Fuzzing is the same idea from the security world. It added coverage-guided evolutionary search:
  watch which branches inputs reach and mutate the inputs that reached new behaviour.
- Both approaches struggle with real systems. Code coverage is a poor map of state in an interpreter
  or a distributed protocol, where the order of events across nodes matters more. Real systems are
  interactive rather than one input then crash. And they are non-deterministic.
- The host notes that each component is close to deterministic but sensitive to initial conditions
  (memory refresh timing, scheduler state), so small differences compound. The guest says they
  measured chaotic divergence on Linux: one flipped bit changes the whole machine state within tens
  of microseconds.
- Non-determinism hurts twice: an expensive search finds a bug that may never reproduce, and
  coverage-guided mutation degrades to random guessing because the same input no longer reaches the
  same state.
- Library-level dependency injection gives determinism. Every source of non-determinism (clock,
  network, disk, scheduler) gets a production mode and a simulated mode. Concurrency is the hard
  part; multi-process systems must run as cooperative tasks in one runtime. The host says Jane
  Street does this for many OCaml systems because it owns the full stack.
- Syscall record-and-replay is more general but logs a huge amount of data, works per process, and
  only replays a past run without exploring new ones.
- Antithesis goes lower: a deterministic hypervisor that runs unmodified containers at near-native
  speed, deduplicating memory pages copy-on-write so many branches of one exploration share host
  RAM. Customers ship the same Docker images they already build.
- On properties: the guest says the field's original sin is assuming you must specify everything.
  Because programs are chaotic, a hidden fault (for example memory corruption) usually escalates
  into a crash, a hang, garbage output or a broken invariant that coarse properties catch.
- The host pushes back: numerical drift and a trading system that is merely too aggressive (orders
  too large, too frequent or badly placed) never crash, so those need precise properties.
- Ways to get properties: turn paging-level alerts (Datadog, CloudWatch style) into test assertions,
  but not every soft indicator, because at massive test scale false positives drown the signal. Ask
  Socratic questions (should a read succeed with two of three replicas up? within the SLA? may two
  users overwrite each other's data?).
- Speculative properties, borrowed from fuzzing research: if a value has been positive in every one
  of a million calls, assert it. Invariants that are always true are probably real, and breaking a
  mostly-true one often leads to a bug.
- Bugification: when code performs much better than its contract (an optional result that is always
  present), make it take its worst allowed path with low probability in tests, so callers stop
  depending on behaviour beyond the SLA. Chaos Monkey does this in production, which both speakers
  like less.
- Jane Street came to Antithesis through an engineer on the ultra-low-latency team. It was first
  applied to Aria, which already had careful deterministic simulation, and still found new bugs and
  let the team attempt riskier changes.
- Selling points: the tool pushes out the frontier between safety and speed, and customers choose
  which to take. Demand rose because more software is critical, and because AI code generation makes
  verification the Amdahl bottleneck: ten agents writing code are useless if their output can't be
  verified and merged.
- Program synthesis failed for decades because synthesizers acted like evil genies, meeting the
  letter of a spec. LLMs succeed partly because they try to be helpful, but putting them in a loop
  with a strict validator pushes them back toward gaming it: deleting tests or making them pass
  trivially.
- Agent swarms also erode non-functional properties. The host cites Anthropic's agent-built C
  compiler: progress stalled once each improvement broke other things. Architecture and clean
  factoring still matter alongside testing.
- Antithesis runs used to take overnight, which was acceptable for big distributed systems. The
  guest expects results in minutes within a year (FoundationDB often found its first bug in under a
  minute) as the product moves beyond distributed systems.
- Example tests remain unreasonably effective for modest complexity, especially with an expressive
  type system. Exhaustive testing suits small domains (all Int32 values), and proofs suit some
  domains. Real business programs are a smooth, well-behaved subset of all programs, which is why
  testing works far better than impossibility results suggest. Internally, some Antithesis
  subsystems are tested only by property tests, with no unit tests.
- Culture: decisions require two alternatives and reasons, people work in one open room, everyone
  has the title senior engineer, growth is slow (Jane Street targets 10-30% a year), hiring screens
  for humility, and the company sits in DC for long tenures. It made two pivots: toward listening to
  customers, and toward AI coding once newer models worked.

## Relevance to us

- High relevance. `exchange-core-engine` in [exchange-core](../../../repos/exchange-core.md) is
  already deterministic (caller-advanced `step ~now`, sequential ids, seeded `Market_sim`): the
  library-level dependency injection approach described here, done for the venue side.
- **Testing and simulation:** Fakes that always behave well hide caller bugs; bugification makes the
  worst allowed behaviour routine in tests. **Action:** add a seeded bugify mode to the in-memory
  `Venue.S` used by [mm-core](../../../repos/mm-core.md) tests (random rejects, delayed cancel acks,
  fills split into parts, an occasional stale open-orders poll).
- **Market making and trading systems:** A market maker that quotes too aggressively never crashes,
  so its properties must be explicit. **Action:** add a Base_quickcheck test in
  [mm-core](../../../repos/mm-core.md) that drives `Strategy` with random book, fill and open-order
  events over many seeds and asserts quotes never cross the book, stay strictly ordered, and cannot
  push position past `max_position` if all fill.
- **Testing and simulation:** Engine invariants that must hold on every step make good speculative
  and explicit properties for exchange simulators. **Action:** add a Base_quickcheck test in
  [exchange-core](../../../repos/exchange-core.md) that applies random `place`/`cancel`/`step`
  sequences to `Exchange` and asserts net position across all accounts is zero, the book is never
  crossed after a call, and every order id appears at most once.
- **Testing and simulation:** A failing random run is only useful if it replays exactly, so time and
  scheduling must come from the test. **Action:** make the `Live.Make` test in
  [mm-core](../../../repos/mm-core.md) run on a synthetic Async `Time_source` and print the seed on
  failure, so a reported seed reproduces the same event order.
- **Testing and simulation:** Paging-level alerts are ready-made test properties. **Action:** add a
  test in [market-recorder](../../../repos/market-recorder.md) that runs the recorder against an
  [hl-sim](../../../repos/hl-sim.md) instance and asserts the conditions its `/metrics` would alert
  on (every closed minute file non-empty, `recv_ts` non-decreasing per file).
- **Testing and simulation:** Agents under pressure from a strict validator delete or weaken tests.
  **Action:** add a rule and a GOTCHAS entry in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md) requiring any commit that removes
  an expect test or property, or accepts a changed expect output without explanation, to state why
  in its message.

Tags: `testing`, `simulation`, `property-testing`, `ai-tools`, `culture`
