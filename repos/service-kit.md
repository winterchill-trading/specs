# service-kit

Building blocks for Async HTTP services on cohttp-async: typed routes with a middleware chain,
RFC 9457 problem responses with stable codes, structured messages for client-side
localisation, idempotency keys with stored-response replay, signed sessions, step-up grants,
rate limits, request logs, health, metrics, CORS and cursor pagination. Each module is
independent and tested without a database. It deliberately keeps no persistent state: anything
that needs storage sits behind a module type with an in-memory implementation, and a service
supplies the durable one.

| | |
| --- | --- |
| Repository | `winterchill-trading/service-kit` |
| opam package | `service-kit` |
| Library | `service-kit` (module `Service_kit`) |
| Binary | none (examples only: `quick_start`, `transfers`) |
| Status | done: all modules, examples and tests are in place; first release is unreleased |

## Key modules

| Module | Purpose |
| --- | --- |
| `Router` | Typed paths, method dispatch with 404 and 405 (`Allow`), global and per-route middleware |
| `Request`, `Response` | Request with its body read and a context map for middleware; JSON, text and problem responses |
| `Server` | cohttp-async adapter: body size limit (413), exceptions answered 500, peer address |
| `Problem` | RFC 9457 `application/problem+json` with validated codes and typed params, no free text |
| `Message` | Structured messages (code + typed params) and a `Catalogue` with per-locale templates and coverage checks |
| `Param` | Typed values carried by problems and messages: string, int, bool, decimal, time, list |
| `Idempotency` | `Idempotency-Key` middleware: replay, 409 on reuse or in-flight, retention, `Store` module type with `Memory_store` |
| `Session` | HMAC-SHA256 tokens, keyring for key rotation, rotation up to a maximum lifetime, revocation hook |
| `Step_up` | Single-purpose, session-bound, time-bound grants; check, single-use consume, `require` middleware |
| `Rate_limit` | Token buckets (GCRA) with integer arithmetic and bounded key tables; 429 with `Retry-After` |
| `Request_log` | One structured entry per request, request ids (`X-Request-Id`), header and query redaction |
| `Health` | `/healthz` and `/readyz` with concurrent checks, timeouts, non-critical checks and draining |
| `Metrics` | Prometheus counters, gauges, histograms, per-route request metrics and a `/metrics` route |
| `Cors` | Origin allow lists, preflight answered before routing, exposed headers |
| `Pagination` | Versioned, optionally signed keyset cursors, `limit` parsing, pages from an over-fetch |
| `Clock` | Injectable time with a manual clock; no module reads the wall clock itself |

Rules the modules follow:

- Error bodies carry a stable `code` and typed params; the server never chooses the language.
- Idempotency never stores 5xx, 401, 403, 409 or 429 answers, so a retry can succeed.
- Tokens and grants are signed, not encrypted; they carry ids and times, never personal data.
- `Stable` modules (`Param`, `Message`, `Idempotency`, `Step_up`, `Pagination`) have pinned
  bin_prot digests; a change to a pinned shape needs a new stable version.

## Tests

- `dune test`: ppx_expect tests and Quickcheck properties per module, with shared generators
  in `test/gens.ml`.
- `test/test_server.ml` runs the router over real HTTP on a free port; the other tests do not.
- HMAC-SHA256 is checked against RFC 4231 test case 2 and base64url against RFC 4648 vectors.
- `examples/test_transfers.ml` drives the `transfers` example end to end (sign-in, step-up,
  idempotent transfers, cursor pages, health, metrics, CORS, rate limits, request logs).

## Dependencies

- Depends on: no org package. External: `core`, `async`, `ppx_jane` (v0.17 to v0.19),
  `cohttp`, `cohttp-async` and `http` (6.0 or later), `uri`, `yojson` (2.2 to 4.0), `cryptokit`
  (1.16 or later); `core_unix` and `expect_test_helpers_core` for tests.
- Used by: none yet.

## CI pin order

CI pins no sibling repositories. It runs the shared `ox-setup` action without a `pins:` block,
then `dune build`, `dune build @examples/all` and `dune test`, and the shared `obj-magic`
workflow.

## Known gaps

- No websocket helpers; `Server.to_cohttp` serves plain HTTP responses only.
- No persistent `Idempotency.Store` or `Step_up.Spent` implementation ships here, by design.
- Session claims are signed but readable; there is no encrypted token format, because the
  cryptokit on the switch has no AEAD cipher.
- `Rate_limit` keeps buckets per process, so several instances each enforce their own limit.
