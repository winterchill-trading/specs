# Getting from tested to battle-tested

- Source: <https://blog.janestreet.com/getting-from-tested-to-battle-tested/>
- Published: 2025-12-03
- Kind: blog post

## Summary

- Tests document intent, record past mistakes and support refactoring, but are always an
  approximation of a chaotic real world (unpredictable users, network blips, host
  reboots). Becoming "battle-tested" means surviving that chaos.
- Context: Aria, the firm's low-latency shared message bus with strong ordering and
  reliability guarantees, used as a platform by teams with strict uptime needs. As adoption
  grows, every quiet week becomes an obligation while the system must keep changing.
- Aria's existing toolbox: unit tests of side-effect-free modules and small state
  machines; integration tests over a simulated network that can delay and drop packets and
  control time; quickcheck tests generating random event orderings for the simulation.
- Also: version-skew tests (new clients with old servers and the reverse); AFL fuzzing
  that turns fuzzer bytes into state updates for performance-optimized state machines;
  nightly lab performance tests in a production-like environment; and chaos testing in
  staging with production-like load and random restarts.
- The simulated network matters most: fast, deterministic tests without heavy mocking,
  deep introspection, no flakiness, the whole suite in every build, and easy reproduction
  tests for bug fixes. Production incidents are rare despite weekly releases, yet escaped
  bugs are always "cases nobody thought to test".
- Antithesis runs the whole system in a VM under a deterministic hypervisor, injects
  scheduling and network faults, and explores scenarios; the system needs no changes and
  runs with its real network, filesystem and shared memory, driven by real client code.
- Its interface: Docker images plus a compose file that it brings up inside the VM, and a
  directory of executables, each performing an action a user or admin might take, which
  the platform decides when to run.
- The exploration engine is what makes the huge state space tractable: determinism allows
  rewinding to earlier states and, guided by coverage feedback, spending more effort around
  rare states.
- The trial found two unknown bugs on the first run, one introduced a month earlier and
  likely to hit production with serious effect; the failure mode had been considered in
  design, but a simple coding bug slipped in without a test.
- Example bug from a nightly run: a replicator crashed on a malformed message of zero
  bytes. Antithesis's tooling showed the failure became likely about six seconds earlier,
  when a fault injector killed a tip-retransmitter that then restarted from a snapshot.
- Rewinding one second before the crash and running tcpdump inside the VM from a
  notebook-like debugger showed the client asking for a byte offset (313,425) earlier than
  the snapshot's start (315,567); the server should have returned an error.
- Root cause: the ring-buffer validity check assumed a buffer that started from the
  beginning. It only failed after a snapshot restart, before the ring filled, for requests
  older than the snapshot, and then served zero bytes from an empty region.
- The code predated snapshots and had run for years; local clients' service discovery
  avoided servers started from later snapshots, masking it, while the new cross-region
  feature's clients had to connect optimistically. Reusing existing code meant nobody wrote
  a new test.
- Antithesis complements rather than replaces the other tests, and the team now takes on
  more ambitious changes. Next targets: a new distributed object store, systems without
  mockable network and time layers, and systems wrapping external software.
- The firm sees it as feedback for agentic coding (both using and training agents) and
  led Antithesis's funding round.

## Relevance to us

- **Testing and simulation:** a whole-system test platform only needs container images, a
  compose file and a folder of action scripts, which [infra](../../../repos/infra.md)
  already half provides. **Action:** add a `test-actions/` directory to `infra` with
  executable scripts (place and cancel orders against a simulator, kill and restart
  `market-recorder`, stop the network of one container) runnable against the compose stack,
  as a local chaos test and an Antithesis-ready layout.
- **Logs and state machines:** the bug was a server answering a request for data older
  than its snapshot with garbage instead of an error. **Action:** in
  [market-data](../../../repos/market-data.md), make `Replay_feed` (and later the replay
  server on the [roadmap](../../../roadmap.md)) return an explicit error when the
  requested date range has no event log files, with an expect test.
- **Testing and simulation:** version-skew tests catch incompatible changes between
  writers and readers. **Action:** in [market-data](../../../repos/market-data.md), check in
  a small event log file written by the current code and add a test that every future
  version still reads it, alongside the existing bin-shape pins.
- **Testing and simulation:** fuzzing that maps arbitrary bytes to state-machine inputs
  finds unsafe states in optimized code. **Action:** add a Base_quickcheck test in
  [order-book](../../../repos/order-book.md) that turns a random byte string into submit,
  cancel and market operations and runs the invariant check after each.
- **Testing and simulation:** deterministic network and time simulation is the most
  valuable layer. **Action:** add a `Time_source` parameter to the
  [venue-net](../../../repos/venue-net.md) `Ws_client` backoff and watchdog so reconnect
  logic can be tested with a synthetic clock in an expect test.

Tags: `testing`, `simulation`, `property-testing`, `state-machines`, `sequencer`
