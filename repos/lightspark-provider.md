# lightspark-provider

The Grid adapter of [banking-provider](banking-provider.md): its `Provider.S` and `Sandbox.S`
implemented over the Lightspark Grid API through [lightspark-client](lightspark-client.md).
It covers customers and their KYC state, USD and stablecoin accounts, cross-border payouts to
bank accounts with Grid's FX quotes, payouts to wallets and Lightning, conversions between a
customer's own accounts as swaps, statements, and webhooks normalized into `banking-provider`
events. Sandbox by default. Cards are not offered.

| | |
| --- | --- |
| Repository | `winterchill-trading/lightspark-provider` |
| opam package | `lightspark-provider` |
| Library | `lightspark-provider` (module `Lightspark_provider`) |
| Binary | `lightspark-provider` (`customer`, `fee`; read-only) |
| Status | done, sandbox-limited: the USD walk passes on the sandbox; the shared conformance suite is EUR-only and fails 8 of 11 scenarios |

## Why separate

`banking-provider` describes what an application needs from any banking-as-a-service provider
and stays free of provider names; `lightspark-client` is a plain SDK for one API. This adapter
is the only place that knows both, so an application written against `Provider.S` runs
unchanged on the fake provider in tests and on Grid for USD.

## Key modules

| Module | Purpose |
| --- | --- |
| `Adapter` | `Provider.S`, `Sandbox.S`, webhook ingestion, the poller, `us_bank_details` |
| `Grid_api` | Grid endpoints lightspark-client does not cover (external accounts, quotes with SCA, balance changes, contact verification, KYC links, test webhooks) and lenient object views |
| `Store` | Links Grid cannot hold (our transfer and swap ids to quotes and transactions, open SCA challenges), with an in-memory implementation |
| `Refs` | Account references carrying the owning customer |
| `Units` | Grid currencies and smallest units in `money` terms, exact |
| `Payee` | Beneficiaries as Grid external accounts and payment rails |
| `Kyc_map` | `kycStatus` and contact verification to kyc-core steps, status and events |
| `Account_map` | Internal accounts, funding instructions and balances |
| `Tx_map` | Transaction statuses and failure reasons to transfer updates and deposits |
| `Grid_time` | Timestamps |

`docs/mapping.md` lists every operation with its Grid endpoints, every webhook and transaction
status with its event, and the currency, rail, KYC and SCA mappings. `docs/api-notes.md`
records what the sandbox showed.

## Rules

- Grid opens the USD account itself a moment after the customer is created; `open_account`
  waits for it.
- A payout quoted in another currency from a USD account is a Grid quote: Grid sets the FX
  rate and the fee is in USD. A payout can lock the receiving amount.
- Money-moving writes are refused unless `GET /config` says the platform is a sandbox or the
  config was built with `~live:true`; the `Sandbox.S` calls refuse live configs outright.
- Webhooks are verified against the platform's PEM key (`X-Grid-Signature`); without the key
  every webhook is refused. Without a public webhook URL the adapter polls customers and their
  transactions while `events` has a subscriber.
- Credentials are read only from the environment and never logged; error bodies pass through
  lightspark-client's redaction.

## Coverage

| Area | Verified live (sandbox) | Fixtures only |
| ---- | ----------------------- | ------------- |
| Customers: create, find by our id, KYC status | yes | KYC webhooks |
| Contact verification, hosted KYC link | | not exercised (US customers need neither) |
| Accounts: open (wait), list, balance, US bank details | yes | |
| Sandbox deposit and its `Incoming_transfer` event | yes | inbound webhooks |
| Fee quote from exchange rates | yes | |
| Cross-border payout USD to EUR by SEPA, events Submitted, Pending, Settled; resend pays once | yes | |
| Payout refused by the partner (refunded) | yes | other failure reasons |
| USDC payout to an Ethereum wallet | yes | |
| Conversion USD to USDC as a swap, `Swap_executed` | yes | |
| Statement (transaction fallback) | yes | balance-change path |
| Payee name check on an IBAN (`Not_possible`: SEPA accounts are `UNSUPPORTED`) | yes | other answers |
| SCA challenge, wrong code, authorization | | yes (US customers get none) |
| Overdraft refusal | | yes |
| Webhook signature, normalization, redelivery | | yes (signed with a throwaway key) |
| `ping` | refused: no webhook URL on the platform | yes |

## CLI

```
lightspark-provider customer -id Customer:...
lightspark-provider fee -account Customer:.../InternalAccount:... -amount '30.00 EUR' [-instant]
```

Both are read-only (a fee quote reads exchange rates).

## Tests

- `dune test`: expect tests on redacted sandbox responses and documented bodies
  (`test/fixtures`, with ids, e-mails, account numbers and addresses replaced): unit
  conversions with a round-trip property, KYC mapping and event ids, accounts and US bank
  details, every transaction status and failure reason, payees, and the adapter over a fake
  transport (payouts with and without SCA, overdraft, swap, signed webhooks and redelivery).
- `LIGHTSPARK_LIVE_TESTS=1 dune test`: the conformance suite on the sandbox
  (`test/live/live.exe`). `LIGHTSPARK_LIVE_WALK=1` also runs the USD walk
  (`test/live/walk.exe`). Each run creates sandbox customers prefixed with a timestamp.

Conformance, run on 2026-10-14 against the Grid sandbox: 3 passed, 8 failed. The passes are the
idempotent create, the KYC approval event and the rejected bad signature. The failures are
the suite's EUR account with an IBAN, which this platform does not hold (USD, USDC, USDT and
USDB only, per `GET /config`), and a test delivery that needs a webhook URL on the platform.
The same steps in dollars passed on the same day in the walk: deposit, fee quote, a SEPA
payout settled and paid once on resend, a refused payout refunded, a conversion, a USDC wallet
payout and a statement whose lines add up. The walk prints statuses and amounts, never ids or
personal data.

## Storage

This is a library: it persists nothing. The `Store.t` record of functions is what a service
implements over its own database; `Store.memory` serves tests, the CLI and the live runs.

## Dependencies

- Depends on: [banking-provider](banking-provider.md), [lightspark-client](lightspark-client.md),
  [kyc-core](kyc-core.md), [payments-core](payments-core.md), [card-core](card-core.md),
  [money](money.md), [ledger](ledger.md). External: `core`, `core_unix`, `async`,
  `async_kernel`, `ppx_jane`, `ppx_yojson_conv`, `yojson`, `uri`, `zarith`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, `money`, `ledger`, `kyc-core`, `payments-core`, `card-core`,
`banking-provider`, `lightspark-client`. CI pins each from GitHub, then runs `dune build`,
`dune build @examples/all`, `dune test` and the API docs build.

## Known gaps

- **EUR accounts and IBANs**: the sandbox platform supports USD, USDC, USDT and USDB only, so
  the conformance suite's EUR scenarios cannot run here.
- **US domestic payouts** (ACH, RTP, FedNow, wire to a routing and account number) and US
  account details on `Account.t` need a payments-core rail and destination, and a non-IBAN
  address in banking-provider. Until then `us_bank_details` exposes the deposit details and
  payouts go to IBANs, wallets and Lightning.
- **Cards** are not offered by this adapter; the card calls return an error.
- **Standing orders**: Grid has no scheduled payments.
- **Sandbox outcomes** are chosen when the customer or payee is created (name and account
  number suffixes); `simulate_kyc_decision` only confirms the decision Grid made, and
  `simulate_transfer_outcome` returns an error.
- **`simulate_payee_check`** returns an error: Grid fixes the name check by the account
  number's suffix when the external account is created.
- **`ping`** needs a webhook URL in the Grid dashboard; this adapter does not change platform
  settings.
- **SCA** is exercised on fixtures only (US customers get no challenge); passkey assertions
  cannot be passed through `confirm_sca`.
- **`totalBalance`** lagged settled payouts on the sandbox; balances report `balance` as
  available and posted with no holds.
- **Balance-change statements** answered 501 for customer accounts; statements are built from
  the newest transactions.
- **Conversions done outside the adapter** show up as deposits into the bought currency.
- **Wallet networks** without a payments-core `Network.t` (Base, Arbitrum, Plasma, Spark) are
  left out of account addresses and cannot be paid.
