# pots-and-insights

Savings pots and spending insights for banks, as pure OCaml values over a double-entry ledger.
Pots are owned sub-accounts with an optional goal; money moves as balanced ledger entries under
idempotency keys, and round-ups and scheduled top-ups run as scheduler jobs. Insights categorise
statement items, total each UTC calendar month and track monthly budgets, and return notices as
values. It deliberately persists nothing and performs no I/O: a service stores pots, budgets,
preferences and items itself and appends the returned entries to its own journal.

| | |
| --- | --- |
| Repository | `winterchill-trading/pots-and-insights` |
| opam package | `pots-and-insights` |
| Library | `pots-and-insights` (module `Pots_and_insights`) |
| Binary | `pots-and-insights` (`round-up`, `budget-status`, `categorise`) |
| Status | done: library, CLI, example and tests are in place; changes listed as unreleased |

## Key modules

| Module | Purpose |
| --- | --- |
| `Id`, `Pot_id`, `Owner_id`, `Budget_id`, `Item_id` | Validated caller-chosen identifiers |
| `Pot` | Pot record, editable details, limits (20 open pots, 30-character names), refusals, goal progress |
| `Pot_booking` | Deposit, withdrawal and close entries checked against balances; idempotent replays; movement history |
| `Round_up` | Round-up of a card purchase to a unit, with a multiplier; totals over a period |
| `Top_up` | Fixed scheduled top-ups, optionally capped at the goal |
| `Pot_job` | Top-ups and daily round-up sweeps as `Scheduler_core.Job.S` |
| `Item` | Statement items and their flow (spending, refund, income, internal) |
| `Category`, `Catalogue` | Category codes and the offered set, grouped spending, income and neutral |
| `Keywords` | Whole-word keyword lists that suggest a category |
| `Preferences` | Overrides, merchant rules, payee rules and standing order categories |
| `Categorise` | Assigns categories; recategorises one item, a merchant or a payee |
| `Insights` | A month by category, merchant and money flow, with the month before |
| `Budget`, `Budget_month` | Monthly budgets with amounts over time, under, near and over states, and pace |
| `Notice` | Budget near or over and goal reached, each with a dedupe key |
| `Calendar_month`, `Percentage` | UTC months and exact one-decimal percentages |

Rules worth knowing:

- Periods are UTC calendar months; pace is `amount * day / days`, rounded down.
- Only completed items count. Internal movements (pots, exchanges) are neither spending nor
  income, and refunds follow their purchase into its category.
- Category order: override, merchant rule, standing order, payee rule, keyword, merchant
  category, default. A stored choice whose category was retired is skipped, never an error.
- Budget states: under below 80 %, near from 80 % up to the amount, over above it, on exact
  amounts. An amount applies from its month onwards, so edits do not rewrite past months.
- Each pot has its own credit-normal ledger account; a deposit needs the parent's available
  balance and a withdrawal the pot's.

## Tests

- `dune test`: expect tests per module (pots, bookings, jobs, categorisation, insights,
  budgets, months, percentages) and a cram test for the CLI.
- Quickcheck properties for months, categorisation, insights, budgets, percentages and pot
  bookings (money conservation, category totals, budget states).
- `test_stable.ml` pins the bin_prot digests of the persisted `Stable.V1` types; a changed
  digest means adding a `V2`.
- CI runs `examples/quickstart.ml` and diffs its output against `quickstart.expected`.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md). External: `core`, `core_unix` (CLI),
  `zarith`, `ppx_jane`, `scheduler-core` (job interface for top-ups and round-up sweeps;
  no page in this directory yet). Tests use `expect_test_helpers_core`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, then `money`, then `ledger`, then `scheduler-core`. CI pins each from GitHub
through the shared `ox-setup` action, then runs `dune build`, `dune test`, the quickstart
example, an odoc build that fails on any warning, and the shared `obj-magic` workflow.

## Known gaps

- The README, CHANGES and AGENTS files list no open gaps.
- Everything is under "Unreleased" in `CHANGES.md`; no version has been released.
