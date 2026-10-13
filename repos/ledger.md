# ledger

OCaml double-entry ledger for a bank or a banking demo: balanced journal entries, two-phase
holds, reversals, trial balance and paged account statements, stored in an append-only,
checksummed Bin_prot journal. It knows accounts, postings and idempotency keys; it knows
nothing of IBANs, cards or webhooks. It is meant to be reusable later by exchange-core's
clearinghouse.

| | |
| --- | --- |
| Repository | `winterchill-trading/ledger` |
| opam package | `ledger` |
| Library | `ledger` (module `Ledger`) |
| Binary | `ledger` (`trial-balance`, `statement`, `camt053`, `verify`, `demo`) |
| Status | done: library, CLI and property tests are in place; CI green |

## Key modules

| Module | Purpose |
| --- | --- |
| `Validated_id`, `Account_id`, `Hold_id`, `Idempotency_key` | Identifiers that refuse malformed text at construction |
| `Side`, `Account_kind` | Debit or credit side; asset, liability and the other kinds |
| `Account` | Account with a `Purpose` and an `allow_negative` flag |
| `Account_status` | `Frozen` (accepts money in only) and `Closed` (final) |
| `Sca_evidence` | Strong customer authentication evidence attached to a posting |
| `Posting`, `Entry` | Signed amounts per account and currency; an entry carries a code, a kind, value and booking dates, and remittance text |
| `Record`, `Framing` | The journal record envelope and its framing on disk |
| `Balances` | Columns for posted and pending debits and credits, `Hold_state`, `Proposal` and `Day_row` |
| `Hold` | Two-phase holds: place, increment, capture, `capture_split`, over-capture with a reason, release and expiry |
| `Reversal` | Reverses an earlier entry, keyed by `~reverses` |
| `Trial_balance` | Per-currency totals; the books balance when debits equal credits |
| `Statement` | Paged account statement by sequence number, date or time |
| `Camt053` | Account statements as values; no XML |
| `Clearing` | `open_items` for matching postings still awaiting a counterpart |
| `Safeguarding` | `reconcile` and `exposures` for customer money held against the bank's own |
| `Snapshot` | `verify` of a day-close snapshot against the journal |
| `Journal` | `append`, `append_linked` (a group that commits or refuses as one), `replay`, `close_day`, `expire_holds`, and opening from a snapshot |

Rules enforced by the journal:

- Idempotency keys are kept forever, including the refusal stored for a rejected request, so
  a retried webhook returns the same answer and books nothing twice.
- Time is assigned by the ledger, monotonically, not taken from the caller.
- Each record carries the hash of the previous one; `verify` checks the chain.
- Adjustments to a closed day need four-eyes approval.

## Tests

- `dune test`: expect tests per feature, cram tests for the CLI.
- Base_quickcheck property tests over random valid and invalid operations run through a real
  journal, with random day closes in between. They check that books balance per currency,
  that restricted accounts never go negative, that held amounts equal open holds, and that
  the columns agree.
- The same state is checked after a read, a replay, a reopen, and a reopen from a snapshot.

## Dependencies

- Depends on: [money](money.md). External: `core`, `core_unix` (CLI), `async_kernel`,
  `cryptokit` (journal checksums), `ppx_jane`.
- Used by: none in the organization yet; planned for `payments-core`, `card-core` and
  `banking-provider` (see [design/neobank.md](../design/neobank.md)).

## CI pin order

`fixed-decimal`, then `money`, then `ledger`. CI pins each from GitHub, then runs
`dune build` and `dune test`, and the shared `obj-magic` workflow.

## Known gaps

- The journal is read whole into memory on open. Large journals need the snapshot path
  or a streaming reader before they fit a server.
- macOS `fsync` does not flush the drive cache. Durability tests on macOS are not evidence
  of durability on power loss; Linux is the target for that.
- Hold expiry needs a timer or a day close to run; nothing expires holds on its own.
- Refused idempotency keys are kept forever, with no retention window.
- Errors raised before an entry exists are not recorded as refusals, so a retry of such a
  request is processed again.
- Matching against provider statements (breaks, ageing) is not built; `Clearing.open_items`
  lists open items only.
- The journal chain head is not published anywhere, so a reader cannot check that the
  journal has not been truncated at the end.
