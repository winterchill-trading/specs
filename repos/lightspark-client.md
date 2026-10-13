# lightspark-client

Async OxCaml client and CLI for two payment APIs: a Lightning and UMA GraphQL server API
(nodes, wallets, invoices, payments, test mode) and a banking-style Grid REST API
(customers, internal accounts, transfers, exchange rates, quotes, sandbox tools). Both
have webhook signature verification. Sandbox by default.

| | |
| --- | --- |
| Repository | `winterchill-trading/lightspark-client` |
| opam package | `lightspark-client` |
| Library | `lightspark-client` (module `Lightspark_client`) |
| Binary | `lightspark` (`account`, `nodes`, `wallets`, `transactions`, `invoice`, `fund-node`, `grid ...`, `webhook ...`; JSON, or sexps with `-sexp`); `test/live/live_check.exe` prints one `skip` line without credentials and runs the reads and the sandbox write flow with them |
| Status | done for the Grid API: the reads and the sandbox write flow pass live (2026-10-13). The GraphQL API is covered by fixtures and by a 401 answer only, because no Lightning token was available (see Known gaps) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | Credentials, endpoints and mode from the environment. `Sandbox` by default; `Live` needs `~live:true` (CLI `-live`). The secret prints redacted |
| `Auth` | HTTP Basic header, `redact` and `redact_headers` so credentials stay out of logs and errors |
| `Transport` | One HTTP exchange (cohttp-async) with its own TLS config: peer verification plus a host-name check against the URI host. `Retry` retries 429 always, and 408/425/5xx/timeouts only for idempotent calls, honouring `Retry-After`. `record` writes status and body only, for fixtures |
| `Api_error` | `Http` (status, Grid `code` and `reason`, request id), `Graphql` (errors with `error_name`), `Rate_limited`, `Transport`, `Decode` and `Refused` |
| `Graphql` | POST a document with variables; returns `data` or a typed error. A partial result can carry both |
| `Documents` | GraphQL documents with the official SDK fragments and field aliases |
| `Lightning_types`, `Lightning` | Account, nodes and balances, wallets, transactions (connections), invoices, decoded payment requests, and test-mode writes |
| `Grid_types`, `Grid` | Platform config, customers, internal accounts, transactions, exchange rates, quotes; `all_pages`; sandbox funding, customer creation, quote create and execute |
| `P256` | ECDSA P-256 over SHA-256 verification on zarith (PEM SPKI keys; DER or raw signatures) |
| `Webhook` | `Webhook.Lightspark.verify` (HMAC-SHA256 hex, `lightspark-signature`) and `Webhook.Grid.verify` (`X-Grid-Signature`, P-256) |

Write guards: GraphQL writes that move funds or create invoices first read the node's
network and refuse unless it is REGTEST. Grid writes that move money first read
`GET /config` and refuse unless the platform looks like a sandbox (its UMA domain and
proxy subdomain contain `sandbox`), because the API has no explicit sandbox flag.

Enumerations are strings rather than variants where the API adds values over time.

## Tests

- `dune test`: fixture tests over redacted Grid responses recorded from the sandbox and
  GraphQL bodies in the official SDK's response shape (plus the live 401 body); retry,
  redaction and P-256 unit tests; `test/tls`, which checks that expired, self-signed and
  wrong-host certificates are rejected and a good host is accepted (skipped when offline).
- `test/live/live_check.exe`: with credentials in the environment it runs the Grid reads and
  the GraphQL account read. With `LIGHTSPARK_LIVE_WRITES=1` it also creates a sandbox
  customer, funds its USD account, quotes and executes a small USD to USDC conversion into
  the customer's own account, and reads the transaction back. It prints counts and
  statuses only, never ids or personal data. CI has no credentials, so it only prints `skip`.

## Dependencies

- Depends on: no org package. External: `core`, `core_unix`, `async`, `async_ssl`,
  `conduit-async`, `cohttp`, `cohttp-async`, `uri`, `yojson`, `ppx_jane`,
  `ppx_yojson_conv`, `base64`, `cryptokit`, `zarith`.
- Used by: none in the organization yet.
- It does not use `venue-net`, because it needs response headers (`x-request-id`,
  `Retry-After`) and its own TLS configuration.

## CI pin order

None: there are no sibling packages to pin. CI uses the `infra` `ox-setup` action with an
empty pins list, then `dune build` and `dune test`, and the shared `obj-magic` workflow.

## Known gaps

- GraphQL is not verified live. The only token available was a Grid token, which the
  GraphQL endpoint rejects with 401. Documents and decoders are tested on fixtures shaped
  like the SDK responses; the first run with a GraphQL token may need alias or field fixes
  (in particular `balances` on the node interface).
- Signed GraphQL mutations: `pay_invoice` works only for remote-signing nodes. Nodes with
  an OSK need the `X-Lightspark-Signing` request signature, which is not implemented.
- UMA sends fail in this sandbox. The documented sandbox UMA address is rejected as an
  invalid address, a UMA address on the platform's own customers fails until the receiving
  platform's webhook approves the payment, and transfers between two customers are disabled
  for this platform. The live write flow therefore converts USD into the same customer's
  USDC account.
- Grid customers need a deliverable email when the platform has embedded wallets.
- Not wrapped: external accounts, KYC and documents, cards, SCA, agents, embedded-wallet
  authentication, UMA invitations, Grid API token management, and webhook endpoint
  configuration (account settings are deliberately not touched).
- TLS: the host-name check is fixed here. `venue-net` has the same gap in its TLS setup;
  its fix is in progress in that repository.
