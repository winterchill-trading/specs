# scheduler-core

OCaml library for recurring schedules, due dates and exactly-once runs: once, weekly,
fortnightly, monthly and every-N-days recurrences whose dates are computed by index from the
start, a pure schedule state machine, and a runner that claims each (schedule, date) pair in a
pluggable store before calling the job. Any kind of job (standing orders, recurring buys,
payroll runs, reminders) implements one `Job` interface. It deliberately does not persist
anything, does not depend on Async, and does not know about transfers, ledgers or money.

| | |
| --- | --- |
| Repository | `winterchill-trading/scheduler-core` |
| opam package | `scheduler-core` (library) and `scheduler-core-cli` (the command), both from one repository |
| Library | `scheduler-core` (module `Scheduler_core`) |
| Binary | `scheduler-dates` (package `scheduler-core-cli`; prints the dates of a recurrence) |
| Status | done: library, CLI, property tests and examples are in place; version 0.1.0 is prepared for opam, not published |

## Key modules

| Module | Purpose |
| --- | --- |
| `Frequency` | Once, weekly, fortnightly, monthly (optional day of month) and every N days |
| `Recurrence` | Dates by index, end date and maximum count, lookups (`first_index_on_or_after`, `between`) and validation |
| `Clock` | Injected time and zone; `Clock.Manual` for tests; a date is due from midnight in that zone |
| `Schedule` | Pure state machine: `due`, `settle`, `pause`, `resume`, `cancel`, `upcoming` |
| `Schedule_id` | Identifier that refuses malformed text at construction |
| `Run_key`, `Run_record`, `Outcome` | One durable record per (schedule, date): claimed, then finished |
| `Job` | The interface every job implements (`validate`, `run`); `Job.Context` carries the run key, index, attempt and time |
| `Store` | Persistence as a module type; `claim` and `settle_unclaimed` must be atomic per run key |
| `Store_memory` | In-memory store, a functor over the monad and the job |
| `Store_conformance` | Test suite any store implementation runs; `Store_memory` passes the same one |
| `Runner` | `Make (Monad) (Job) (Store)`: `tick`, `add`, `pause`, `resume`, `skip`, `cancel` |

Rules enforced by the library:

- Date `i` comes from the start and the index, never from the previous date, so a monthly
  schedule on 31 January runs on 28 February, 31 March and 30 April without drifting.
- A claim older than two minutes is taken over; the job is called again with the same key,
  which it passes on as its idempotency key. A date that carries a claim is never marked
  missed or skipped and is never resumed past.
- After a gap the passed dates are recorded as missed and only the latest runs, or, per
  schedule, every passed date runs in order.
- Three failed dates in a row (configurable) pause the schedule with the reason. Resuming
  continues from the first date on or after today.
- Persisted types have `Stable.V1` bin_prot and sexp forms with pinned digests; reading
  validates.

## Tests

- `dune test`: expect tests for dates, transitions, and the runner around crashes, gaps and
  failures; `Stable` digests pinned in `test_stable.ml`; a cram test for the CLI.
- Store conformance run against `Store_memory`.
- Quickcheck properties: dates strictly increase and respect their bounds, monthly dates
  depend only on their index, the arithmetic index lookups agree with a scan, due dates are
  contiguous, and two runners sharing a store with random clock jumps, crashes, pauses,
  resumes and skips never run a date's first attempt twice and never record a missed or
  skipped date whose job ran.
- `examples/`: `quick_start` and `three_jobs` (output diffed in CI via `@examples/runtest`).

## Dependencies

- Depends on: no org packages. External: `core`, `ppx_jane`; `core_unix` and `base_quickcheck`
  for tests; the CLI package adds `core_unix` and requires `scheduler-core` at the same
  version. Requires the OxCaml compiler.
- Used by: `pots-and-insights`.

## CI pin order

No sibling repositories are pinned. CI uses the shared `ox-setup` action from `infra`, then
runs `dune build`, `dune test` and `dune build @examples/runtest`, and the shared `obj-magic`
workflow.

## Known gaps

- Editing a schedule's recurrence (as opposed to its job parameters) is not modelled; cancel
  and create a new schedule.
- Business-day calendars (move a date off a weekend or holiday) are left to the job or the
  caller.
- No store beyond `Store_memory`: a service implements `Store.S` over its own database and
  runs `Store_conformance` against it.
- Version 0.1.0 is prepared for opam but not published.
