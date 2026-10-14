# ledger

OCaml double-entry ledger: balanced journal entries, two-phase holds, reversals, four-eyes
adjustments, trial balance and paged account statements, stored in an append-only,
checksummed and hash-chained Bin_prot journal. It knows accounts, postings and idempotency
keys; it knows nothing of IBANs, cards or webhooks. It is meant to be reusable later by
exchange-core's clearinghouse. Opam readiness: [research/opam-readiness/ledger.md](../research/opam-readiness/ledger.md).

| | |
| --- | --- |
| Repository | `winterchill-trading/ledger` |
| opam package | `ledger` |
| Library | `ledger` (module `Ledger`) |
| Binary | `ledger` (`trial-balance`, `statement`, `camt053`, `verify`, `example`) |
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
| `Safeguarding` | `reconcile` and `exposures` for safeguarded (customer) funds |
| `Snapshot` | `verify` of a day-close snapshot against the journal |
| `Journal` | `append`, `append_linked` (a group that commits or refuses as one), `replay`, `fold`, `close_day`, `expire_holds_at` with `next_expiry`, `forget_expired_refusals`, `chain_head`, and opening from a snapshot |
| `Chain_head` | The hash-chain head as one line (`ledger-head-v1:<seq>:<length>:<sha256>`) to publish, and `verify` against a journal |

Rules enforced by the journal:

- Idempotency keys are kept forever, including the refusal stored for a rejected request
  (also a builder's refusal, such as an unknown hold id), so a retried webhook returns the
  same answer and books nothing twice. With `refusal_retention`, refusals last that window
  and a `Refusals_forgotten` record drops them.
- Time is assigned by the ledger, monotonically, not taken from the caller.
- Each record carries the hash of the previous one; `verify` checks the chain.
- Manual adjustments need a second approver (four-eyes).

## Tests

- `dune test`: expect tests per feature, cram tests for the CLI.
- Base_quickcheck property tests over random valid and invalid operations run through a real
  journal, with random day closes in between. They check that books balance per currency,
  that restricted accounts never go negative, that held amounts equal open holds, and that
  the columns agree.
- The same state is checked after a read, a replay, a reopen, and a reopen from a snapshot.

## Dependencies

- Depends on: [money](money.md). External: `core`, `core_unix` (journal file and CLI),
  `async_kernel` (time source), `cryptokit` (SHA-256 chain), `ppx_jane`.
- Used by: `accounting-sync`, `banking-provider`, `billing-core`, `card-core`, `chain-books`,
  `fx-core`, `griffin-provider`, `investing-core`, `lightspark-provider`, `neobank-api`,
  `payments-core`, `payouts-core`, `pots-and-insights`, `requests-core`, `rewards-core`,
  `risk-rules`, `statements`, `striga-provider`.

## CI pin order

`fixed-decimal`, then `money`, then `ledger`. CI pins each from GitHub, then runs
`dune build` and `dune test`, and the shared `obj-magic` workflow.

## Known gaps

- macOS `fsync` does not flush the drive cache, so durability on macOS is weaker than on
  Linux.
- The folded state keeps every booked entry for idempotency, so memory grows with the number
  of entries (the file itself is streamed, not read whole). Segment files per period with an
  on-disk key index would bound it; that is a format decision.
- Matching against provider statements (breaks, ageing) is not built; `Clearing.open_items`
  lists open items only. Needs its own design.
- `ledger camt053` reads every record into memory, since the statement replays the journal
  for its balances.

Fixed on 2026-10-14: the journal is streamed on open (`Framing.fold`, `keep_records:false`,
`Journal.fold`); hold expiry can be scheduled (`next_expiry`, `expire_holds_at`); refusals
have a retention window; builder errors are recorded as refusals; the chain head is exposed
(`Journal.chain_head`, `Chain_head`, `ledger verify -head`).
