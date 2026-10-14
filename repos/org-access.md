# org-access

Access control for business customers of a bank: organisations, members and roles,
invitations, maker-checker approvals and an append-only, hash-chained access audit. Every
decision is a pure function (`Authorize.decide`) with a stable reason code, and the library
never persists anything: a service implements `Store.S` over its own database. It depends
only on [money](money.md) for amounts. Opam package and command: `org-access` and `org-access-cli`.

| | |
| --- | --- |
| Repository | `winterchill-trading/org-access` |
| opam packages | `org-access` (library), `org-access-cli` (command) |
| Library | `org-access` (module `Org_access`) |
| Binary | `org-access` (`roles`, `explain`, `required`) |
| Status | done: library, command, property tests and the store conformance suite are in place; not yet published to [opam-repository](opam-repository.md) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Org_id`, `User_id`, `Invitation_id`, `Approval_id` | Validated ids, one type each |
| `Role`, `Permission`, `Email`, `Text`, `Time_utc` | Validated names and fields |
| `Role_model` | Roles in privilege order, their permissions, the custodian permission; `Role_model.default` |
| `Organisation`, `Member` | The organisation (status, verification) and a user's membership |
| `Action`, `Reason`, `Authorize` | What a request needs, why it was refused, the pure decision |
| `Approval_policy` | Per-currency maker-checker thresholds as money amounts |
| `Approval` | Approval state machine: open, approve, reject, cancel; versioned for compare-and-set |
| `Invitation`, `Token` | Invitations with expiry, resend and single-use acceptance; secret tokens stored as SHA-256 hashes |
| `Team` | Pure member operations that keep a custodian |
| `Audit` | Events, hash-chained entries, `verify` |
| `Store`, `Store_memory`, `Store_conformance` | Persistence as a module type, an in-memory store and the suite every store runs |
| `Access` | The operations a service exposes, over any store and monad |

## Rules

- **Roles map to permission sets.** The default model has four roles (admin, approver,
  operator, viewer). `members.manage`, the custodian permission, can never be left with
  no holder: the library refuses to demote or remove the last one.
- **One organisation per resource.** A member of another organisation gets the same
  answer as for something that does not exist.
- **Decision order.** `Authorize.decide` checks, in order: a membership exists
  (`not_a_member`); it is in the resource's organisation (`other_organisation`); the
  organisation is not suspended (`organisation_suspended`); the role is in the model
  (`unknown_role`); the role holds the permission (`role_required`); the organisation is
  verified when the action needs it (`verification_required`). Outsiders are checked first.
- **Maker-checker.** `Approval_policy` gives the number of distinct approvers an amount
  needs, per currency. The maker never approves their own request, and two approvals from
  one person count once.
- **Invitations.** Only the SHA-256 of the link token is stored; resending rotates it.
- **Audit.** Every change and every refusal is an entry; `Audit.verify` detects a deleted,
  edited or reordered entry.
- **Concurrency.** Team, invitation and approval writes are compare-and-set on a version.
  `Access` reloads and retries a lost write (three attempts by default), then answers
  `conflict`.

Workflow error codes: `own_request`, `already_approved`, `not_pending`,
`not_enough_approvers`, `not_canceller` (approvals); `member_exists`, `member_elsewhere`,
`own_membership`, `last_admin` (team); `invitation_pending`, `too_many_invitations`,
`invitation_not_pending`, `invitation_expired`, `invalid_token`, `email_mismatch`
(invitations).

## Tests

- `dune test`: the quick-start example is run and its output compared with
  `examples/quick_start.expected`; `@examples/runtest` builds the examples.
- Base_quickcheck properties on the invariants (custodian, maker-checker, audit chain).
- `Store_conformance` is the suite a service runs against its own store.

## Dependencies

- Depends on: [money](money.md). External: `core`, `ppx_jane`, `cryptokit` (SHA-256),
  `base_quickcheck` and `odoc` for tests and docs.
- Used by: none yet.

## CI pin order

`fixed-decimal`, then `money`. CI pins each from GitHub, then runs `dune build`,
`dune test` and the examples.

## Known gaps

- Access for people outside the organisation (a supplier submitting invoices through a
  link) is not modelled; `Token` is the building block for it.
- Verification is one flag on the organisation. The verification file itself (legal
  entity, owners, documents) belongs in [kyc-core](kyc-core.md).
- Scoping stops at the organisation. Finer rules (only the cardholder may reveal a card)
  are the service's checks after `Authorize.decide`.
- The audit chain is tamper-evident, not signed: someone able to rewrite the whole table
  can rebuild it. Export the latest digest elsewhere.
- No database store ships here. A service implements `Store.S` and runs
  `Store_conformance` against it.
