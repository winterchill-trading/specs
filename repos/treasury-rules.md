# treasury-rules

Policy rules for an organisation's treasury: sweep cash above a threshold, top up a balance
below a floor, convert an asset when there is too much of it, rebalance to target
allocations, keep yield or staking within limits, and hedge a staked position at a ratio.
Each rule is a pure function of a snapshot (balances, prices, recent runs) that proposes
actions with reason codes and evidence. Guards add daily caps per rule and per organisation,
a drawdown pause on a reference price, freshness checks and approval thresholds. Runs are
recorded once per rule and period, and every change lands in an audit trail. The library
never reads a clock, a ledger or a price feed on its own, and never executes an action.

Requires the OxCaml compiler (`5.2.0+ox`).

| | |
| --- | --- |
| Repository | `winterchill-trading/treasury-rules` |
| opam packages | `treasury-rules` (library), `treasury-rules-cli` (command) |
| Library | `treasury-rules` (module `Treasury_rules`) |
| Binary | `treasury-rules` (`check`, `evaluate`, `reason-codes`) |
| Status | done: library, command, example (checked in CI) and property tests are in place |

## Key modules

| Module | Purpose |
| --- | --- |
| `Rule`, `Rule_id` | Rules with validation and an active, paused, archived lifecycle |
| `Action`, `Hit`, `Reason_code` | What a rule proposes, the checks that fired, the stable reason codes |
| `Settings` | Caps, freshness limits, approval thresholds |
| `Snapshot`, `Location` | Balances per location, prices and recent runs at one instant |
| `Evaluate` | `evaluate`: the pure decision |
| `Outcome` | Actions, hits and route; `to_decision` gives a `Risk_rules.Decision.t` |
| `Mode`, `Cadence` | Live, shadow and dry-run; periods aligned to the epoch in UTC |
| `Run_key`, `Run_record` | One run per rule and period; the state machine of a run |
| `Runner` | Ticks and previews over a `Store.S`: create rules, tick, `executed`, `failed` |
| `Audit` | Append-only trail: who, when, which rule, what happened |
| `Store`, `Store_memory`, `Store_conformance` | Persistence as a module type, an in-memory store and the conformance suite |

## Rules

| Kind | Proposes | Skips with |
| --- | --- | --- |
| `Sweep` | a transfer of everything above `threshold` | `BELOW_THRESHOLD`, `BELOW_MINIMUM` |
| `Top_up` | a transfer that refills a balance below `floor` up to `target`, limited by the source | `FLOOR_MET`, `INSUFFICIENT_BALANCE`, `BELOW_MINIMUM` |
| `Convert` | a conversion of the excess above `threshold` into `buy`, capped by `max_per_run`, estimated at the fresh rate rounded down | `BELOW_THRESHOLD`, `BELOW_MINIMUM`, `PRICE_UNAVAILABLE` |
| `Rebalance` | transfers or conversions from overweight to underweight legs, back to the exact weights, once a leg drifts outside `band_bps` | `WITHIN_BAND`, `BELOW_MINIMUM` |
| `Yield` | a subscription of cash above `buffer` up to `max_share_bps` of cash plus fund; a redemption when cash falls below the buffer or the share is exceeded | `BELOW_BUFFER`, `ALLOCATION_LIMIT_REACHED`, `BELOW_MINIMUM` |
| `Hedge` | an order that brings a short position to `ratio_bps` of the staked amount, never beyond `max_position` | `WITHIN_BAND`, `POSITION_LIMIT_REACHED`, `BELOW_MINIMUM` |

`Evaluate.evaluate` checks, in order, and the first failing guard is the only `Block` hit:

1. the rule is active (`RULE_INACTIVE`);
2. the snapshot is fresh (`SNAPSHOT_STALE`);
3. no earlier run of the rule is awaiting approval or execution (`PREVIOUS_PENDING`);
4. the drawdown guard: the reference price is not more than `max_drawdown_bps` below its peak
   over `lookback` (`DRAWDOWN_PAUSE`);
5. the kind's own logic, with fresh prices only (`PRICE_UNAVAILABLE`);
6. the rule's daily cap, then the organisation's, over today's committed runs (UTC): actions
   are cut to what is left (`DAILY_CAP_APPLIED`) or the run stops (`RULE_DAILY_CAP_REACHED`,
   `ORG_DAILY_CAP_REACHED`);
7. routing: `MANUAL_EXECUTION` when automatic execution is off, `APPROVAL_REQUIRED` when an
   action's value is above the rule's threshold.

The route is derived from the hits: any `Block` hit (or no action) is `Skip`, any `Review` hit
is `Approve`, otherwise `Execute`.

Modes:

- `Live`: runs are recorded, and actions go to approval or to execution.
- `Shadow`: runs are recorded with their actions but nothing executes, and nothing counts
  against the organisation's cap. A shadow rule shows what the live rule would have done.
- `Dry_run`: the scheduler skips the rule; `Runner.preview` evaluates any rule on demand and
  records nothing. New rules start here.

Runs happen exactly once per period. The runner claims the run key in the store before
evaluating; a second tick in the same period gets the existing record back. A claim still
`Evaluating` after `stale_claim_after` belonged to a crashed runner and is taken over under
the same key, and the late writer loses its compare-and-set. Action keys are stable across
attempts, for use as idempotency keys with the rails.

```
Evaluating -> Skipped | Shadowed | Awaiting_approval | Awaiting_execution | Failed
Awaiting_approval -> Awaiting_execution | Rejected
Awaiting_execution -> Executed | Failed
```

A service reads runs awaiting execution, carries out their actions, and reports
`Runner.executed` or `Runner.failed`.

## Command line

```sh
treasury-rules check -currency HYPE:8 -rules examples/rules.sexp
treasury-rules evaluate -currency HYPE:8 -rules examples/rules.sexp \
  -snapshot examples/snapshot.sexp -settings examples/settings.sexp -evidence
treasury-rules reason-codes
```

`-currency CODE:DIGITS` registers a token that money does not know. Errors exit with code 2.

## Stable types

`Rule_id`, `Location`, `Reason_code`, `Mode`, `Cadence`, `Run_key`, `Action`, `Hit`, `Rule`,
`Settings`, `Outcome`, `Run_record`, `Snapshot` and `Audit` have `Stable.V1` bin_io and sexp
forms with digests pinned in `test/test_stable.ml`. Readers of `Rule`, `Outcome` and
`Run_record` validate: a stored rule that fails validation, an outcome whose route disagrees
with its hits, or a run record whose status disagrees with its outcome is refused on read.

## Tests

- Expect tests per rule kind and per guard; `test/cli.t` for the command.
- Base_quickcheck properties (`base_quickcheck` is a test dependency).
- `examples/quick_start.ml` is built and its output compared with `examples/quick_start.expected`.
- `Store_conformance` is the suite a database implementation runs in its own tests.

## Dependencies

- Depends on: [money](money.md), [risk-rules](risk-rules.md) (outcome shapes: severity,
  reason codes, hits). External: `core`, `core_unix` (command), `ppx_jane`, `zarith`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `money`, `ledger`, `payments-core`, `risk-rules`. CI pins each from GitHub,
then runs `dune build`, `dune test`, the examples and the API docs build. The library
itself needs only `money` and `risk-rules`.

## Known gaps

- Caps across rules hold when one runner at a time ticks an organisation; two concurrent
  runners can each miss the other's run of the same instant.
- Days for caps are UTC days, and a run counts on the day its period starts.
- Execution status is per run, not per action; a partial failure is a failed run.
- Conversion and rebalance estimates ignore fees and slippage; hedges do not size margin.
- A pending run blocks later runs of the same rule; there is no "superseded" state.
