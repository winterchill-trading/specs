# neobank-web

The browser app of the [neobank demo](../design/neobank.md): sign-up and sign-in with an
authenticator, identity verification, accounts with IBAN and deposit addresses, payments
over SEPA, on-chain and Lightning with strong customer authentication, swaps, virtual
cards, standing orders, statements, payees and an operator review queue. It is OCaml
compiled to JavaScript with js_of_ocaml and built with Bonsai. It talks only to
[neobank-api](neobank-api.md), whose request and response types it shares.

| | |
| --- | --- |
| Repository | `winterchill-trading/neobank-web` |
| opam package | `neobank-web` (a web app, not a library) |
| Binary | `bin/main.bc.js`, installed as `share/neobank-web/{index.html,main.js}` by the infra `web` image target; `scripts/dev.sh` builds and serves on port 8000 (`-r` for the release profile) |
| Status | done: model and mock-bank tests, the browser smoke on the mock and the live smoke against neobank-api on the fake provider are green in CI; release `main.js` is 1.7 MB (514 KB gzipped) |
| Tool | none installed outside the repository; the app reads no credentials, the card component's application id and UI secret and the identity SDK's token come from the API at runtime |

## Modes

- `?mock=1` runs on the built-in mock bank, no server needed.
- `?api=<url>` talks to a running neobank-api.
- With no query the app expects the API under `/api` on its own origin, as the compose and
  chart nginx serve it.

## Layout

| Directory | What |
| --- | --- |
| `model/` | Plain OCaml, also built natively for the tests: routes, API paths, amounts in minor units (Zarith, so 18-decimal ETH stays exact), formatting, field checks (IBAN mod 97, BIC, addresses, Lightning invoices, codes), statement CSV, a QR encoder, refusals and the mock bank |
| `ui/` | Bonsai components: one module per page, the backend (live over `XMLHttpRequest` or the mock), forms, the step-up flow and the glue to the two provider components |
| `bin/` | The `main.bc.js` entry point and the installed static site |
| `static/` | `index.html` with the stylesheet (light and dark) |
| `smoke/` | The compiled app under node with a fake DOM: `run.js` walks every page on the mock, `live.js` runs against a running API |

## Pages

| Route | Page |
| --- | --- |
| `#/sign-up`, `#/sign-in` | Details, then the authenticator key once as a QR code; email, password and code (a login is SCA) |
| `#/onboarding` | KYC steps: email and mobile codes, document and liveness in the identity SDK, a sandbox approval button |
| `#/dashboard` | Balances per currency, recent activity |
| `#/accounts`, `#/accounts/:id` | IBAN or deposit address with a QR code, the last 30 days, a sandbox deposit |
| `#/send`, `#/transfers/:id` | SEPA (standard or instant), crypto or Lightning with a fee quote; answers our challenge and then the provider's code, reloads until final |
| `#/swap` | Quote with a countdown, execute with fresh SCA, the provider's code when asked |
| `#/cards` | Issue a virtual card, freeze and unfreeze, limits, card details through the provider's component |
| `#/standing-orders` | Daily, weekly or monthly orders, confirmed with the provider's code |
| `#/statements` | Any account and period; CSV built in the browser |
| `#/beneficiaries` | Payees with the IBAN check, the name check result and trust |
| `#/review` | Operators: approve or reject held payments (needs the ops token) |

An action the API refuses with `sca_required` shows a password and code form in place; after
the step-up the customer presses the button again. Pages reload after every change and on
every push from the API's `/ws`. Every `POST` outside `/auth` carries a fresh
`Idempotency-Key`.

## Provider components

Two pages embed the provider's own components, loaded only on first use (URLs in
`model/hosted.ml`, glue in `ui/hosted_js.ml`):

- **Identity verification** runs in the KYC vendor's WebSDK with the access token from
  `POST /kyc/start`, refreshed through the same route. Results reach the API by webhook; the
  page polls the status.
- **Card number, CVV and PIN** are drawn by the card display plugin in its own iframes. The
  plugin is created with the application id and UI secret from `GET /cards/:id/display`, the
  customer consents (`requestConsent`), the API learns the challenge
  (`POST /cards/:id/consent`), the code goes to `POST /sca/:id` and `POST /cards/:id/pan-token`
  returns the token. Neither this app nor the API sees the number.

A deployment with a Content-Security-Policy must allow those two script hosts in `script-src`
and `frame-src`. In mock mode both components are replaced by stand-ins.

## Tests

- Expect and Quickcheck tests of the model: amounts round-trip for every currency, one changed
  IBAN digit is always caught, the QR encoder matches the qrcodegen reference on seven inputs,
  and scenario tests of the mock bank (SCA attempts, provider codes, review, step-up, swaps,
  sign-up to verified).
- `smoke/run.js`: the compiled app on the mock, 12 steps through every page.
- `smoke/live.js`: skipped unless `API_URL` is set; `scripts/live-smoke.sh` builds the sibling
  neobank-api, starts it on the fake provider with the memory store and runs 9 steps over
  HTTP: sign-up with computed authenticator codes, KYC with the sandbox decision, deposit,
  SEPA with SCA, swap, card with the provider's code, standing order, statement CSV, and a
  held payment released by an operator.

## Dependencies

- Depends on: `neobank-api-types` (the `neobank-api` repository, that package only), `core`,
  `zarith`, `yojson`, `bonsai_web`, `virtual_dom`, `js_of_ocaml`, `async_kernel`.
- Pinned for CI: `neobank-api-types` only.
- Used by: the infra `web` image target and the planned compose profile `neobank`
  ([infra](infra.md)).

## Known gaps

- The README's API coverage table still lists `GET /cards/:id/display` and
  `POST /cards/:id/consent` as missing from neobank-api. Both routes are on neobank-api's
  `main` (added after that README was written), so the table is stale and the card details
  page needs a live check against them.
- The identity SDK and the card plugin are not exercised by tests; the KYC SDK script URL
  comes from the vendor documentation and is hard-coded.

See [design/neobank.md](../design/neobank.md) for the demo's design.
