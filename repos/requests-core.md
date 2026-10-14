# requests-core

OCaml money requests, payment links and bill splits between customers of the same institution,
as pure state machines. Each transition takes the value and a time and returns the next value,
the notices to deliver and, when money moves, a settlement instruction that is booked as
intraledger transfers through payments-core with deterministic idempotency keys. It does not
persist anything, send notices, move money by itself, or convert currencies; those belong to the
service and to payments-core and ledger.

| | |
| --- | --- |
| Repository | `winterchill-trading/requests-core` |
| opam package | `requests-core` |
| Library | `requests_core` (module `Requests_core`) |
| Binary | none |
| Status | done: library, examples and property tests are in place; CI configured |

## Key modules

| Module | Purpose |
| --- | --- |
| `Customer_id`, `Request_id`, `Link_id`, `Split_id` | Checked ids (1 to 48 characters of `[A-Za-z0-9_.-]`) |
| `Note` | Normalised short text (35 characters) for notes and titles |
| `Party` | A customer id with a display name |
| `Policy` | Request lifetime, reminder gap and count, link cap bound, split size |
| `Request_status`, `Request` | Request state machine: `create`, `apply` (pay, decline, cancel, remind), `expire`, `status`, `actions` |
| `Link_token`, `Link_status`, `Link` | Payment links behind random tokens: `create`, `pay`, `revoke`, `status`, `public_view` |
| `Split` | `equal_shares`, `create` (with its requests), `summary`, `remind` |
| `Settlement` | The instruction a payment produces, `check_funds`, and its booking as transfers |
| `Notice` | Notices for customers, each with a stable key |
| `Refusal` | Every refusal as a constructor with a stable snake-case code |
| `Store`, `Store_memory`, `Store_conformance` | Persistence as a module type, an in-memory store, and the scenarios every store must pass |

Rules enforced by the library:

- A request expires after 14 days by default and reads as expired at once, before any sweep
  stores it. Reminders keep a gap (10 minutes by default) and an optional count limit.
- A link token is 32 bytes from the operating system generator, written as 43 base64url
  characters, never derived from an id or counter. The public view shows only the owner's
  display name, amount, currency and note.
- Links are single-use or multi-use with a cap, live 1, 7 or 30 days, refuse their owner and
  accept one payment per payer.
- Equal splits give each participant the total divided by the head count, rounded down to the
  minor unit; the requester keeps the remainder. Split status is derived from its requests.
- Idempotency keys are derived (`request:<id>`, `link:<id>:<payer>`), so a retried booking
  produces the same entries.
- Stores insert atomically and update by compare-and-set. Persisted types have `Stable.V1`
  forms with pinned digests.

## Tests

- `dune test`: expect tests pin each lifecycle, the refusals and their order, the public view,
  the bookings and their idempotency, the store scenarios and the stable digests.
- Quickcheck properties: request command sequences never leave a final state, pay at most once
  and space reminders by the gap; link payments never exceed the cap, never come from the owner
  or twice from one payer, and complete exactly at the cap; equal shares add up to the total;
  link tokens round-trip.
- `examples/quickstart.ml` runs a request, a link and a split against ledger balances and the
  in-memory store; `runtest` checks its output. `examples/readme.ml` compiles the README snippet.

## Dependencies

- Depends on: [fixed-decimal](fixed-decimal.md), [money](money.md), [ledger](ledger.md) and
  [payments-core](payments-core.md). External: `core`, `ppx_jane`, `zarith`, `cryptokit`;
  `base_quickcheck` for tests. No database, HTTP or `async`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, then `money`, then `ledger`, then `payments-core`. CI runs the shared `ox-setup`
action with these pins, then `dune build`, `dune test` and `dune build @doc` (any odoc warning
fails), and the shared `obj-magic` workflow.

## Known gaps

- One currency per request and link; a payer whose account is in another currency is refused
  rather than converted.
- Requests to people who are not yet customers (by e-mail or phone, claimed on sign-up) are
  not modelled; the payer must be a customer.
- Amount limits per request are left to the service's own limits and risk rules.
