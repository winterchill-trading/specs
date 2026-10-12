# Building and testing a config management orchestrator for Windows

- Source: <https://blog.janestreet.com/config-management-orchestrator-for-windows/>
- Published: 2026-10-06
- Kind: blog post

## Summary

- Intern project: Windows hosts were configured by a scheduled PowerShell task that parsed
  JSON meta-config (applicability by hostname regex, AD group or department, schedules,
  and dev/beta/staging phasing) and ran config scripts in-process on every machine.
- Problems: management and execution mixed in one single-threaded process (a config that
  spawned a thread hung the whole run), only JSON-schema level typing, and per-host
  applicability checks loaded external systems.
- The decision logic moved into an OCaml parser inside an existing rollout service
  (Orchestrator) that polls the meta-config; hosts run a stateless F# agent that talks to
  it over RPC and reports through the central observability stack.
- Centralizing turned health checks into one server query ("which hosts have not checked
  in recently?").
- Cutover safety came from an "audit mode": the new client shadows the old system, feeds
  the server the old run's outcomes, asks what the new logic would have done, and logs
  drift as include/exclude decisions with a typed reason.
- The decision diff found real bugs in the old system (wrong overnight schedule windows,
  missed test-mode reruns after a failed apply), which were fixed in place; some old bugs
  were deliberately kept in the rewrite to avoid behavior changes.
- Migration is per config script: the old system skips scripts assigned to the new one.

## Relevance to us

- The shadow-and-diff cutover pattern fits [market-maker](../../../repos/market-maker.md):
  a new quoting or reconciliation rule can run beside the current one and log decision
  drift before it is allowed to send orders.
- Typed decision reasons (an enum per include/exclude) are a cheap way to make
  [mm-core](../../../repos/mm-core.md) reconciler output diffable.
- **Action:** in `mm-core`, add a ppx_expect test that runs two reconciler configurations
  over the same recorded quote sequence and prints only the actions where they differ.

Tags: `ops`, `testing`, `deployment`, `ocaml-practice`
