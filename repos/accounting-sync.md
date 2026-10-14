# accounting-sync

Export of double-entry ledger journals to external accounting systems. It takes the records
of a [ledger](ledger.md) journal and turns them into journal entries an accounting package
accepts: one entry per transaction and currency, lines on the package's own account codes
with tracking categories, an idempotent key per entry, a status per entry, batches per
accounting period that respect period locks, and a reconciliation that shows whether the
books on both sides agree. Amounts come from [money](money.md) as exact minor units. The
library is pure and persists nothing: mappings, trackers, connections and locks are values
with stable binary forms that a service stores however it likes.

| | |
| --- | --- |
| Repository | `winterchill-trading/accounting-sync` |
| opam package | `accounting-sync` |
| Library | `accounting-sync` (module `Accounting_sync`) |
| Binary | `accounting-sync` (`example`, `mapping-example`, `export`, `sync`) |
| Status | done for the library, the simulated system and the command; no adapter for a real accounting package yet |

## Key modules

| Module | Purpose |
| --- | --- |
| `Account_code`, `Entry_key`, `Push_key`, `Remote_id` | Validated text ids, distinct types |
| `Chart` | The external chart: code, name, type (asset, bank, liability, equity, revenue, expense), archived flag |
| `Tracking` | Tracking categories with options; at most one option per category on a line |
| `Journal_entry` | Key, ledger transaction, date, currency, optional rate to the reporting currency, narration, reference, balanced lines with sources |
| `Mapping` | Rules from ledger accounts to codes: exact account, longest prefix, tag, account class; tracking from account tags; `check` against a chart |
| `Export` | Ledger records to entries; blocked transactions and the unmapped-account report |
| `Period`, `Period_lock`, `Batch` | Monthly periods, a lock date plus closed months, batches of bounded size that never mix periods |
| `Reason`, `Status`, `Tracker` | Rejection reasons, the entry state machine, the status book with attempts and replacements |
| `Connection`, `Organisation` | Consent and organisation selection: pending, connected, disconnected, cancelled |
| `Connector` | The module type an adapter implements, and an existential wrapper |
| `Simulated` | An in-memory system with consent, organisations, chart, lock date, idempotent posts, polls, voids and test hooks |
| `Check`, `Sync`, `Reconciliation` | Local checks, push, poll and void over a connector, and the period reconciliation |

## Rules

- One ledger transaction (a booked record: an entry, an approved adjustment, or a group of
  linked entries) becomes one entry per currency it moves, keyed `<transaction key>:<currency>`.
  Exporting the same journal again gives the same keys and digests.
- Postings that map to the same code and tracking options are netted into one line. A hold's
  pending sub-account maps like its parent, so a hold placed and released inside one
  transaction leaves nothing; a transaction that nets to zero produces no entry.
- A transaction with a posting the mapping cannot place is not exported in part: it is
  blocked, and `Export.unmapped` reports the accounts to map, with entry counts and amounts.
- Every attempt to post carries the push key `<entry key>:<attempt>`. A request that fails is
  resent under the same key; a retry after a rejection or a void moves to the next attempt.
- Entries dated in a locked period (the system's lock date, a local lock date, or a closed
  month) are refused locally with `period_locked` and never sent.
- An entry whose ledger content changes after it was submitted or posted is not re-sent: the
  new content waits as a replacement until the remote entry is voided.

```text
Pending --accepted--> Submitted --posted--> Posted --voided--> Voided
   |                     |                                       |
   +------posted---------|-------------------> Posted            |
   +------rejected-------+---rejected--> Rejected --retry--> Pending
   +------voided-----------------------> Voided   --retry--> Pending
```

Rejection reasons: `unmapped_account`, `unbalanced`, `unknown_tracking`, `period_locked`,
`validation_error`. The last two are retryable as they are; the others need a mapping, chart
or content change first.

Writing a connector: implement `Connector.S` (consent URL, completing a grant into the
organisations it covers, disconnect, chart, tracking categories, the system's own lock date,
`post`, `poll`, `void`, a view URL). `post` must be idempotent per push key and answer every
key; `poll` answers only ids it knows. A refusal is an `Answer.Rejected`, not an error;
errors are for transport failures, after which entries stay pending under the same keys.

Reconciliation compares, per currency and chart code, the net movement of the ledger's
postings in the period, of the entries an export builds now, and of the entries the tracker
says are posted. A period reconciles when every count except `matched` is zero and the three
views agree.

## Tests

- Expect tests: a month of activity (deposits, a fee, an exchange as linked legs, a card hold
  and capture, a scheme settlement), mapping precedence, periods, locks and batching, the
  status transition table, end-to-end syncs against the simulated system (consent, repeats,
  rejections and retries, changes and voids, a remote lock, decisions on poll), reconciliation,
  and the command (`test/cli.t`).
- Base_quickcheck properties: exported net movement per code equals the ledger's under a
  complete mapping; entries balance and keys are unique and deterministic; batches partition
  their input; staging is idempotent and push keys never repeat across retries.
- Stable digests are pinned in `test/test_stable.ml`.
- `examples/quickstart.ml` is built and run in CI.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md). External: `core`, `core_unix`,
  `async_kernel`, `async`, `ppx_jane`, `zarith`, `expect_test_helpers_core` for tests.
- Used by: none yet. The adapters for real systems are planned as separate packages next to
  their HTTP clients.

## CI pin order

`fixed-decimal`, `money`, `ledger`. CI pins each from GitHub, then runs `dune build`,
`dune test` and the quick-start example.

## Known gaps

- No adapter for a real accounting package yet; each belongs in its own package next to its
  HTTP client.
- Entries are dated by day in UTC; a ledger whose business day is in another zone should
  export by `Business_date`.
- A system that caps the number of tracking categories per line (two is common) is not
  checked locally; the system rejects such entries with `unknown_tracking` or
  `validation_error`.
