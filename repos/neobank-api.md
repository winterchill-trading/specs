# neobank-api

The HTTP API of the [neobank demo](../design/neobank.md): sessions with strong customer
authentication, KYC, accounts and statements, beneficiaries, SEPA, on-chain and Lightning
transfers through risk rules and SCA, swaps, virtual cards, standing orders, provider
webhooks, websocket pushes, an operator review queue and ops views. It runs over the
`Provider.S` of [banking-provider](banking-provider.md): the deterministic fake offline,
or Striga's sandbox through `striga-provider` once that lands on `main`.

| | |
| --- | --- |
| Repository | `winterchill-trading/neobank-api` |
| opam packages | `neobank-api` (library `Neobank_api`, binary `neobank-api`); `neobank-api-types` (library `Neobank_api_types`, depends on `core` and `yojson` only, shared with `neobank-web`) |
| Binary | `neobank-api [-port] [-provider fake or striga] [-store memory or postgres] [-database-url] [-state-dir] [-policy] [-allow-origin] [-fake-settlement] [-fake-sca]`; `DATABASE_URL`, `NEOBANK_OPS_TOKEN` and `STRIGA_*` from the environment |
| Status | done on the fake provider: CI runs the curl walk on the memory store and on PostgreSQL. `-provider striga` is on branch `striga-provider` until `striga-provider` adopts `Sandbox.S` |
| Storage | PostgreSQL database `neobank` through [pg-async](pg-async.md), behind `Store.S` ([ADR 0009](../adr/0009-postgres-replaceable-store.md)); the ledger journal under `-state-dir` stays the system of record |

## Endpoints

| Area | Routes |
| --- | --- |
| Health | `GET /healthz`, `GET /metrics` |
| Sessions | `POST /auth/signup`, `/auth/login`, `/auth/step-up`, `/auth/logout`; `GET /me` |
| KYC | `GET /kyc`, `POST /kyc/start`, `POST /kyc/complete` |
| Accounts | `GET /accounts`, `GET /accounts/:id`, `GET /accounts/:id/statement?from=&until=&format=csv` |
| Payments | `GET`/`POST /beneficiaries`, `POST /beneficiaries/:id/trust`, `POST /transfers/quote`, `POST /transfers`, `GET /transfers[/:id]`, `POST /transfers/:id/confirm-sca`, `/sca`, `/cancel` |
| Swaps | `POST /swaps/quote`, `POST /swaps/:id/execute`, `GET /swaps[/:id]` |
| Cards | `GET`/`POST /cards`, `GET /cards/:id`, `POST /cards/:id/freeze`, `/unfreeze`, `/limits`, `/pan-token`, `/consent`; `GET /cards/:id/display` |
| Standing orders | `GET`/`POST /standing-orders`, `DELETE /standing-orders/:id` |
| Provider codes | `POST /sca/:id` (the provider's own challenge for a swap, order or card number) |
| Pushes | `GET /ws?token=` (`transfer`, `account`, `kyc`, `card`, `swap`, `standing_order`) |
| Webhooks | `POST /webhooks/provider` (verified on the raw bytes before parsing) |
| Operators | `GET /ops/review`, `POST /ops/review/:id`, `GET /ops/outbox`, `GET /ops/audit`, `GET /ops/ledger`, `GET /ops/ledger/postings?account=` |
| Sandbox | `POST /sandbox/kyc-decision`, `/sandbox/deposit`, `/sandbox/card-auth`, `/sandbox/transfer-outcome` (only with a provider sandbox) |

Every `POST` except `/auth/*` and `/webhooks/*` needs an `Idempotency-Key` header. Idempotency
keys are kept 24 hours and bound to a hash of the body.

## Key modules

| Module | Purpose |
| --- | --- |
| `Store`, `Store_memory`, `Store_pg`, `Any_store` | `Store.S` with `commit` over batches; the in-memory store and the PostgreSQL store, the only module with SQL |
| `Bank`, `Ctx`, `Model` | The bank over `Provider.S`, its context and the domain records |
| `Auth`, `Password`, `Totp` | Sessions, PBKDF2 passwords, RFC 6238 authenticator codes |
| `Onboarding`, `Accounts`, `Payments`, `Swaps`, `Cards`, `Standing_orders` | Journeys over `kyc-core`, `payments-core`, `card-core` |
| `Provider_sca`, `Risk_policy` | Provider challenges; the `risk-rules` policy every outgoing transfer is evaluated against |
| `Events`, `Relay`, `Ledger_projection` | Inbox of provider events, outbox relay with backoff, projection of the ledger journal |
| `Views`, `Redact`, `Incident`, `Metrics`, `Hub` | Ops views, masking of card numbers and IBANs, DORA incident classification, Prometheus metrics, websocket hub |
| `Sandbox_api`, `Keyed_lock`, `Problem`, `Ids`, `Server` | Sandbox triggers, per-process locks, error bodies, identifiers, the HTTP routes |

## Storage

`Store.S` (`lib/store_intf.ml`) holds the API's state in domain types: customers, sessions,
KYC events, accounts, beneficiaries, transfers, swaps, cards, standing orders, reviews,
outbox, inbox, idempotency keys, the audit chain and the ledger projection. All writes go
through `commit`, which applies a batch atomically. `Store_pg` keeps each record's Bin_prot
bytes in a `body` column next to the columns queries use. Migrations `0001` to `0003`
(init, ledger projection, provider links) are embedded in the binary and applied at startup
under pg-async's advisory lock.

`test/store_suite.ml` prints one transcript of store behaviour; `test/test_store.ml` runs it
on both stores with the same expected output, and `test/test_flow.ml` runs the HTTP walk on
both. The API owns its database; nothing joins across services.

## Tests

| What | Verified on |
| --- | --- |
| PBKDF2, TOTP, base32 | RFC 7914, RFC 6238 and RFC 4648 vectors |
| Store behaviour | one transcript, memory and PostgreSQL |
| The HTTP walk: routes, idempotency, wrong factors, review, refusal, stale SCA, webhook redelivery and forgery, standing order run, ledger balance | fake provider, memory and PostgreSQL |
| Quickcheck: request hash, outbox backoff (found a retry-delay overflow, fixed), masking | properties |
| DORA classification and deadlines | expect tests |
| The curl walk | CI, against the binary, memory and PostgreSQL |

Nothing is verified live against the provider.

## Dependencies

- Depends on: `banking-provider`, `risk-rules`, `pg-async`; `striga-provider` on the
  `striga-provider` branch only.
- Pinned for CI and used through `banking-provider`: `money`, `ledger`, `kyc-core`,
  `payments-core`, `card-core`, `fixed-decimal`.
- Used by: [neobank-web](neobank-web.md) (through `neobank-api-types`), and the planned
  compose profile `neobank` in [infra](infra.md).

## CI pin order

`fixed-decimal`, `money`, `ledger`, `kyc-core`, `payments-core`, `card-core`, `risk-rules`,
`banking-provider`, `pg-async`.

## Known gaps

- `-provider striga` is written and compiles on branch `striga-provider`, but is not on
  `main`: the pushed `striga-provider` still has `Provider.Sandbox`, which `banking-provider`
  renamed to `Sandbox.S`.
- KYC screening and risk rating are not run by the API: the demo KYC policy trusts the
  provider's decision (`Ctx.Config.demo_kyc_policy`).
- Personal data in KYC events is stored as Bin_prot without per-customer encryption.
- Per-record locks are per process: run one API instance.
- Provider challenges answered through `/sca/:id` are remembered in memory; after a restart
  the customer starts the operation again.
- No rate limiting beyond the SCA lock and no device binding.
- Card authorizations and clearings are counted, not stored per card.
- With the fake provider the bank's customers live in memory, so restarting over a kept
  database loses their provider records: start with a fresh database and state directory,
  or use `-store memory`.

See [design/neobank.md](../design/neobank.md) for the demo's design.
