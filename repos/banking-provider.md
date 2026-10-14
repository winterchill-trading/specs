# banking-provider

The boundary between an application and a banking-as-a-service provider: the `Provider.S`
module type (customers and KYC, accounts, transfers, swaps, virtual cards, standing orders,
webhooks), the `Sandbox.S` module type for simulated outcomes, the normalized `Event.t` every
provider reports in, a deterministic `Fake_provider` that books into a
[ledger](ledger.md) journal, and a `Conformance` functor that any implementation must pass.

| | |
| --- | --- |
| Repository | `winterchill-trading/banking-provider` |
| opam package | `banking-provider` |
| Library | `banking_provider` (module `Banking_provider`) |
| Binary | `banking-provider` (`demo`, `conformance`) |
| Status | done: `Provider.S`, the fake and the conformance suite are in place; CI green |

## Key modules

| Module | Purpose |
| --- | --- |
| `Provider.S` | What an application needs from a provider, in Async with `Or_error` |
| `Sandbox.S` | Simulations a sandbox offers: deposit, KYC decision, card authorization, transfer outcome, ping |
| `Event` | The normalized event union with the provider's event id; `Stable.V1` with a pinned digest |
| `Transfer_update` | A provider's report about a transfer; `apply` treats redeliveries and overtaken reports as `Stale` |
| `Card_update` | Card status and scheme messages (request, advice, reversal, clearing, expiry) in card-core types |
| `Account`, `Customer`, `Card_info`, `Transfer_info`, `Statement` | Views a provider returns |
| `Sca_challenge` | A challenge a provider issues for an operation; `Or_challenge` for calls that may need one |
| `Webhook` | Raw requests, HMAC-SHA256 helpers, and a timestamped signature with a five-minute replay window; the signature is compared in constant time over the raw bytes |
| `Inbox` | In-memory dedup by event id; a service keeps the durable inbox in its own store |
| `Sensitive` | Codes, tokens and secrets that print as `<redacted>`, with constant-time equality |
| `Fake_provider` | Deterministic in-memory provider over a ledger journal |
| `Conformance` | Scenarios as a functor over `Provider.S` and `Sandbox.S` |
| `Customer_ref`, `Account_ref`, `Event_id`, `Standing_order_ref` | Provider-side identifiers |

## The contract

- **Idempotent creation.** `create_customer` (by the application's customer id),
  `initiate_transfer` (by the draft's transfer id), `issue_virtual_card` (by `request_id`) and
  `open_account` (one account per customer and currency) return what the first call made, so
  an outbox relay may resend them.
- **Results arrive as events,** at least once and in any order. The initiating response is
  never the final state; `transfer` and `kyc_status` serve reconciliation.
- **SCA belongs to the operation.** A transfer, swap, standing order or card-number reveal may
  answer `Challenge c`; `confirm_sca c.id ~code` resumes it.
- **Ids.** The application's transfer, swap and standing-order ids go out; provider ids
  (`Customer_ref`, `Account_ref`, card ids) come back.
- **No personal data in events.** KYC events carry steps and status only; the application
  opens its kyc-core case with the person it collected.
- **Statements show posted money:** hold placements and releases net out; captures appear as
  the payment.

The repository's `docs/contract.md`
lists what an adapter must normalize and why.

## Fake provider

Deterministic: ids are counters (`cus_000001`, `acc_000001`, `evt_000001`), time comes from an
injected time source, and nothing is random. Every movement is booked in the given
`Ledger.Journal.t` with payments-core's and card-core's booking rules, keyed by the event id,
so balances are what the journal says and the trial balance always holds. It simulates KYC
steps and decisions, IBANs and deposit addresses, deposits on each rail, payment settlement in
immediate, delayed or manual modes, rejections and returns, swaps with three linked ledger
legs, card decisions, clearing, reversal, refund and stand-in advice, payee checks, GBP and
USD accounts with UK and US details and payments on the UK and US rails,
standing orders, and signed webhook deliveries kept for redelivery and reordering.

It keeps no personal data: `create_customer` and `update_customer` accept the person and
ignore it.

## Conformance

`Conformance.Make (P) (S)` provides twelve scenarios, run in the config's currency over its
rail: `Config.default` (EUR, SCT Inst), `Config.gbp` (GBP, Faster Payments) and `Config.usd`
(USD, ACH PPD). Each awaits results through events or
polling within a timeout, so a sandbox that provisions an IBAN minutes later still passes:
idempotent customers, KYC approval, EUR account with IBAN, deposit and balance, SCA-confirmed
payment debiting amount plus fee, resend pays once, overdraft refused, wrong code refused,
unsigned webhook refused, ping event, card approved and card declined `57` when frozen, and
`verify_payee` returning a simulated answer. The account scenario asks for the address the rail
needs (IBAN, sort code and account number, routing and account number).

The fake passes them in its own tests, immediately and with fees and delayed settlement on the
wall clock. An adapter runs the same functor against its sandbox behind an environment gate.

## Storage

This is a library and persists nothing itself. The fake keeps its state in memory and its money
in the ledger journal file it is given. A service that uses a provider keeps its own outbox,
inbox and idempotency records in its own store (see
[ADR 0009](../adr/0009-postgres-replaceable-store.md)).

## Dependencies

- Depends on: [kyc-core](kyc-core.md), [payments-core](payments-core.md),
  [card-core](card-core.md), and through them [money](money.md) and [ledger](ledger.md).
  No database and no HTTP client.
- Used by: `striga-provider` (in progress) and `neobank-api` (planned).

## CI pin order

`fixed-decimal`, `money`, `ledger`, `kyc-core`, `payments-core`, `card-core`. CI pins each from
GitHub, then runs `dune build`, `dune test` and the shared `obj-magic` workflow.

## Tests

Expect tests cover onboarding, payments with SCA, resends, insufficient funds, timeouts and late
settlement, returns, stale and redelivered reports, SCA lockout, delayed on-chain confirmations,
swaps, card flows, standing orders, Lightning, statements, webhook signatures and shuffled
redelivery into the inbox, the pinned event digest, the conformance suite, and a cram test of
the CLI. Quickcheck properties check that an update applied twice is `Stale` the second time,
and that random deposits, payments, card authorizations and refunds keep the trial balance at
zero, the account never overdrawn, and the statement's closing balance equal to the posted
balance.

## Known gaps

- Lightning payments to a BOLT 11 invoice settle without a preimage in the fake: the invoice's
  payment hash belongs to the payee.
- `Event.Stable.V1` and the unversioned `bin_io` of `Account` cannot write UK or US rails,
  accounts or details, or newer-network addresses (they raise); an inbox that may see them
  must persist `Event.Stable.V2`.
- `verify_payee` is new in `Provider.S`: striga-provider answers an error (no verification of
  payee at Striga); griffin-provider maps it onto its Confirmation of Payee but its
  `simulate_payee_check` refuses (Griffin simulates one request at a time), so the
  conformance payee scenario fails there until the adapter keeps answers per beneficiary.
- The fake's payee checks are deterministic by account-number suffix, not a name register;
  US accounts are never checked (no US scheme checks names).
- The fake charges cards only in their billing currency (no FX clearings) and simulates neither
  incremental authorizations nor disputes.
- An approved stand-in advice above the available balance cannot be held.
- Standing orders run only on an explicit call; nothing schedules them.
- Bookings take their time from `Ledger.Journal.now`; a frozen clock makes idempotency keys collide.
