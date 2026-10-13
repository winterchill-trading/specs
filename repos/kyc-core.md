# kyc-core

Provider-neutral customer due diligence for a bank: identity verification steps and tiers, a
risk-based customer risk rating with CDD levels and enhanced due diligence, PEP records,
sanctions, PEP and adverse-media screening with four-eyes discounting, ongoing monitoring,
investigations and FIU reporting, periodic review, record retention with legal holds,
travel-rule data, and an audit trail of every change with its actor. It is event-sourced and
idempotent by provider event id. It does no I/O and has no Async; a provider adapter turns its
webhooks into `Event.t` values.

| | |
| --- | --- |
| Repository | `winterchill-trading/kyc-core` |
| opam package | `kyc-core` |
| Library | `kyc-core` (module `Kyc_core`) |
| Binary | `kyc-case` (`replay`, `policy`, `assess`, `match`) |
| Status | done: library, CLI and property tests are in place |

## Key modules

| Module | Purpose |
| --- | --- |
| `Pii` | `'a Pii.t`: sexp and `to_string` print `<redacted>`; `Pii.reveal` is the only way to the value |
| `Customer_id`, `Event_id`, `Operator_id`, `Screening_id` | String identifiers |
| `Country`, `Address`, `Person` | Minimal personal data; every `Person` field is a `Pii.t` |
| `Timestamp`, `Actor` | UTC time in sexp form; `System`, `Provider`, `Operator` |
| `Verification`, `Tier` | Identity steps and their states; tiers T0 to T3, the rule table and the `Tier.Limits` hook |
| `Status` | Case status: Created, Verifying, Approved, Rejected, Needs_resubmission, Blocked, Closed |
| `Pep` | PEP, family member or close associate, with scope, function and dates; EDD runs at least 12 months after the role ends |
| `Risk` | Inputs per EBA factor group, a versioned `Model` (points, score 0 to 100), `Band`, hard floors, EDD triggers and `Override` |
| `Cdd_level` | `Simplified`, `Standard`, `Enhanced` |
| `Name_match` | Folding normalizer and Jaro-Winkler score; candidate threshold 0.85 |
| `Screening` | List sources, screen reasons, hits with list version and score, per-hit review states |
| `Monitoring` | Alerts: `Open`, `Closed_no_action`, `Escalated` |
| `Investigation` | Investigation states, FIU report states, FIU request due dates |
| `Retention` | Retain-until dates and legal holds |
| `Visibility` | Field classes (`Public`, `Internal`, `Pii`, `Sensitive_pii`, `Restricted`) and audiences |
| `Travel_rule` | Originator and beneficiary data for crypto transfers; self-hosted ownership checks above EUR 1 000 |
| `Event`, `Audit` | Persisted events with their provider event id, and the audit trail |
| `Kyc_case` | The aggregate: `apply`, `of_events`, tiers, `cdd_level`, `can_approve`, `follow_ups`, `customer_view`, review and retention dates |

Rules enforced by the case:

- Idempotent: an event id already applied is a no-op; the same id with different content is an
  error. Illegal events return `Error` and leave the case unchanged; nothing raises.
- Approval needs the approval tier's steps, a screening run with every hit discounted, a risk
  assessment and, under EDD, the EDD steps plus a senior sign-off after the latest assessment.
- Risk bands are Low 0 to 29, Medium 30 to 59, High 60 to 100. An active PEP, a high-risk third
  country or confirmed adverse media force High and cannot be overridden down. An override needs
  an operator and a reason; the assessment keeps the computed band and the model version.
- A confirmed sanctions-list hit blocks the customer in the same event. Tipping-off rules keep
  alerts, investigations, reports and block reasons visible to compliance only; a blocked
  customer sees `Under_review`.
- Records are kept 5 years after closure or refusal; a legal hold may extend that by at most
  5 more years. After `retain_until` the case reports `Retention_ended`.
- Periodic review falls due 5, 3 or 1 years after approval or the last review, by band.

## Stored formats

`Event.Stable.V1` and the stable modules it is built from (`Audit.Entry.Stable.V1`,
`Risk.Assessment.Stable.V1`, `Travel_rule.Stable.V1`) are the persisted formats. Their bin_io
digests are pinned in the tests. A risk assessment is stored as computed, so replay never
rescores with a newer model. PII is in clear inside bin_io, so the event store is PII storage.

## Tests

- `dune test`: expect tests per transition and per rule, cram tests for the `kyc-case` CLI over
  `examples/approved.sexp`.
- Base_quickcheck properties: applying an event twice equals applying it once; floors always
  give High; a riskier sector never lowers the score; Jaro-Winkler is symmetric.
- Jaro-Winkler reference pairs (MARTHA/MARHTA, DWAYNE/DUANE, DIXON/DICKSONX).

## Dependencies

- Depends on: `core`, `ppx_jane`; `core_unix` for the CLI. No sibling repositories.
- Used by: none yet; planned for `banking-provider` (see
  [design/neobank.md](../design/neobank.md)).

## CI pin order

Standalone: no pins. CI builds and tests this repository alone.

## Known gaps

- Name matching folds Latin scripts only; other scripts are not transliterated.
- No beneficial-owner (legal entity) model; customers are natural persons.
- FIU working days skip weekends only; the caller passes a holiday calendar if one is needed.
- Report contents (goAML XML and similar) are out of scope; only report states are tracked.
- Encryption and erasure of PII are left to the storage layer.
- Years are 365 days for reviews and retention.
- Risk weights and band cut-offs are configuration (model version `kyc-risk-2026-10`), not law.
