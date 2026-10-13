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
| `Api_error` | Striga error bodies; `status_of_error` and `code_of_error` recover the HTTP status and `errorCode` |
| `Call` | Endpoint plumbing for the resource modules: call, check and decode |
| `Wire` | JSON helpers shared by the resource modules |
| `Common` | Small records shared by several resources; lenient decoding (unknown fields ignored, absent or `null` optional fields become `None`) |
| `User` | Consumers: create, email and mobile verification, KYC start and status |
| `Wallet` | Wallets and accounts, IBAN and crypto deposit details, enrichment |
| `Transaction` | Transaction lists and single transactions |
| `Exchange` | Rates and swaps (with OTP) |
| `Payment` | SEPA, on-chain and Lightning payouts with OTP, address whitelist, intraledger transfers |
| `Card` | Virtual cards: create, freeze and unfreeze, limits, settings, statements, close; `Card.Pan_ui.browser_options` for the browser PAN component |
| `Standing_order` | Create, confirm (OTP) and cancel recurring transfers |
| `Sca` | PSD2 strong customer authentication: TOTP enrollment, the unified login that opens a 180-day SCA session, security events, trusted beneficiaries |
| `Totp` | RFC 6238 codes (HMAC-SHA1, 30 s, 6 digits); used by the live walk and dev tools to act as the user's authenticator. A real application never holds the user's TOTP secret |
| `Simulator` | `/simulate/...` stand-ins for events that start outside the application (KYC decision, incoming SEPA, card at a till); each refuses any host that is not the sandbox |
| `Webhook` | Verifies the signature on an incoming webhook |

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
  order create with challenge.
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

- EUR and USDC provisioning takes minutes after KYC approval; the live walk must allow for
  it.
- The sandbox does not fund crypto. On-chain payouts, crypto intraledger transfers and
  Lightning payouts stop at their balance or invoice checks; they are not exercised past
  that point.
- EUR intraledger transfers are not verified against the sandbox.
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
