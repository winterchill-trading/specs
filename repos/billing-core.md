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
| `Engine` | Applies events (billing run, usage, payment, cancellation) to the state |
| `Refusal` | Why an event was refused |
| `Store`, `Store_memory`, `Store_conformance` | Persistence as a module type, an in-memory store and the conformance suite |

## Design

- Pure values: the engine takes state and an event and returns the new state and the
  effects (invoices to issue, bookings to make, retries to schedule). Nothing is persisted
  or sent by the library.
- Money is [money](money.md) amounts; bookings go through [ledger](ledger.md) entries, so a
  billing run never changes a balance except through the ledger's own rules.
- Refusals are values, as in the other banking libraries; an event that does not apply is
  reported, not raised.

## Tests

- `dune test`: expect tests per module and a walk of the engine through billing, dunning,
  credit and cancellation.
- `Store_conformance` is the suite a service runs against its own store.
- `@examples/runtest` builds the examples in CI.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md). External: `core`, `ppx_jane`, `zarith`,
  `expect_test_helpers_core` for tests, `odoc` for docs.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `money`, `ledger`. CI pins each from GitHub, then runs `dune build`,
`dune test`, the examples and the API docs build.

## Known gaps

- Work in progress: the README says so, and the interfaces may still change before a first
  release.
- No stable binary formats yet, so no pinned digests.
- Payment collection, tax rules by jurisdiction and invoice delivery are left to the caller.
