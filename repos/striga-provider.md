# striga-provider

`banking-provider`'s `Provider.S` and `Sandbox.S` implemented over the Striga v1 API
through `striga-client`: customers and KYC, EUR and crypto accounts, SEPA, intraledger,
on-chain and Lightning payouts confirmed by SCA, swaps, virtual cards, statements and
webhooks normalized into `banking-provider` events. Sandbox by default. The mapping from
each operation, sandbox call and webhook to Striga endpoints is in the repository's
`docs/mapping.md`.

| | |
| --- | --- |
| Repository | `winterchill-trading/striga-provider` |
| opam package | `striga-provider` |
| Library | `striga-provider` (module `Striga_provider`) |
| Binary | none. `test/live` is the conformance runner, enabled by `STRIGA_LIVE_TESTS=1` |
| Status | done, sandbox-limited: the adapter's mappings are tested on recorded bodies, and the live checks cover customer creation, KYC, wallets and webhook signatures. The sandbox never provisioned a EUR account for the test persons, so the EUR-dependent conformance scenarios did not run (see Conformance) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Adapter` | `Provider.S`, `Sandbox.S`, webhook ingestion (`ingest_webhook`) and the poller used when there is no public webhook URL |
| `Store` | Links Striga cannot hold (our customer, transfer, challenge, swap and card request ids), with an in-memory implementation; a service supplies its own persisted one |
| `Refs` | Account and standing order refs carrying the Striga user id |
| `Units` | Striga tickers and smallest units to `Money`; USDC and USDT cents rescaled to micro-units |
| `Kyc_map` | Striga tiers and statuses to `kyc-core` steps, status and events |
| `Account_map` | Accounts, enrichment (IBAN, deposit addresses) and balances |
| `Tx_map` | Ledger entries to transfer updates and deposits |
| `Card_map`, `Card_tx_map` | Cards, statuses and EUR limits; card transactions to `card-core` advices |
| `Striga_time` | ISO and epoch-millisecond timestamps |

Idempotency comes from the `Store`: Striga takes no idempotency keys, so every create looks
up the store first. Only the in-memory store ships; a service must persist its own.

## Tests

- `dune test`: unit tests per mapping module (`test_account_map`, `test_card_map`,
  `test_card_tx_map`, `test_kyc_map`, `test_refs`, `test_tx_map`, `test_units`) on recorded
  and documented Striga bodies in `test/fixtures` (ids and IBANs redacted).
- `STRIGA_LIVE_TESTS=1 dune test` runs the `banking-provider` conformance functor against
  the sandbox with the credentials from a local `.env` (not committed). Each run creates new
  sandbox users prefixed with a timestamp. Without the variable it prints one line and
  passes, which is what CI sees.

## Conformance

Two sandbox runs, each with a different test person, stopped the same way: after the
simulated KYC approval the sandbox provisioned the crypto accounts (BTC, ETH, BNB, POL,
SOL) within seconds, but no EUR or USDC account, neither within the 6-minute timeout nor
about an hour later. Four of the 11 scenarios pass (customer creation idempotency, KYC
approval as an event, a bad webhook signature refused, the webhook ping). The seven
others all start by opening a EUR account, so none reached the deposit, SCA payment,
double-initiation, overdraft, wrong-code or card steps. The suite has no crypto scenarios.

## Dependencies

- Depends on: `banking-provider` (the `Provider.S` and `Sandbox.S` it implements, and the
  domain types), `striga-client` (the Striga SDK). External: `core`, `async`, `yojson`,
  `zarith`.
- Domain libraries used through `banking-provider`: `money`, `ledger`, `kyc-core`,
  `payments-core`, `card-core`, `fixed-decimal` (via `money`).
- Used by: none yet. `neobank-api` selects it in its Striga mode (on `main`).

## CI pin order

`fixed-decimal`, `money`, `ledger`, `kyc-core`, `payments-core`, `card-core`,
`banking-provider`, `striga-client`. CI uses the `infra` `ox-setup` action with those pins,
then `dune build` and `dune test`, and the shared `obj-magic` workflow. The live suite
does not run in CI.

## Known gaps

- **EUR and USDC accounts in the sandbox.** Not provisioned after a simulated KYC approval in
  either run, so deposits, SEPA payouts with SCA, wrong-code handling, double-initiation,
  overdraft refusal and cards were not exercised live by this adapter. Earlier SDK-level runs
  saw EUR appear minutes after approval. Whether this is an application setting, the test
  person's residence or a sandbox fault is not known.
- **No crypto funding in the sandbox.** On-chain, crypto intraledger and Lightning payouts
  stop at Striga's balance or invoice checks; `simulate_deposit` credits EUR by SEPA only.
- **No idempotency keys at Striga**, so the `Store` is what makes creates idempotent; only
  the in-memory store ships.
- **Standing orders** return an error: Striga's are deposit conversions, not dated payments.
  The application schedules them.
- **Fee quotes** for on-chain and Lightning are known only once a payout is initiated; SEPA
  and intraledger quote zero (the sandbox application charges none).
- **Card numbers** need Striga's browser component to start the consent. Card limits are
  whole euros, without ATM counts, MCC or country block lists. `Blocked`, `Requested` and
  `Expired` cannot be set.
- **`simulate_transfer_outcome`** covers confirmed SEPA payouts only.
- **`ping`** publishes its own `Ping`: Striga answers 200 whether or not the delivery reached
  the dashboard's URL.
- **SCA attempts** are counted locally (Striga allows five and does not report the rest).
  Each confirmation sends the configured end-user IP, since `Provider.S` carries none.
- **Transfer status ordering** uses the adapter's own rank table over a stored status, not
  `Transfer_update.apply`, because the store keeps a record, not a full `Transfer.t`.
