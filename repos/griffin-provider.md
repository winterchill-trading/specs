# griffin-provider

The UK adapter of [banking-provider](banking-provider.md): its `Provider.S` and `Sandbox.S`
implemented over the Griffin v0 API through [griffin-client](griffin-client.md). It covers UK
customers as legal persons with onboarding checks and decisions, GBP accounts with sort
codes, Faster Payments and book transfers, Confirmation of Payee, statements, and Griffin's
event log and webhooks normalized into `banking-provider` events. Sandbox by default. Cards,
swaps, standing orders, crypto and SCA are not offered and answer an error saying so.

| | |
| --- | --- |
| Repository | `winterchill-trading/griffin-provider` |
| opam package | `griffin-provider` |
| Library | `griffin-provider` (module `Griffin_provider`) |
| Binary | `griffin-provider` (`accounts`, `balance`, `uk-details`, `statement`, `kyc`, `cop`, `events`) |
| Status | done, sandbox-limited: the GBP walk passes on the sandbox; the shared conformance suite is EUR-only and fails 7 of 11 scenarios |

## Why separate

`banking-provider` describes what an application needs from any banking-as-a-service provider
and stays free of provider names; `griffin-client` is a plain SDK for one API. This adapter
is the only place that knows both, so an application written against `Provider.S` runs
unchanged on the fake provider in tests and on Griffin for GBP.

## Key modules

| Module | Purpose |
| --- | --- |
| `Adapter` | `Provider.S`, `Sandbox.S`, Confirmation of Payee, UK details, webhook ingestion, the poller |
| `Store` | Links Griffin cannot hold (our customer ids, accounts per currency, transfers), with an in-memory implementation and a stable transfer record |
| `Refs` | Customer and account refs from Griffin resource URLs |
| `Uk_account` | Sort codes and account numbers, from text or a GB IBAN |
| `Units` | Griffin GBP amounts to `Money` |
| `Kyc_map` | Person to claims; legal persons, verifications and decisions to kyc-core steps, status and events |
| `Account_map` | Accounts, balances, statements |
| `Tx_map` | Submissions and admissions to transfer states, deposits and events |
| `Griffin_time` | ISO timestamps |

`docs/mapping.md` lists every operation with its Griffin endpoints, every event and the KYC,
payment and Confirmation of Payee mappings. `docs/api-notes.md` records what the sandbox
showed.

## Rules

- Payees are `Internal` beneficiaries naming a sort code and account number
  (`04-00-04 12345678`) or a Griffin account id (`ba.…`, a book transfer), or a `Bank_account`
  with a GB IBAN.
- GBP payments are drafted and reported on the `Intraledger` rail, because payments-core has
  no Faster Payments rail yet (see Known gaps).
- Creates are idempotent through the `Store`: a service must persist it. Accounts are also
  found again by owner.
- Without a public webhook URL the adapter polls the organization's event log while `events`
  has a subscriber. A service hands each webhook delivery to `ingest_webhook`.
- Credentials are read only from the environment and never logged.
- Sandbox keys (`g-test-`) are the only ones accepted unless the caller passes `~live:true`.

## Coverage

"Live" means exercised on the Griffin sandbox on 2026-10-14 by the conformance run, the GBP
walk or the example; "offline" means against recorded bodies or the in-memory Griffin in
`test/`.

| Operation | Verified |
| --- | --- |
| `create_customer` (idempotent), `update_customer` | live, offline |
| `start_verification`, `kyc_status`, KYC events | live, offline |
| `simulate_kyc_decision` | approve live and offline; decline offline |
| `open_account` (idempotent, recovered by owner), `accounts`, `uk_details` | live, offline |
| `balance`, `statement` | live, offline |
| `initiate_transfer` by Faster Payments and book transfer, resend, refusal above the scheme limit, insufficient funds | live, offline |
| `transfer`, transfer events | live, offline |
| `cancel_transfer` | offline |
| `simulate_deposit` (Faster Payments) and the deposit event | live |
| `confirm_payee`, `simulate_confirm_payee` (match, close match, no match, account not found) | live, offline |
| `ingest_webhook` (verified, tampered, wrong host) | offline (own P-521 key); the forged delivery live |
| `ping` | local `Ping` event (live) |
| refusals (cards, EUR, SCA, swaps, standing orders) | live, offline |

## Tests

- `dune test`: mapping tests on recorded, redacted sandbox bodies; adapter flows against an
  in-memory Griffin (`test/fake_griffin.ml`); the CLI and examples build; the live runners
  print a skip line without credentials.
- `GRIFFIN_LIVE_TESTS=1 dune test` with the sandbox key loaded: the conformance suite and the
  GBP walk (`test/live/walk.ml`). Each run creates sandbox legal persons, accounts and payments.

Conformance, run on 2026-10-14 against the sandbox: 4 passed, 7 failed. The passes are the
idempotent create, the KYC approval event, the rejected bad signature and the local `Ping`.
Every failure is the suite opening an EUR account with an IBAN first, which Griffin does not
hold (GBP only). The GBP walk checks the same properties in GBP and passed on the same day:
customer and onboarding, one account per customer, a deposit published once and credited, a
Faster Payment settled and debited by amount plus fee, the same transfer twice paying once,
a book transfer between customers, payments above the balance not leaving the account, a
balanced statement, Confirmation of Payee, and refusals for cards and EUR.

## Dependencies

- Depends on: [banking-provider](banking-provider.md), [griffin-client](griffin-client.md),
  [kyc-core](kyc-core.md), [payments-core](payments-core.md), [card-core](card-core.md),
  [money](money.md), [ledger](ledger.md). External: `core`, `core_unix`, `async`,
  `async_kernel`, `ppx_jane`, `yojson`.
- Used by: none yet; a neobank provider choice would select it (see
  [design/neobank.md](design/neobank.md)).

## CI pin order

`fixed-decimal`, `money`, `ledger`, `kyc-core`, `payments-core`, `card-core`,
`banking-provider`, `griffin-client`. CI pins each from GitHub, then runs `dune build`,
`dune build @examples/all` and `dune test`.

## Known gaps

- No Faster Payments rail or UK account destination in payments-core, and no UK details in
  `Account.Address`. GBP payments ride on `Intraledger`, and accounts list no addresses;
  `uk_details` gives the sort code. A `Faster_payments` rail, a UK account destination and an
  address would remove both workarounds.
- No `verify_payee` in `Provider.S`: Confirmation of Payee is `Adapter.confirm_payee`.
- The shared conformance suite is written for EUR, SEPA and cards only, so 7 of its 11
  scenarios cannot pass against a GBP provider. A suite parameterized by currency and rail
  would let the GBP walk's checks run there.
- No idempotency keys at Griffin; only the `Store` makes creates idempotent. A legal person
  created by a lost response is not found again.
- Tier: Griffin verifies identity and address electronically, not e-mail, mobile or liveness,
  so an approved customer's derived kyc-core tier stays `T0`.
- Sandbox: no inbound simulator (deposits are paid from another sandbox account), every
  payment is delivered (`simulate_transfer_outcome` refuses), and every new account starts
  with GBP 1m, so a balance equal to the deposit never holds.
- `ping` publishes its own `Ping` by default instead of asking Griffin for a test delivery to
  the organization's single webhook, which may belong to another integration.
- A declined decision is tested offline only, and Griffin has no resubmission request
  (`Request_resubmission` is refused).
- Cards, swaps, standing orders, crypto and SCA are not offered.
