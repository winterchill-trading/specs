# payouts-core

Batches of outgoing payments to many payees, across rails and currencies: payroll runs,
contractor and supplier payments, bulk refunds. One approval covers a whole batch; after
that every line is funded, sent and settled on its own. Lines are a pure state machine,
the batch is approved through a policy hook, and money is reserved with
[ledger](ledger.md) holds before any transfer is made through [payments-core](payments-core.md).
Nothing is persisted by the library.

| | |
| --- | --- |
| Repository | `winterchill-trading/payouts-core` |
| opam package | `payouts-core` |
| Library | `payouts-core` (module `Payouts_core`) |
| Binary | none |
| Status | done: library, quick-start example (checked in CI) and property tests are in place |

## Key modules

| Module | Purpose |
| --- | --- |
| `Batch_id`, `Line_id`, `Actor_id` | Validated ids (the ledger id alphabet) |
| `Line_key` | Per-line idempotency key; the ledger keys and the funding hold id are derived from it |
| `Line_status`, `Failure` | The transition table; why a line failed |
| `Line` | One payment: payee, rail, amount, reference, status, history, funding, transfer |
| `Approval` | `Policy.t` hook, `Policy.thresholds`, `Summary`, `Refusal` |
| `Batch` | Creation checks, approve, reject, cancel, cancel a line, derived `Progress` |
| `Conversion` | The FX hook: buy a line's amount in a funding currency |
| `Funding` | `plan` against ledger balances, `apply`, `release` |
| `Submission` | Transfer drafts, hold handover on submission, `observe` of transfer statuses |
| `Receipt` | Receipts as values, masked destinations, text rendering |
| `Reconciliation` | Per-currency `Totals`; differences between batch, ledger holds and transfers |
| `Store`, `Store_memory`, `Store_conformance` | Persistence as a module type, an in-memory store and the conformance suite |

## Rules

- **Line life.** `draft -> approved -> funded -> submitted -> settled`, with `failed`,
  `returned` and `cancelled`. Every transition is checked against one table; failed,
  returned and cancelled are final.
- **Batch approval.** `Approval.Policy.t` is two functions over the batch totals and the
  approver. The creator never approves their own batch and one person approves once,
  whatever the policy. Batches go `pending_approval -> approved | rejected | cancelled`;
  progress after approval is derived from the lines (`processing`, `completed`,
  `completed_with_failures`, `failed`).
- **Funding.** `Funding.plan` walks approved lines in order against
  `Ledger.Balances.available` and reserves each with a ledger hold. Two modes: fund what
  fits line by line, or all or nothing. The ledger re-checks each hold when it is booked,
  so a plan built on stale balances is refused, never half applied.
- **Conversion.** Funding never prices currencies. For a line its currency account cannot
  cover, the plan asks the `Conversion.Hook.t` for a firm price to buy exactly the line's
  amount; the caller executes the conversion and plans again.
- **Idempotency.** Each line carries the caller's key. A store refuses a second line with
  the same key, so a retry never pays twice.
- **Partial failure.** Lines fail independently and nothing is rolled back.

Ledger entries per step:

| Step | Entries | Key |
| --- | --- | --- |
| Funding | hold of the line's amount on the payer's account | `<line key>/fund`, hold `payout:<line key>` |
| Cancel or fail while funded | release of that hold | `<line key>/release` |
| Submission | release of the funding hold and the transfer's own hold, in one linked record | `<line key>/submit`, `<event id>/hold` |
| Settlement, rejection, return | `payments-core` `Booking.transition` | `<event id>/<leg>` |

Receipts are plain values: `Receipt.of_line` builds the record and `Receipt.to_text`
renders it. Reconciliation checks that per-currency buckets add up and lists every
difference between a batch, the ledger's holds and the transfers that pay it.

## Tests

- `dune test`: expect tests and the quick-start example, whose output is compared with
  `examples/quickstart.expected`.
- Base_quickcheck properties on the line machine, batch progress and reconciliation.
- `Store_conformance` is the suite a service runs against its own store.
- Stable digests are pinned for every persisted type (`Stable.V1`).

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md), [payments-core](payments-core.md).
  External: `core`, `ppx_jane`, `zarith`, `base_quickcheck` and `odoc` for tests and docs.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `money`, `ledger`, `payments-core`. CI pins each from GitHub, then runs
`dune build`, `dune test` and the API docs build.

## Known gaps

- Payroll schedules (a batch per due date) are left to a scheduler; a batch has no notion
  of recurrence.
- Contractor invoices and monthly payout caps are not modelled.
- Lines are not dated: every approved line is due at once.
- The FX hook is a function, not a dependency on a pricing library; executing the
  conversion is the caller's job.
- Persisted rails and payees use the `payments-core` V2 format, which carries the UK rails.
