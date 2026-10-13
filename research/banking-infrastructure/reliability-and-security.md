# Reliability and security of banking systems

Kind: reference.

## Summary

- Exactly-once delivery is impossible over an unreliable network; systems get exactly-once
  effects from at-least-once delivery plus idempotent consumers (dedup by a stable id).
- Public payment APIs scope an idempotency key to the caller, compare the parameters of a
  retry with the original, return the stored response, and prune keys after 24 hours.
- The transactional outbox writes the state change and the outgoing message in one
  transaction; a relay publishes it at least once, so the receiving side keeps an inbox.
- PCI DSS v4.0.1: sensitive authentication data (track, card verification code, PIN and
  PIN block) is never kept after authorization; PAN display is at most BIN and last four;
  audit logs are kept 12 months with the latest three immediately available.
- GDPR: data minimisation and storage limitation (Art 5), erasure yields to legal
  retention duties (Art 17(3)(b)), breach notice within 72 hours (Art 33).
- DORA Art 11/12: business continuity plans tested at least yearly, backups restored on
  segregated systems, RTO and RPO set per function, reconciliation after recovery.
- NIST SP 800-57 gives key states and cryptoperiods (data and key-wrapping keys under
  2 years of originator use); OWASP ASVS 5.0 says a bank can hardly justify less than L3.

## Exactly-once effects

| Mechanism | Where | Dedup key | Guarantee |
| --- | --- | --- | --- |
| Idempotency key | Client to our API, our API to the provider | (caller, key) | One effect per key within the retention window |
| Outbox | Our DB to the provider | Outbox row id, sent as the provider idempotency key | Sent iff the transaction committed, at least once |
| Inbox | Provider webhooks to us | Provider event id | Each event applied once |
| Journal idempotency | Ledger entries | Entry idempotency key, kept forever | One posting per business event |

Reference behaviour of a widely used public payments API: keys up to 255 characters, V4 UUIDs
suggested, no personal data in keys; the status code and body of the first request are
saved once execution begins, and retries return them, including `500` errors; parameters of
a retry are compared to the original and a mismatch is an error; keys may be pruned once at
least 24 hours old, after which reuse creates a new request; results are not saved when
validation fails or a concurrent request with the same key is executing.

Outbox: the message row is written in the same transaction as the business data, so it is
sent if and only if the transaction commits; a relay (log tailing or polling) publishes it
and may publish twice after a crash, so consumers dedup on the message id.

Sagas replace a distributed transaction with a sequence of local transactions, each with a
compensating transaction run in reverse order on failure. In money movement a compensation
is a new reversing entry, never a deletion; steps after the point of no return (a SEPA
credit sent) are compensated by a separate business process (recall, refund).

## Webhooks

| Property | Reference practice |
| --- | --- |
| Signature | HMAC-SHA256 over timestamp and raw body, e.g. header `t=<unix>,v1=<hex>` |
| Replay window | Reject when the signed timestamp is more than 5 minutes off (library default); tolerance 0 disables the check |
| Retries | Exponential backoff for up to three days (live mode) |
| Ordering | Not guaranteed; do not order by the event's creation time |
| Duplicates | Possible; dedup by event id (and object id plus type for twin events) |

Our provider signs the body without a timestamp and retries up to five times (see the design
page), so replay protection rests on the inbox: a replayed event id is a no-op.

## Dual control and separation of duties

Four-eyes (maker-checker): one person proposes, a different authorised person approves,
and the system enforces that they differ. Banking uses it for manual ledger adjustments and
write-offs, limit and tier changes, discounting a sanctions or PEP screening hit, beneficiary
whitelisting on behalf of a customer, releasing held payments, role grants, and key
ceremonies. Key ceremonies use dual control and split knowledge: no one person ever holds
a whole clear-text key component set (PCI PIN requirement, unverified wording). Separation
of duties also means developers have no production write access and operators cannot
approve their own role changes.

## Key management

| NIST SP 800-57 Pt 1 Rev 5, Table 1 | Originator-usage period | Recipient-usage period |
| --- | --- | --- |
| Private signature key | 1 to 3 years | - |
| Symmetric authentication key (HMAC) | < 2 years | < OUP + 3 years |
| Symmetric data encryption key | < 2 years | < OUP + 3 years |
| Symmetric key-wrapping key | < 2 years | < OUP + 3 years |
| Symmetric master key / KDK | About 1 year | - |

Key states: Pre-activation, Active, Suspended, Deactivated, Compromised, Destroyed. A
compromised key's cryptoperiod is no longer valid and protecting use stops at once.
Envelope encryption: data is encrypted under a data encryption key (DEK); the DEK is stored
wrapped by a key-encryption key (KEK) held in an HSM or KMS, so rotating the KEK re-wraps
DEKs without re-encrypting data. FIPS 140-3 validates cryptographic modules at security
levels 1 to 4; payment HSMs for PIN processing are PCI PTS HSM or FIPS 140 level 3
(unverified wording).

## PCI DSS v4.0.1 scope

| Data | Element | After authorization |
| --- | --- | --- |
| Account data: cardholder data | PAN, cardholder name, expiry, service code | May be stored if protected (3.5.1) |
| Account data: sensitive authentication data | Full track (3.3.1.1), card verification code (3.3.1.2), PIN and PIN block (3.3.1.3) | Not stored, even encrypted (3.3.1) |

- 3.4.1: no more than the BIN and last four digits are displayed on screens and reports
  without a documented business need; with 8-digit BINs the brands set truncation formats
  (PCI SSC FAQ 1091, not fetched).
- Scope reduction: a provider-hosted iframe or redirect for card entry and display keeps
  PAN off our systems; merchant e-commerce with all payment page elements from a compliant
  provider is SAQ A, partial elements (direct post) is SAQ A-EP, everything else SAQ D.
  v4.0.1 adds script-integrity duties for SAQ A pages (unverified).
- 10.5.1: retain audit log history at least 12 months, the most recent three months
  immediately available for analysis.

## Audit trails

Each record answers who (user or service id, on behalf of whom), what (action, object id,
before and after where not sensitive), when (UTC timestamp from a synchronised clock),
where (source IP or host, channel) and outcome (success, failure, reason). The store is
append-only; tamper evidence comes from a hash chain where each record carries the hash of
its predecessor, so an edit or deletion breaks every later link. Truncation of the tail is
only detected against an external anchor (the last hash recorded elsewhere).

## GDPR

| Article | Rule |
| --- | --- |
| 4(5) | Pseudonymisation: data cannot be attributed to a person without additional information kept separately |
| 5(1)(c) | Data minimisation: adequate, relevant and limited to what is necessary |
| 5(1)(e) | Storage limitation: identifiable no longer than necessary |
| 17(3)(b) | Erasure does not apply where processing is needed to comply with a legal obligation |
| 25(1)-(2) | Data protection by design and by default, e.g. pseudonymisation |
| 32(1) | Pseudonymisation and encryption; confidentiality, integrity, availability; timely restore; regular testing |
| 33(1) | Notify the supervisory authority without undue delay, where feasible within 72 hours |

Crypto-shredding encrypts each subject's personal data under a per-subject key; destroying
the key erases every copy, backups included, while the pseudonymous ids in the ledger stay.
AML record keeping (five years after the relationship ends, AMLD Art 40, unverified here)
is the usual Art 17(3)(b) ground to defer erasure of KYC records.

## Business continuity

DORA Art 11: ICT business continuity and response and recovery plans, a business impact
analysis, tests at least yearly and after substantive changes, including switchovers to
redundant capacity and backups; readily accessible records of activity during disruption.
DORA Art 12: documented backup scope and minimum frequency by criticality; periodic
restoration tests; restore onto systems physically and logically segregated from the source;
RTO and RPO set per function by criticality; checks and reconciliations after recovery,
including against data from external stakeholders.

## Secure SDLC and secrets

OWASP ASVS 5.0.0 has three levels: L1 about 20% of requirements, L2 (all of L1 and L2,
about 70%) is what most applications should reach, L3 the rest; it notes a bank may have
difficulty justifying anything less than L3 for online banking. Secrets come from the
environment or a secret manager, are typed so they cannot print, are never in logs,
fixtures, journals or CI output, and are rotated within the periods above.

## What we adopt

1. `neobank-api`: header `Idempotency-Key` (1 to 255 printable ASCII characters) on every
   `POST`; scope `(customer_id, method, route, key)`; `request_hash` is SHA-256 of the
   canonical JSON body. Table `idempotency(scope, request_hash, state, status, body,
   created_at)` with `state` `In_progress | Completed`. Same scope and hash and
   `Completed`: return stored status and body. Different hash: `422`
   `idempotency_key_reused`. `In_progress`: `409` `idempotency_key_in_use`. Validation
   failures are not stored. Retention 24 hours, pruned hourly.
1. `payments-core`: every transfer carries `idempotency_key : Transfer_key.t` derived from
   the API key scope; the provider call uses the transfer id as the provider idempotency key,
   so a resent outbox row cannot create a second payment.
1. `ledger`: `Entry.idempotency_key` is unique for the life of the journal (no pruning);
   `post` of an existing key with an identical posting returns `Already_posted entry_id`, a
   different posting returns `Error Key_conflict`.
1. `neobank-api`: `outbox(id, aggregate_id, kind, payload, attempts, next_attempt_at,
   sent_at)` written in the same transaction as the transfer state change; a relay polls
   every 1 s, backoff 1 s doubling to 5 min, gives up after 24 h into `Needs_review`.
1. `neobank-api`: `inbox(provider_event_id PRIMARY KEY, received_at, payload_hash,
   applied)`; verify signature on raw bytes in constant time, insert, apply, mark applied in
   one transaction; a duplicate id returns `200` without effect. Inbox rows kept 30 days.
1. `ledger`: `Adjustment { maker : Operator_id.t; checker : Operator_id.t; reason : string;
   ticket : string }`; `Adjustment.create` returns `Error Same_operator` when
   `maker = checker`; states `Proposed -> Approved | Rejected | Expired` (24 h), only
   `Approved` posts. The same maker-checker type guards tier and limit overrides in
   `risk-rules` and hit discounting in `kyc-core`.
1. `ledger`: each journal record carries `prev_hash` (SHA-256 of the previous record's
   Bin_prot bytes; genesis is 32 zero bytes after the header) and replay verifies the chain,
   failing with `Chain_broken { seq }`; the head hash is written to the daily statement
   and the backup manifest as the external anchor.
1. `kyc-core`: fields tagged `Public | Internal | Pii | Sensitive_pii` (name, address,
   birth date, document numbers are `Sensitive_pii`); `Pii` and above stored encrypted
   under a per-customer DEK wrapped by a KEK; erasure destroys the DEK once the 5-year AML
   retention ends, and an `Erasure_requested` audit record is written at request time.
1. All libraries: one `Redact` module. PAN shows last four only (`**** 1234`), stricter
   than BIN plus last four; IBAN shows country code and last four (`DE** **** 1234`); OTP,
   CVV, PIN, passwords, API keys, session tokens and webhook secrets are never logged;
   email shows first character and domain.
1. Demo targets: RPO 0 for committed journal entries (fsync before acknowledge) on a
   healthy disk, RPO 5 min on disk loss (journal shipped every 5 min); RTO 15 min (restore
   and replay, then reconcile with the provider); restore drill in CI on every release.
1. Audit records in every library: `{ actor; on_behalf_of; action; object_id; at; source;
   outcome }`, append-only, hash-chained like the journal, kept 12 months online.

## Open questions

- Should the outbox and inbox live in the Bin_prot journal (one log) or in a separate
  store; one log keeps the single-transaction property without a database.
- Which member state AML retention period applies to the provider versus to us.

## Sources

- Idempotent requests (public payments API reference): <https://docs.stripe.com/api/idempotent_requests>
- Receive events in your webhook endpoint (public payments API docs): <https://docs.stripe.com/webhooks>
- Transactional outbox pattern: <https://microservices.io/patterns/data/transactional-outbox.html>
- Sagas, SIGMOD 1987: <https://doi.org/10.1145/38713.38742>
- NIST SP 800-57 Part 1 Rev 5: <https://doi.org/10.6028/NIST.SP.800-57pt1r5>
- FIPS 140-3: <https://csrc.nist.gov/pubs/fips/140-3/final>
- PCI SSC FAQ on PAN masking and 8-digit BINs:
  <https://www.pcisecuritystandards.org/faqs/1492/>
- PCI SSC FAQ on SAQ A and SAQ A-EP eligibility:
  <https://pcisecuritystandards.org/faq/articles/Frequently_Asked_Question/why-is-saq-a-ep-used-for-direct-post-while-saq-a-is-used-for-iframe-or-url-redirect>
- PCI DSS v4.0.1 requirement text (3.3.1, 10.5.1) as mirrored:
  <https://ce.prod.cloudaware.com/frameworks/pci-dss-v4.0.1/10/05/01>
- Regulation (EU) 2016/679 (GDPR): <https://eur-lex.europa.eu/eli/reg/2016/679/oj>
- Regulation (EU) 2022/2554 (DORA): <https://eur-lex.europa.eu/eli/reg/2022/2554/oj>
- OWASP ASVS 5.0.0, using the ASVS:
  <https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/en/0x03-What-is-the-ASVS.md>
