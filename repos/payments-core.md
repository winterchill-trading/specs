# payments-core

Provider-neutral payment rails and transfer lifecycles: SEPA Credit Transfer and SCT Inst with
their ISO 20022 fields and reason codes, on-chain transfers with travel-rule data and a
confirmation policy, Lightning, and intraledger moves. It also covers beneficiary validation,
strong customer authentication (SCA), standing orders, currency swaps, and the pure booking
rules that turn every transfer transition into balanced `ledger` entries. Reconciliation
compares a provider's view with the ledger and returns breaks. No network access; a provider
adapter maps its webhooks onto these states.

| | |
| --- | --- |
| Repository | `winterchill-trading/payments-core` |
| opam package | `payments-core` |
| Library | `payments-core` (module `Payments_core`) |
| Binary | `payments` (`iban`, `bic`, `address`, `lightning`, `schedule`, `demo`) |
| Status | done: library, CLI and property tests are in place |

## Key modules

| Module | Purpose |
| --- | --- |
| `Rail`, `Network` | SEPA credit and instant, on-chain per network, Lightning, intraledger |
| `Iban`, `Bic` | ISO 13616 IBAN (country lengths, mod 97, SEPA membership); ISO 9362 BIC |
| `Crypto_address`, `Base58`, `Bech32` | Per-network address checks: Base58Check, SegWit v0 and v1+, EIP-55, Tron, Solana |
| `Lightning` | BOLT 11 invoices (network, amount, expiry, payment hash), LNURL, Lightning addresses |
| `Beneficiary` | Payee with destination, trusted flag, first-seen date and payee-name check result |
| `Iso_reason`, `Iso20022` | Reason codes with their R-transaction kinds; payment ids, UETR, creditor reference, remittance, pacs.002 statuses, SEPA character set |
| `Sepa`, `Target_calendar` | Rulebook checks, reason lists per R-transaction, SCT Inst timing, return and recall deadlines in TARGET business days |
| `Travel_rule`, `Confirmation_policy` | Originator and beneficiary data for transfers of funds; when an on-chain deposit counts |
| `Transfer` | Status machine with reason-coded rejects, returns, recalls, SCT Inst time-outs and chain reorgs |
| `Sca` | Two-category challenges bound to amount, currency and payee; attempt locks; sessions; exemptions; counters; audit events |
| `Booking` | Transitions to ledger entries: hold, capture, fee, release, return, late settlement, reorg |
| `Swap` | Quotes with spread and fee; three-entry execution |
| `Standing_order`, `Schedule` | Recurring drafts with month-end clamping and catch-up |
| `Reconciliation` | Balance and status diffs; transaction breaks with ageing and maker-checker resolution |

Rules enforced by the library:

- SCT Inst: a 10-second time-out; a settlement that arrives late is booked as a fresh entry.
- SCA: five failed attempts lock the challenge for 30 minutes; every outgoing transfer records
  the exemption and the RTS article it relies on.
- A transfer's hold, fee and capture are booked as one linked group: all or nothing.
- Confirmation policy: BTC counts after 3 or 6 confirmations (the policy's
  thresholds), ETH when finalized.

## Tests

- `dune test`: expect tests and vectors from BIP 173 and 350, EIP-55, BOLT 11, RFC 6238, ISO
  11649 and ISO 17442 (LEI); cram tests for the `payments` CLI.
- Base_quickcheck properties: over random lifecycles the trial balance stays zero and every
  hold is closed; swap rounding; `Schedule.next_after`; generated ids pass the SEPA character
  checks.
- Property tests found two bugs, a fee overdraw and a double capture on a chain reorg; both are
  fixed.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md). External: `core`, `core_unix` (CLI),
  `async_kernel`, `cryptokit`, `zarith`, `ppx_jane`.
- Used by: [card-core](card-core.md) (SCA counters and exemptions); planned for `risk-rules`
  and `banking-provider` (see [design/neobank.md](../design/neobank.md)).

## CI pin order

`fixed-decimal`, then `money`, then `ledger`. CI pins each from GitHub, then runs `dune build`
and `dune test`, and the shared `obj-magic` workflow.

## Known gaps

- BOLT 11 node signatures and the payment secret (`s` field) are not checked; the paying
  provider verifies them.
- The window for a request for recall by the originator (AC03, AM09, CUST) is not confirmed by
  the research; 13 months is assumed.
- The Tron and Solana deposit thresholds are our choice, not from a scheme document.
- Business-day deadlines use the TARGET calendar only; national holidays are ignored.
- Reconciliation breaks are values; persisting them is the caller's job.
- Hold entries carry no SCA evidence, because the ledger API does not accept it yet.
- Linked groups booked at a frozen clock collide on `recorded_at`; this is a ledger issue.
