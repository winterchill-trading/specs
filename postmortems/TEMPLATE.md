# YYYY-MM-DD: short title

Copy this file to `postmortems/YYYY-MM-DD-short-title.md` (the date the incident started,
UTC) and replace every section. Postmortems are blameless: they describe what systems and
procedures did, not who made a mistake, and name roles (recorder operator, on-call) rather
than people.

- **Status:** draft | reviewed | actions done
- **Severity:** data loss | degraded | near miss
- **Repositories:** the `repos/` pages of the repositories involved
- **Duration:** first bad minute to recovery, UTC

## Summary

Two or three sentences: what broke, what it affected, how it was fixed.

## Impact

What was lost or wrong, measured: venues, streams and symbols affected; minutes of raw
data missing; derived tables rebuilt; orders or positions affected. Say how the numbers
were obtained (a query from [design/queries.md](../design/queries.md), a `/metrics`
series, a log search).

## Timeline

All times UTC. Include when the problem started, when it was first visible in a signal
(alert, `/healthz`, a gap in a query), when someone noticed, each action taken and its
effect, and recovery.

| Time | Event |
| --- | --- |
| HH:MM | |

## Detection

Which signal showed the problem first, and which should have. If nobody acted on an alert,
say why (noise, flapping, no owner).

## Causes

The chain of causes, each one checkable in code, configuration or logs. Link commits and
files. Include contributing factors (missing test, missing metric, unwritten procedure).

## What went well

Signals, tools or procedures that limited the impact and are worth keeping.

## Actions

Each action is concrete, has a repository and is tracked to done: a test, a metric, a
runbook step, a design change. Add the open ones to [roadmap.md](../roadmap.md) and link
the commit or ADR when done.

| Action | Repository | Status |
| --- | --- | --- |
| | | planned |

## Specs updates

Pages of this repository changed because of the incident (failure tables, designs,
ADRs).
