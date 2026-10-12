# Building and testing a config management orchestrator for Windows

- Source: <https://blog.janestreet.com/config-management-orchestrator-for-windows/>
- Published: 2026-10-06
- Kind: blog post

## Summary

- Intern project in Windows engineering. The firm had moved off Group Policy (weak
  alerting, hard to manage as code) to its own framework built on a scheduled PowerShell
  task, which in turn became hard to reason about.
- The unit of configuration is an artifact: a condition ("is this set?") plus an action
  that makes it true, ideally a single registry-style change. Artifacts group into
  parameterized config scripts.
- A JSON meta-config decides applicability (hostname regex, AD group, the user's
  department), scheduling (when a script may run) and phasing (dev, beta, staging groups
  for staged rollouts).
- Previously every host parsed the meta-config itself and ran scripts in the same
  single-threaded PowerShell process. Mixing management and execution caused incidents: one
  config spawned a thread that could never run, hanging the whole loop.
- Other problems: JSON-schema "typing" only, PowerShell's weak type checking, and
  per-host applicability checks that loaded external systems.
- Decision-making moved into an existing internal rollout service (Orchestrator), which
  already has applicability and phasing; an OCaml parser for the meta-config lets it poll
  and store the configuration, including subtle cases such as test-mode runs outside the
  schedule.
- The rewrite found several bugs in the old PowerShell logic; some were deliberately
  reproduced in the new code so the cutover would not change behavior.
- Hosts now run a stateless F# agent that talks to Orchestrator over RPC and reports via
  the central observability stack, so liveness becomes one server-side query for hosts that
  have not checked in recently. Old monitoring stays on in parallel until trust is earned.
- Cutover used an audit mode beside the normal apply mode: the agent tails the old system,
  reports its outcomes to the server as if they were its own (since the next decision
  depends on the previous run's result), asks what the new logic would do, and logs drift.
- Both systems emit decision logs with an include or exclude verdict and a typed reason
  per config. Diffs exposed old-system bugs: wrong handling of overnight schedule windows,
  and failing to keep re-running a failed config in test mode outside its schedule.
- Those bugs were fixed in the old system, so there was no need to rush the migration.
  Migration happens per config script: the old system skips scripts assigned to the new
  one.

## Relevance to us

- **Testing and simulation:** running a new decision engine in shadow beside the old one
  and diffing typed decisions finds bugs in both before cutover. **Action:** add a
  ppx_expect test in [mm-core](../../../repos/mm-core.md) that feeds one scripted
  `Market_state` and fill sequence through `Strategy` under two `Params` values and prints
  only the ticks where the `Action` plans differ.
- **Logs and state machines:** each decision should carry a machine-readable reason so
  logs from two implementations can be diffed line by line. **Action:** in
  [mm-core](../../../repos/mm-core.md), have the `Quoter` return a typed reason (for
  example inventory limit, kill switch, below minimum notional) for each side it leaves
  unquoted, and log it as a sexp.
- **Build and deploy:** a centralized "who has not checked in" view beats probing each
  instance. **Action:** expose a per-stream `last_message_age_seconds` gauge in the
  [market-recorder](../../../repos/market-recorder.md) `/metrics` output, so silent feeds
  show up in one query rather than only as a `/healthz` 503.
- Keeping known old bugs during a rewrite to separate "port" from "behavior change" is a
  useful discipline when porting adapters between venues.

Tags: `ops`, `testing`, `deployment`, `ocaml-practice`
