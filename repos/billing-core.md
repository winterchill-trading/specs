# billing-core

Recurring and usage-based billing as pure OCaml values and state machines: price lists,
subscriptions, usage, invoices, receipts, dunning, credit notes and ledger bookings. The
library is meant to hold the rules of billing (what a period costs, when an invoice is due,
how a failed payment is retried, how a credit note offsets an invoice) and to leave storage
and payment collection to the caller. It is work in progress: the modules and their
interfaces exist, and the tests walk the engine through billing, dunning, credit and
cancellation, but the API is not yet stable.

| | |
| --- | --- |
| Repository | `winterchill-trading/billing-core` |
| opam package | `billing-core` |
| Library | `billing-core` (module `Billing_core`) |
| Binary | none |
| Status | in progress: scaffold with interfaces and an engine walk test; API not frozen, no `Stable.V1` types yet |

## Key modules

| Module | Purpose |
| --- | --- |
| `Customer_id`, `Plan_id`, `Subscription_id`, `Invoice_id`, `Credit_note_id`, `Payment_id`, `Usage_id` | Validated ids |
| `Price`, `Unit_price`, `Price_list` | Prices per unit and per plan; price lists |
| `Interval`, `Period` | Billing periods and their boundaries |
| `Plan`, `Meter`, `Usage` | Plans, the meters that count usage, and usage records |
| `Subscription`, `Proration` | Subscription state and the charge for a partial period |
| `Charges`, `Line`, `Tax`, `Rounding_rules` | Charges per line, tax, and how amounts round |
| `Invoice`, `Numbering`, `Receipt` | Invoices, their numbers, and receipts for paid invoices |
| `Dunning` | Retry schedule and states for failed payments |
| `Credit_note` | Credits against invoices |
| `Booking` | Ledger bookings of invoices, payments and credits |
| `Engine` | Billing operations over a `Store.S`: invoices for periods, usage, payments, credit, cancellation |
| `Refusal` | Why an event was refused |
| `Store`, `Store_memory`, `Store_conformance` | Persistence as a module type, an in-memory store and the conformance suite |

## Design

- `Engine` runs the pure state machines over a `Store.S`. Every operation is safe to retry and
  safe to run from several processes: invoice ids derive from the subscription and the period
  they bill, document numbers are idempotent, saves are compare-and-set (a stale save reloads
  and redoes the pure step).
- The engine never appends to a journal. It returns the ledger entries and the caller books
  them; a retried call returns the same entries, and the journal recognises the duplicates.
- `Booking` builds balanced [ledger](ledger.md) entries with deterministic keys such as
  `billing:invoice:<id>:issue`. Issuing an invoice debits the customer's receivable and credits
  fee income per component and tax payable per rate; a payment credits the receivable, and a
  payment on a written-off invoice credits bad debt instead.
- `Dunning` is a state machine (`Waiting`, `Collecting`, `Exhausted`, `Recovered`, `Closed`)
  driven by a policy of waits in days. On a retry date it asks the caller to collect once and
  waits for the outcome.
- Periods close `close_after_days` after they end (default 0). Usage dated before the current
  period is refused with `Period_closed`.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md). External: `core`, `ppx_jane`, `zarith`,
  `expect_test_helpers_core` for tests, `odoc` for docs.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `money`, `ledger`. CI pins each from GitHub, then runs `dune build`,
`dune test`, the examples and the API docs build.

## Known gaps

- Work in progress: the interfaces may still change before a first release.
- No `Stable.V1` binary formats yet, so no pinned digests.
