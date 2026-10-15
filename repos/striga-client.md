# striga-client

OCaml/Async client and `striga` command line tool for the Striga v1 API: consumers and KYC,
wallets and IBAN deposit details, swaps, intraledger, SEPA, on-chain and Lightning payments
with OTP confirmation, virtual cards, standing orders, strong customer authentication, the
sandbox simulator and webhook verification. Sandbox by default; any other host needs
`~live:true`. It is the provider SDK under the neobank demo (see
[design/neobank.md](../design/neobank.md)).

| | |
| --- | --- |
| Repository | `winterchill-trading/striga-client` |
| opam package | `striga-client` |
| Library | `striga_client` |
| Binary | `striga` (CLI over the API, including `sim` and `card` groups); `test/live/live.exe` walks the sandbox under `STRIGA_LIVE_TESTS=1` |
| Status | done for the sandbox: the live walk below has run against it; the wrapped endpoints are covered by live calls or recorded fixtures. CI green. Open items in Known gaps |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | Base URL (sandbox by default), API key and secret from the environment. Any other host is refused unless created with `~live:true` |
| `Secret` | Holds the API key, HMAC secret and other credentials so they do not reach logs or errors |
| `Signature` | HMAC-SHA256 request signing (`Authorization: HMAC <ms>:<hex>` over the timestamp, method, path and MD5 of the body) and webhook signatures |
| `Tls` | Peer verification against an explicit CA bundle, plus a host-name check |
| `Redact` | Masks credentials, card numbers, IBANs and one-time tokens (SumSub, PAN auth, TOTP secrets, recovery codes, PINs) in anything that may be logged |
| `Transport` | HTTP calls with the `api-key` header and signature, `Api_error` decoding, and event logs with no credentials |
| `Api_error` | Striga error bodies; `status_of_error` and `code_of_error` recover the HTTP status and `errorCode`; `is_sca_session_required` spots `30070` |
| `Call` | Endpoint plumbing for the resource modules: call, check and decode |
| `Wire` | JSON helpers shared by the resource modules |
| `Common` | Small records shared by several resources; lenient decoding (unknown fields ignored, absent or `null` optional fields become `None`) |
| `User` | Consumers: create, email and mobile verification, KYC start (with share token) and status, Payment Account consent, verified-email change, PII read |
| `Wallet` | Wallets and accounts, IBAN and crypto deposit details, enrichment |
| `Transaction` | Transaction lists and single transactions |
| `Exchange` | Rates and swaps (with OTP) |
| `Payment` | SEPA, on-chain and Lightning payouts with OTP, address whitelist, intraledger transfers |
| `Card` | Virtual cards: create, freeze and unfreeze, limits, settings, statements, close, replace, physical activation; `Card.Pan_ui.browser_options` for the browser PAN component |
| `Standing_order` | Create, confirm (OTP) and cancel recurring transfers |
| `Sca` | PSD2 strong customer authentication: TOTP enrollment, the unified login that opens a 180-day SCA session (needed for EUR and USDC to be listed), security events, trusted beneficiaries, passkeys, 2FA reset |
| `Totp` | RFC 6238 codes (HMAC-SHA1, 30 s, 6 digits); used by the live walk and dev tools to act as the user's authenticator. A real application never holds the user's TOTP secret |
| `Simulator` | `/simulate/...` stand-ins for events that start outside the application (KYC decision, incoming SEPA, card at a till); each refuses any host that is not the sandbox |
| `Webhook` | Verifies the signature on an incoming webhook and decodes it by channel; `Webhook.notice` types enrichment, review, standing-order, debt, KYC-action, KYB and travel-rule deliveries |

## Tests

- `dune test`: unit tests for signing, `Api_error`, configuration, redaction, secrets, TLS
  (`test_tls.ml`), TOTP, transport retries, wire codecs, and the per-resource request and
  response shapes. Responses come from `test/fixtures/` (redacted) through `Fixture`.
- `STRIGA_LIVE_TESTS=1 dune test` runs the live walk from `test/live/`. It needs the
  sandbox credentials in the environment; they are not committed.
- The live walk has passed for: onboarding with KYC simulation; wallets, accounts and
  enrichment (EUR IBAN, BTC, ETH); EUR deposit simulation; EUR to USDC swap with OTP; SEPA
  payout with OTP and settlement simulation; virtual cards (freeze, limits, settings,
  statement, close, approved and declined authorisation simulation); TOTP enrollment and SCA
  login; Lightning invoice; address whitelist; rates; statements; webhook ping; standing
  order create with challenge; EUR intraledger between two users (after opening an SCA
  session for each right after KYC approval).
- Checked from the CLI against the sandbox (2026-10-15): Payment Account consent set and
  read, the SMS 2FA reset (initiate, simulated liveness, status, complete), KYC share token,
  card replace, passkey list.
- `docs/api-coverage.md` in the repository lists every endpoint found in public sources
  (API reference, its Postman collection, public example code) with its status: 103
  consumer-side rows, 55 live, 8 fixture, 32 wrapped but untested, 1 missing
  (`/standing-orders/update-fees`, body not published), 7 not planned; business,
  corporate and travel-rule families are not planned.
- HMAC signing is checked against the sample vector in the provider's documentation.

## Environment

| Variable | Required | Purpose |
| --- | --- | --- |
| `STRIGA_API_KEY` | yes | `api-key` header; webhook signature key |
| `STRIGA_API_SECRET` | yes | HMAC request signatures |
| `STRIGA_BASE_URL` | no | default is the sandbox base URL |
| `STRIGA_APPLICATION_ID` | no | card PAN browser component only (`Card.Pan_ui`) |
| `STRIGA_UI_SECRET` | no | card PAN browser component only (`Card.Pan_ui`) |
| `STRIGA_LIVE_TESTS` | no | `1` lets `dune test` run the live sandbox walk |

Credentials are read from the environment only. The application ID and UI secret are for
the browser card-display component; the REST API uses the API key and secret.

## Dependencies

- Depends on: no org package.
- External: `core`, `core_unix`, `async`, `async_ssl`, `cohttp`, `cohttp-async`,
  `conduit-async`, `uri`, `yojson`, `ppx_jane`, `ppx_yojson_conv`, `cryptokit`, `base64`.
- Used by: `striga-provider` (planned, see [design/neobank.md](../design/neobank.md)).

## CI pin order

None: there are no sibling packages to pin. CI uses the `infra` `ox-setup` action, then
`dune build` and `dune test`, and the shared `obj-magic` workflow. Live tests are skipped
in CI because it has no sandbox credentials.

## Known gaps

- The sandbox's `/wallets/get` and `/wallets/get/all` leave out the EUR and USDC accounts
  until the user has an SCA session; they exist and are `ACTIVE` from KYC approval on.
  What looked like a provisioning delay was the accounts being unlisted. Without a session
  `/wallets/get/account` on EUR answers 403 `SCA_REQUIRED` (`NO_SESSION`); the live walk
  opens a session (SMS login) right after approval.
- The sandbox does not fund crypto. On-chain payouts, crypto intraledger transfers and
  Lightning payouts stop at their balance or invoice checks; they are not exercised past
  that point.
- Standing-order confirm and cancel are not verified against the sandbox.
- PAN display needs the browser component; the consent step cannot run from the CLI.
- Not wrapped: business (KYB) onboarding, travel-rule records, passkeys, 2FA reset, card
  tokenization.

## Quirks

- Request bodies must be compact JSON: the body digest in the signature is computed over the
  compact form, which the client sends.
- Webhooks are signed with the API key, as the provider documents.
- Payouts to the user's own IBAN, and intraledger transfers between accounts of one user,
  are refused by the sandbox.
- Completing a 2FA reset revokes the user's SCA session: EUR and USDC leave the wallet
  listing again until the next login.
- Passkeys are not enabled for the sandbox application, so the passkey wrappers are pinned
  offline only.
- New webhook kinds go into `Webhook.Notice.t`, not `Webhook.Event.t`, which
  `striga-provider` matches exhaustively.
