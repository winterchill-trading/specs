# Solving Puzzles in Production

- Source: <https://signalsandthreads.com/solving-puzzles-in-production/>
- Published: 2024-10-07
- Kind: Signals and Threads episode 20

## Summary

- Production Engineering at Jane Street is a role built around daytime support during
  trading hours (not overnight on-call): production engineers are first responders to
  alerts and to people reporting odd behaviour.
- Roughly a quarter to a third of the time is spent on rotation. The rest goes on
  projects that reduce future support, from OCaml self-service apps to incident-process
  work. The host compares the role to Google-style SRE.
- Software engineers know a few systems in depth; production engineers hold a working
  model of many systems and how they connect, and work on the same teams alongside SWEs,
  PMs and designers.
- The guest moved from consulting into the role after applying as a software engineer;
  the appeal is the detective work of building a story from evidence, the variety, and
  directly helping a dozen or so people a day.
- The guest's team owns the post-trade pipeline: ingest the firm's trades, parse,
  normalize and group them, then send them to a historical database, a Kafka topic
  that live P&L and monitoring subscribe to, and the banks that settle them.
- A common issue is a new kind of trade: a combination of fields (booking date,
  counterparty, settlement system and so on) never seen before has no path through the
  configuration. Operations makes the business decision; the team encodes it and is
  working on making that self-service.
- Incident example: someone booked trades with hand-edited identifiers, the system tried
  to raise errors on them, and the error-raising code itself crashed, taking the pipeline
  down. An existing tool that removes specific trades from the live stream got it
  running again.
- Urgency depends on the layer. Order engines, which translate internal orders into each
  venue's protocol, are in the live trading path, and an outage there costs mostly
  opportunity. Post-trade can be fixed by end of day. Monitoring sits between: trading
  without it is unsafe.
- The firm's alerting system, Oculus, raises discrete pages into a workflow view. The guest
  joined its team to add snoozing; production engineers then built stateful auto-actions
  on top of its auto-act feature, and a newer feature jumps from a page to the source line
  that raised it.
- Many alerts come from inside an application's own logic (an unexpected branch) rather
  than from external rules over exported metrics, so fixing one often means changing the
  application. Metrics-based alerting is growing.
- A tool built this year analyzes a team's alert history. Noise markers: transient
  alerts that open and close with nobody acting, alerts routinely snoozed, and alerts
  forwarded to someone else who should have received them directly. Each action other
  than own-and-resolve is a hint the alert is wrong.
- Engineers should resist clearing the screen (the host's "win the video game"
  worry) and ask after each issue: did it need to fire, can impact be reduced, can the
  alert be clearer, can the fix be automated.
- Automation that filters alerts is correctness-critical: under-filtering trains people
  to ignore alerts, over-filtering hides real problems silently. Applications commonly
  expose internal state through command-line tools, which makes automation easy;
  end-of-day support summaries feed the improvement backlog.
- Debugging used to mean SSH-ing to boxes and reading log files, often in S-expressions;
  centralized log management arrived in the last two years, with an observability team
  adding distributed tracing, alongside long-standing nanosecond-accurate packet captures.
- Migrating to new libraries stalls on long tails; the host argues for migrating eagerly,
  since a few systems left on the forgotten old way add risk.
- Culture: report your own mistakes immediately and without blame. Postmortems record a
  timestamped timeline, causes, resolution and concrete process and technical actions.
- Templates help first-time postmortem writers but can crowd out the big-picture
  synthesis; team discussions after incidents matter as much as the document.
- Training as real incidents become rarer: tabletop incident simulations run like a
  role-playing game, cooperative games played under pressure, broken non-production
  copies of systems to debug (costly, so rare), and an older firm-wide deliberately broken
  training system.
- Onboarding: the OCaml bootcamp plus a production bootcamp and class, then weeks of
  side-by-side support apprenticeship; high-stakes teams such as order engines have
  stricter training.
- Hiring: candidates are often redirected from SWE applications; production interviews
  drop the candidate into code, data and CLI tools to reconstruct a past real incident,
  and interviewers judge the process, not just the answer. Desired traits: communication,
  debugging, carefulness, calm under pressure.

## Relevance to us

- [market-recorder](../../../repos/market-recorder.md) is our closest analogue to the
  normalizing pipeline. Our [market-maker](../../../repos/market-maker.md) adapters play
  the role of order engines, the part where downtime matters most.
- **Logs and state machines:** unexpected input that crashes the error path or vanishes
  silently is the classic pipeline incident, and the recorder spec lists parse errors
  inside the clients as invisible and uncounted. **Action:** surface a per-stream
  parse-error count from each client's `Live_feed` into `Metrics`, with an expect test
  that sends one malformed frame from [hl-sim](../../../repos/hl-sim.md) and checks the
  counter rises and recording continues, in
  [market-recorder](../../../repos/market-recorder.md).
- **Data platform:** being able to pull specific bad records out of a stream turned a
  crash into a quick recovery. **Action:** give the planned raw-to-norm tool (see
  [roadmap](../../../roadmap.md)) a skip-list option of raw file and line numbers to
  exclude when rebuilding `norm/`, in [market-data](../../../repos/market-data.md).
- **Build and deploy:** flickering alerts (opening and closing with no action) are the
  main noise signal. **Action:** count `/healthz` transitions between 200 and 503 per
  stream as a `healthz_flaps_total` counter in `Metrics`, so a flapping stream shows up
  before the alert is tuned, in [market-recorder](../../../repos/market-recorder.md).
- **OCaml practice:** jumping from an alert straight to the code that raised it saves the
  first minutes of every incident. **Action:** include `[%here]` source positions in the
  error and warning logs of `Raw_writer` and `Uploader` in
  [market-recorder](../../../repos/market-recorder.md).
- **Build and deploy:** applications that expose their internal state make support
  automation easy. **Action:** add a `GET /status` endpoint to `Http_server` returning a
  sexp of the open minute files and the uploader's pending queue, in
  [market-recorder](../../../repos/market-recorder.md).
- **Testing and simulation:** broken non-production copies of real systems are the best
  incident training, but costly; our simulators make one cheap. **Action:** add a fault
  phase to `scripts/e2e-all.sh` that restarts the simulator mid-run and checks that the
  market maker reconnects, resyncs open orders and keeps quoting, in
  [market-maker](../../../repos/market-maker.md).
- **Build and deploy:** blameless postmortems with timeline and concrete actions turn
  incidents into fixes. **Action:** add a short postmortem template (timeline, impact,
  causes, actions) under a `postmortems/` directory in `specs`.

Tags: `ops`, `observability`, `culture`, `testing`
