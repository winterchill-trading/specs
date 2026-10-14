# otp-mail

OCaml and Async one-time codes and transactional email: numeric codes stored only as an HMAC,
single use, one purpose per code, with lockouts; typed localised email templates; RFC 5322 and
MIME rendering and parsing; DKIM signing; and one mailer interface with an in-memory inbox, an
SMTP submission client and a webhook sink. It keeps no state of its own: services implement the
store interface over their own database. The CLI is offline and never sends email, and the
library is not a mail transfer agent (no MX lookup).

| | |
| --- | --- |
| Repository | `winterchill-trading/otp-mail` |
| opam package | `otp-mail` |
| Library | `otp-mail` (module `Otp_mail`), plus `otp-mail.testing` |
| Binary | `otp-mail` (`address`, `render`, `dkim-record`, `dkim-verify`, `check-templates`) |
| Status | done: library, test SMTP server, CLI and examples are in place; first release pending |

## Key modules

| Module | Purpose |
| --- | --- |
| `Otp` | Pure code logic: issue and verify, HMAC-SHA256 under a rotatable `Key`, `Purpose` (sign-in, passcode reset, payment bound to amount and payee), `Config`, stable `Record` and `Challenge` |
| `Otp_store` | Store interface `S` with `load` and `save ~expected_version`; `Memory` store; `check` contract scenarios |
| `Otp_service` | `Make (Store)`: issue and verify over a store, retrying on version conflicts |
| `Rng` | Random sources: `/dev/urandom` and a seeded ChaCha20 source; uniform digits |
| `Address`, `Mailbox` | RFC 5322 addr-spec validation (ASCII only), display names, address lists |
| `Mime` | Base64, quoted-printable, encoded words, header folding, content types, entity parser |
| `Message`, `Message_id` | Render to RFC 5322 with MIME and parse back; `Message-ID` values |
| `Dkim` | `rsa-sha256` signing, simple and relaxed canonicalization, DNS key records, test verifier |
| `Template`, `Code_email` | Typed templates per locale with `Catalogue.check`; code email in six languages |
| `Mailer` | Sending interface, delivery ids, statuses, events, send errors, `Event_feed`, idempotency |
| `Simulated_inbox` | In-memory mailer that renders and parses back each message; queryable |
| `Smtp` | Submission client: STARTTLS, implicit TLS, AUTH PLAIN and LOGIN, configuration from env |
| `Webhook_sink` | Constant-time HMAC check of webhook bodies; deduplicating sink into an event feed |
| `Fake_smtp` | In `otp-mail.testing`: a local SMTP server for tests |

Rules enforced by `Otp`:

- Digits are drawn uniformly (6 by default, 4 to 10); a code is stored only as an HMAC over the
  challenge id, purpose and code.
- One outstanding code per subject and purpose kind; a code verifies only for its purpose and,
  for payments, the same amount and payee.
- Codes expire (10 minutes by default) and are accepted once.
- Consecutive failures are kept across re-sent codes; the limit starts a doubling lockout.
- Comparison is constant time, and codes and keys print as `<redacted>`.

## Tests

- `dune test`: expect tests per module, a cram test for the CLI, and Quickcheck properties for
  MIME round trips and for random one-time code sessions.
- SMTP tests run against `Fake_smtp` on 127.0.0.1: plain, STARTTLS, implicit TLS, AUTH, refused
  recipients, 4xx and 5xx replies, and TLS failures (wrong host, untrusted chain).
- DKIM is checked against the RFC 6376 canonicalization example and against signatures from an
  independent implementation in both directions (fixtures).
- Digests of the stable bin_prot types are pinned; HMAC is checked against RFC 4231.
- `dune build @examples/runtest` diffs two example programs against checked-in output.

## Dependencies

- Depends on: no org package. External: `core`, `core_unix` (CLI and tests), `async`,
  `async_ssl` (needs OpenSSL), `cryptokit` (needs GMP), `ppx_jane`.
- Used by: none yet.

## CI pin order

CI pins no sibling repository. It sets up the toolchain with the shared `ox-setup` action, runs
`dune build`, `dune test` and `dune build @examples/runtest`, then the shared `obj-magic`
workflow.

## Known gaps

- No connection reuse or pipelining: one SMTP connection per message.
- No MX lookup: `Smtp` submits to one relay.
- No `ed25519-sha256` DKIM (RFC 8463); RSA keys only.
- `Dkim.verify` checks the first signature against a given key; it does not fetch DNS records
  or honour `l=`, `i=` and `x=`.
- No SMTPUTF8: addresses must be ASCII.
- `Mime.Content_type.parse` does not accept comments or RFC 2231 parameter continuations.
- Idempotency keys are remembered in memory per mailer value; a service that sends from several
  processes keeps its own outbox keyed by request.
