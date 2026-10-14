# payments-core

Provider-neutral payment rails and transfer lifecycles: SEPA Credit Transfer and SCT Inst with
their ISO 20022 fields and reason codes, UK Faster Payments, CHAPS and Bacs with sort codes and
the published modulus check, US ACH, RTP and Fedwire with ABA routing numbers, on-chain transfers with travel-rule data and a
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
| Binary | `payments` (`iban`, `bic`, `address`, `uk-account`, `lightning`, `schedule`, `demo`) |
| Status | done: library, CLI and property tests are in place |

## Key modules

| Module | Purpose |
| --- | --- |
| `Rail`, `Network` | SEPA credit and instant, Faster Payments, CHAPS, Bacs, ACH (standard entry class, same day), RTP, Fedwire, on-chain per network (Bitcoin, Ethereum, Polygon, Tron, Solana, Base, Arbitrum, Plasma, Spark), Lightning, intraledger |
| `Sort_code`, `Uk_account`, `Uk_modulus`, `Uk_scheme` | UK accounts with roll numbers, the published modulus check over caller-loaded tables, Faster Payments limit (configurable), CHAPS cut-off hook and value dates |
| `Aba`, `Us_account`, `Us_scheme` | ABA routing numbers (check digit), US accounts (checking or savings), Same Day ACH and RTP limits (RTP configurable) |
| `Iban`, `Bic` | ISO 13616 IBAN (country lengths, mod 97, SEPA membership); ISO 9362 BIC |
| `Crypto_address`, `Base58`, `Bech32` | Per-network address checks: Base58Check, SegWit v0 and v1+, EIP-55, Tron, Solana |
| `Lightning` | BOLT 11 invoices (network, amount, expiry, payment hash), LNURL, Lightning addresses |
| `Beneficiary` | Payee with destination (IBAN, UK account, US account, crypto, Lightning, internal), trusted flag, first-seen date and payee-name check result (match, close match, no match, not possible, account not found, unavailable) |
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
- Stable formats: `Stable.V2` of `Network`, `Crypto_address`, `Rail`, `Beneficiary`,
  `Transfer` and `Standing_order` hold the UK and US rails and accounts and the newer
  networks. V1 digests and the unversioned `bin_io` (still the V1 format) are unchanged,
  so a record that embeds a V1 type raises when asked to write a UK or US value: dependents
  that persist those (risk-rules `Context`, neobank-api's store and model, striga-provider's
  and lightspark-provider's stores) need their own V2 before they carry GBP or USD.
- The UK modulus tables are not bundled (they change several times a year); without them
  every account is `Not_checked`. Nine and ten digit UK account numbers are refused.
- UK and US bank holidays are not known: the default CHAPS cut-off covers weekends only;
  US cut-offs, the Federal Reserve calendar, NACHA files and R-code tables are not modelled.
  Bacs is a stub. FedNow is not a rail.
- Spark addresses are checked for prefix and Bech32m checksum only.
- Reconciliation breaks are values; persisting them is the caller's job.
- Hold entries carry no SCA evidence, because the ledger API does not accept it yet.
- Linked groups booked at a frozen clock collide on `recorded_at`; this is a ledger issue.
