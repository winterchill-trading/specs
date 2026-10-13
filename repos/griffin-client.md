# griffin-client

Async OxCaml client and CLI for a UK banking-as-a-service API: legal persons and
onboarding, bank accounts, payments, payees, Confirmation of Payee, events and webhooks.
Sandbox by default. Navigates by the hypermedia links from the index resource instead of
hard-coded paths.

| | |
| --- | --- |
| Repository | `winterchill-trading/griffin-client` |
| opam package | `griffin-client` |
| Library | `griffin-client` (module `Griffin_client`) |
| Binary | `griffin` (`index`, `org`, `legal-persons`, `accounts`, `transactions`, `payments`, `cop`, `events`, `webhooks`, `keys`, `check-signature`; JSON, or sexps with `-sexp`); `test/live/live.exe` runs the sandbox walk under `GRIFFIN_LIVE_TESTS=1` |
| Status | done for the sandbox: the walk runs against it, and the wrapped endpoints are covered by live calls or recorded fixtures. Signed requests and real webhook deliveries are not yet verified end to end (see Known gaps) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | `of_env ?live`: base URL (sandbox by default), API key, optional signing key. Keys other than sandbox keys are refused unless `~live:true`; the key prints as `<redacted>` |
| `Secret` | Holds the API key and signing material so they do not reach logs or errors |
| `Transport` | HTTP calls: auth header, optional RFC 9421 request signing, retries with exponential backoff and `Retry-After` for idempotent calls only, an in-flight cap, a client request id on every request, `Api_error` decoding |
| `Tls` | `config ~host`: peer verification against an explicit CA bundle (`SSL_CERT_FILE` or the usual system and Homebrew paths) plus a host-name check |
| `Index`, `Links` | The hypermedia entry point (`GET /v0/index`) and the link relations it names |
| `Model` | Typed records for organizations, legal persons, verifications, decisions, bank accounts, products, payments, submissions, payees, events and webhooks, with stable JSON codecs (unknown fields ignored) |
| `Page` | List pages with `links.next` and `links.prev` cursors |
| `Client` | `connect` (refuses a live-mode organization without the opt-in), typed operations (`legal_persons`, `start_verification`, `open_account`, `wait_until_open`, `create_payment`, `submit_payment` where a 410 becomes `Already_submitted`, `create_payee`, `confirm_payee`, `simulate_confirm_payee`, `events`, `webhooks`), `get` for any link, `fold` and `pipe` over every page |
| `Claims` | Request bodies for a sandbox individual legal person with all verification claims |
| `Http_signature` | RFC 9421 signing and verification with RFC 9530 content digests (SHA-512) |
| `Ed25519`, `P521` | Signature algorithms over Zarith, since no EC library builds on the OxCaml switch |
| `Webhook` | `verify` for ES512 (P-521) delivery signatures; `Keys.fetch` reads the published key set, and `verify_refreshing` refetches it on an unknown `keyid` |
| `Api_error` | Decoded error bodies and `status_of_error`; bodies are scrubbed of the API key |

Enumerations (statuses, product classes, event types) are strings rather than variants,
because the API adds values within its version.

## Tests

- `dune test`: signature vectors (Ed25519, P-521 against OpenSSL, RFC 9421 base strings),
  transport retries and backoff, decoding of recorded sandbox responses in
  `test/fixtures/` (redacted), client flows over in-memory fixtures, webhook verification
  with a local P-521 key in the documented header format, and `test/test_tls.ml`, which
  checks that self-signed, expired, untrusted-root and wrong-host certificates are
  rejected and a good host accepted (skipped when offline).
- `GRIFFIN_LIVE_TESTS=1 dune test` (needs the environment loaded from a local `.env`,
  which is not committed): index, organization, create a legal person, verification and
  decision, open two operational accounts, an inbound Faster Payments transfer between
  them, transactions and admissions, an outbound payment and the 410 on resubmission,
  Confirmation of Payee (live and simulated), a payee and a payment to it, events,
  webhooks, signing keys, and pagination.

## Dependencies

- Depends on: no org package. External: `core`, `core_unix`, `async`, `async_ssl`,
  `cohttp`, `cohttp-async`, `conduit-async`, `uri`, `yojson`, `ppx_jane`,
  `ppx_yojson_conv`, `cryptokit`, `zarith`, `base64`.
- Used by: none in the organization yet.

## CI pin order

None: there are no sibling packages to pin. CI uses the `infra` `ox-setup` action, then
`dune build` and `dune test`, and the shared `obj-magic` workflow.

## Known gaps

- Signed requests are not verified end to end. Registering a public key is only possible
  in the provider's web app, and no key was registered for the sandbox. The signature
  format is checked against the reference library offline and against a live
  "unknown key id" answer, but no signed request has been accepted. In the sandbox a
  request signed with an unregistered key is rejected even though signing is not
  enforced.
- Real webhook deliveries are untested. Nothing here receives deliveries, and the
  organization's only webhook belongs to another integration, so it was not changed.
- Not wrapped: account closure, restrictions, holds, statements, mandates and direct
  debits, fraud claims, memberships, users, roles, API keys, invitations, account and
  payment search, open banking consents, onboarding applications, and payment PATCH
  (approvals). `Client.get` and `Client.page` reach any of them by link.
- Book transfers are supported (`~scheme:Book_transfer`), but the live walk only uses
  Faster Payments.
- `venue-net` has the same host-name gap in its TLS setup; its fix is in progress in that
  repository, not here.
