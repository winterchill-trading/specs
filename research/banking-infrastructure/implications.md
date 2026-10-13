# Implications for the banking repositories

Kind: reference.

A per-repository checklist drawn from the notes in this directory, as of 2026-10-13. Each
item names the note it comes from; the note has the source and the exact values. "Have"
marks what a repository already does (from its README or `.mli`), so the list is the
difference. Where two notes touched the same type, this page is the decision.

## Top ten

1. The ledger is the record of what happened to every request: idempotency keys are booked
   forever, a refusal that depends on state is recorded under its key so a retry gets the
   same answer, and nothing is ever edited (reversal or four-eyes adjustment only).
   ([ledger](ledger.md), [reliability](reliability-and-security.md))
1. Holds have an expiry and settle over the hold in one entry; a card clearing can be
   partial, repeated, above the auth or without an auth, and a refund is a new credit.
   ([ledger](ledger.md), [cards](cards.md))
1. Atomic groups of entries (FX legs and fee, settlement and fee) through `Linked`.
   ([ledger](ledger.md))
1. SEPA identifiers (`end_to_end_id`, `uetr`) are ours, in the SEPA character set, and
   every reject, return and recall carries an ISO reason code; SCT Inst times out at
   10 seconds and may still settle late. ([payment schemes](payment-schemes.md))
1. SCA is two different element categories with a code bound to amount, currency and
   payee; at most 5 failed attempts; 5 minutes idle session; every skipped SCA names its
   RTS exemption article, because skipping it moves fraud liability to us.
   ([SCA](strong-customer-authentication.md))
1. Risk band per customer (Low, Medium, High) from the four EBA factor groups, with forced
   floors for PEPs and high-risk countries, documented overrides, and periodic review at
   1, 3 or 5 years. ([KYC and AML](kyc-aml.md))
1. Screening on every list update and every payment counterparty; discounting a hit needs
   two different people; alerts, cases and reports are never visible to the customer
   (tipping-off). ([KYC and AML](kyc-aml.md))
1. Customer money sits in liability accounts matched by safeguarding asset accounts, with
   a daily safeguarding reconciliation per currency that proposes, never posts, a top-up.
   ([risk and treasury](risk-and-treasury.md))
1. Exactly-once effects: client idempotency keys at the API (24 hours), an outbox for
   provider calls, an inbox keyed by provider event id, and a hash-chained journal.
   ([reliability](reliability-and-security.md))
1. First model stack: a gradient-boosted tree trained in Python, exported as JSON, scored
   in OCaml with parity to 1e-6, calibrated, turned into two rules (`Review`, `Block`)
   with thresholds from the daily alert budget, shipped in shadow mode first.
   ([fraud and monitoring](fraud-and-monitoring.md))

## money

- Have: integer minor units, EUR 2, BTC 8, ETH 18, USDC and USDT 6, `BTC@lightning` 11,
  named rounding modes.
- Never change a registered currency's exponent; a new scale is a new currency code.
  ([ledger](ledger.md))
- `Amount.Sepa.validate`: EUR, 0.01 to 999 999 999.99, at most two decimals (AT-T002).
  ([payment schemes](payment-schemes.md))
- `Fee` stays separate from `Rate`: a swap books the fee as its own entry, not inside the
  rate; rate rounding favours the house. ([ledger](ledger.md))

## ledger

- Have: balanced single-currency entries, holds on pending sub-accounts, reversals, keys
  booked once, checksummed Bin_prot journal, trial balance, statements; in progress:
  `Linked`, `Rejected` (failed keys), `Account_status_changed`, `Day_closed`.
- Hold `~timeout` with `expires_at`; an `Expire` event releases it; capture or release
  after expiry is refused as `Hold_expired`; partial capture releases the remainder in the
  same record; capture above the hold only with `~over_capture` and the excess as its own
  posting. ([ledger](ledger.md), [cards](cards.md))
- Holds keyed by the caller's id (card `auth_id`, transfer id); increment adds, partial
  reversal reduces, several captures allowed until the hold is closed. ([cards](cards.md))
- `Entry.code` enum next to the free tag: `Deposit`, `Withdrawal`, `Transfer_intraledger`,
  `Fx_leg`, `Fee`, `Card_auth`, `Card_settlement`, `Refund`, `Reversal`, `Return`,
  `Recall`, `Adjustment`, `Safeguarding_sweep`. ([ledger](ledger.md))
- `Entry.business_date`; after `Day_closed`, write a snapshot per (account, currency):
  opening, debits, credits, closing booked (`CLBD`), closing available (`CLAV`), covered
  sequence number; replay may start at a snapshot and must reproduce it. ([ledger](ledger.md))
- `Adjustment { maker; checker; reason; ticket }` with `maker <> checker`, states
  `Proposed -> Approved | Rejected | Expired` (24 h); only `Approved` posts.
  ([reliability](reliability-and-security.md))
- Each record carries `prev_hash` (SHA-256 of the previous frame payload); replay checks
  the chain (`Chain_broken { seq }`); the head hash goes into the daily snapshot as the
  external anchor. Needs a `Stable.V2` record and a new compatible digest.
  ([reliability](reliability-and-security.md))
- Each payment posting may carry `sca : Challenge_id | Exemption of string` so liability
  under PSD2 Art 74(2) is traceable. ([SCA](strong-customer-authentication.md))
- Account classes for safeguarding: `Customer_funds` liabilities per customer and currency,
  `Safeguarding_asset` per bank or provider account and currency, `Own_funds`,
  `Fee_income`; clearing accounts per flow (`clearing:sepa_out`, `clearing:card`,
  `clearing:fx`) that must return to zero, with a report of non-zero clearing balances older
  than one business day. ([risk and treasury](risk-and-treasury.md), [ledger](ledger.md))
- `Safeguarding_recon` per currency per day: requirement, internal resource, external
  balance, differences, `Balanced | Shortfall | Excess`, and a proposed top-up.
  `Exposure` per currency: customer liability, assets held, house position.
  ([risk and treasury](risk-and-treasury.md))
- Ledger stores ids, never PII. ([KYC and AML](kyc-aml.md))

## payments-core

- Have: rails, IBAN/BIC, beneficiaries, crypto addresses, Lightning, transfer status
  machine (`Draft | Awaiting_sca | Submitted | Pending | Settled | Failed | Returned |
  Cancelled`), `Sca` challenges with binding and attempts, standing orders, swaps,
  booking rules, balance and transfer reconciliation diffs.
- Status: keep the existing states and add `Timed_out` (SCT Inst, may be followed by a late
  `Settled`), `Recall_requested`, `Recalled`, `Recall_refused of Reason_code.t`; make
  `Failed` and `Returned` carry a `Reason_code.t`; map ISO `ACSP`/`PDNG` to `Pending` and
  `ACSC`/`ACCC`/`ACCP` to `Settled`. ([payment schemes](payment-schemes.md))
- `Reason_code.t`: every code in the payment-schemes table plus `Other of string`, with
  `kind` (Reject, Return, Recall, Rfro, Answer) and `is_customer_error`.
- Identifiers per SEPA transfer: `end_to_end_id` and `uetr` (UUIDv4) generated by us,
  `instr_id`, and provider `msg_id`, `pmt_inf_id`, `tx_id` as options; a `Sepa_text`
  validator (Latin set, Max35, no leading or trailing `/`, no `//`); `Ustrd` at most 140
  characters; `charge_bearer` always `SLEV`; `acceptance_ts` in milliseconds for Inst.
- Timers: Inst `Timed_out` 10 s after `acceptance_ts`, status query at 12 s; SCT alert if not
  settled after 2 business days; recall windows 10 business days (DUPL, TECH) or 13 months
  (FRAD); answer expected within 15 business days.
- `Vop.t = Match | Close_match of string | No_match | Not_possible`, stored with the
  transfer.
- Crypto deposits `Seen | Confirming of int | Credited | Reorged`: BTC at 3 confirmations
  (6 above EUR 10 000), ETH and ERC-20 at the `finalized` tag; a reorg after credit books
  a reversal and opens a case. Lightning out: hold, settle on preimage (kept as proof),
  release on a permanent failure.
- Booking: `Submitted` places a hold; `Settled` captures it; `Rejected` and `Timed_out`
  release it; a late `Settled` books a fresh debit; returns and recalls are new credits.
- `Sca`: `Element = Knowledge | Possession | Inherence`; `Otp`, `Totp`, `Passkey` are all
  possession, so add `Pin` (knowledge) and `Biometric` (inherence) and verify only when
  two categories pass; binding over operation, amount, currency and payee; hard ceiling
  of 5 attempts; per-customer `Lock` (temporary, then permanent with notice); generic
  failure messages; `Exemption.t` with its RTS article; counters since last SCA for
  Art 16 (EUR 30, 100, 5) and Art 11 (EUR 50, 150, 5). Fix the `sca.mli` comment: attempts
  are RTS Art 4(3)(b), the 5 minutes is Art 4(3)(d) session inactivity.
  ([SCA](strong-customer-authentication.md))
- `Sca_event` audit record per challenge transition (fields in the SCA note); codes never
  stored.
- `Reconciliation`: add break records (`Timing`, `Missing_internal`, `Missing_external`,
  `Amount_mismatch`, `Duplicate`), first-seen business date, ageing buckets, and
  resolution only through a ledger adjustment. ([ledger](ledger.md))

## kyc-core

- Have: case status machine, tiers T0-T3, verification steps, `Pii.t` redaction, screening
  hits with reviewer decision, idempotent events, audit without PII.
- `Risk_band = Low | Medium | High` from a versioned weighted score over the four factor
  groups (customer, country, product, channel); floors: PEP, high-risk third country or
  confirmed adverse media force `High`; `Override { band; reason; by; at }` required for a
  manual change. ([KYC and AML](kyc-aml.md))
- `Cdd_level = Simplified | Standard | Enhanced`, with `Edd_trigger.t` forcing `Enhanced`.
- `Pep.t` with kind, scope, function, start and end dates, `edd_until = ended + 12 months`
  at the earliest, senior-management approval, source-of-wealth check date.
- Screening: `List_source` (`Eu_fsf`, `Un_sc`, `Ofac_sdn`, `Uk_sanctions_list`,
  `Pep_list`, `Adverse_media`), `Screen_reason` (onboarding, list update, data change,
  periodic, payment), hit keeps list version, entry id, score and algorithm;
  `Discounted` needs two distinct operators. Name matcher: NFKD, strip marks, casefold,
  drop punctuation and legal-form tokens, max Jaro-Winkler of full and token-sorted names,
  alert at 0.85 (tunable).
- `Review { last_reviewed; next_due }`: 1, 3, 5 years by band; overdue raises an alert.
- `Alert_state`, `Case_state`, `Report_state` (draft, approved, filed, acknowledged,
  rejected by FIU) and `fiu_request_due` (5 working days).
- Retention: `relationship_ended_at`, `refused_at`, `retain_until = end + 5 years`,
  optional `legal_hold` (at most 5 more years); a purge erases PII after it.
- Field classes `Public | Internal | Pii | Sensitive_pii`; PII encrypted under a
  per-customer key so erasure is key destruction once retention ends.
  ([reliability](reliability-and-security.md))
- `Travel_rule.t` with the TFR Art 14(1) originator and 14(2) beneficiary fields, for
  every crypto transfer; ownership proof of a self-hosted address above EUR 1 000.
  ([payment schemes](payment-schemes.md))

## card-core (planned)

- Card states `Inactive | Active | Frozen | Closed`; frozen declines `57`. ([cards](cards.md))
- Auth record: `auth_id`, `card_id`, `network_txn_id`, kind (`Auth | Incremental | Advice
  | Financial`), requested and approved amounts, merchant amount and currency, merchant
  name, MCC, country, entry mode, ECI, 3DS `transStatus`, response code, `decided_by`
  (`Us | Stand_in | Provider_default`), `expires_at`.
- Auth states `Pending -> Authorized -> Partially_cleared -> Cleared`, plus `Declined`,
  `Reversed`, `Expired`; advice and stand-in enter `Authorized` and cannot be declined.
- Hold expiry 7 days, 30 days for MCC 7011, 7512, 4411 or estimated auths; a late clearing
  still posts.
- Response codes from rule outcomes: 51 funds, 57 not permitted, 61 amount limit, 65
  frequency limit, 05 for review; decisions within 500 ms of a 2 s webhook budget.

## risk-rules

- Have: severities, engine, caps, velocity, beneficiary cooldown, structuring, countries,
  self-hosted wallet, MCC block, online toggle, review queue, sexp policies.
- After Allow, Review or Block, decide `Sca_required | Exempt of Exemption.t` in the order
  own accounts (Art 15), trusted beneficiary (13), recurring (14), low value (16), TRA (18);
  beneficiary changes, standing order set-up, new device and crypto payouts always need
  SCA. TRA stays off until `Tra_book` keeps rolling 90-day fraud rates per type against
  the Annex bands. ([SCA](strong-customer-authentication.md))
- `Context` gains session and device facts, credential-change time, failed SCA count,
  inbound history, account opening time, VoP result and card history; new rules
  `mule_pass_through`, `fan_in`, `new_account_payout`, `account_takeover`,
  `app_first_large_payment`, `vop_not_matched`, `card_testing`.
  ([fraud and monitoring](fraud-and-monitoring.md))
- Screening of every SEPA counterparty and crypto destination: potential match is
  `Review` with a hold, confirmed is `Block`; tighter caps for `High` risk customers.
  ([KYC and AML](kyc-aml.md))
- Card rules in a fixed order returning response codes (see card-core). ([cards](cards.md))
- Overrides of tier limits use the same maker-checker type as ledger adjustments.

## risk-models

- In progress: synthetic generator with five typologies, Python training (gradient
  boosted and logistic, isotonic calibration), a reference scorer over a committed JSON
  export.
- `Features.of_context` over `Risk_rules.Context.t` is the only feature code, used for
  training export and serving, so features are point-in-time by construction.
  ([fraud and monitoring](fraud-and-monitoring.md))
- Tree walk semantics written down per format: XGBoost `x < cond` in float32 with NaN to
  `default_left`; LightGBM `x <= threshold` in float64 with `missing_type`; parity test on
  about 1 000 vectors including NaN and split-boundary values, tolerance 1e-6.
- Report average precision and precision at the daily alert budget on a prequential split
  with a 7-day label delay gap, besides the FPR operating points; synthetic data scores are
  not evidence of real performance.
- `Score.to_rules` gives `model_review` and `model_block`; reasons carry score, model
  version and top three reason codes from path attributions; shadow mode is severity
  `Allow`; weekly PSI per feature with review at 0.1 and retrain at 0.25.

## banking-provider (planned)

- Normalized events: SEPA status with ISO reason codes and late settlement after timeout,
  returns and recall answers; crypto deposits with confirmations and reorgs; Lightning
  settlement with preimage; card `Auth_request`, `Auth_advice`, `Reversal`, `Clearing`,
  `Refund`, `Expiry`. ([payment schemes](payment-schemes.md), [cards](cards.md))
- The fake provider simulates each of them, plus VoP results and webhook redelivery out of
  order, so the state machines are tested on the unhappy paths.
- The provider id of each event is the inbox key. ([reliability](reliability-and-security.md))

## neobank-api (planned)

- `Idempotency-Key` on every `POST`, scope (customer, method, route, key), SHA-256 request
  hash, stored response for 24 hours, `422` on reuse with a different body, `409` while in
  progress. ([reliability](reliability-and-security.md))
- Outbox for provider calls written with the state change, the transfer id as the
  provider's idempotency key; inbox keyed by provider event id, signature checked on raw
  bytes in constant time.
- Sessions: 5 minutes idle; balance and 90-day history without new SCA for 180 days;
  everything else needs fresh SCA; errors never name the failed factor.
  ([SCA](strong-customer-authentication.md))
- Never show alerts, cases or reports; a held payment reads "under review".
  ([KYC and AML](kyc-aml.md))
- One `Redact` rule set: PAN last four, IBAN country and last four, never OTP, CVV, PIN,
  tokens or secrets.
- `Incident.t` with the DORA criteria, Minor or Major classification and computed report
  deadlines (4 h after classification and at most 24 h after detection, 72 h, 1 month).
  ([risk and treasury](risk-and-treasury.md))
- Recovery targets for the demo: RPO 0 for acknowledged entries, RTO 15 minutes (restore,
  replay, reconcile with the provider).

## specs

- An outsourcing register page with the EBA para 54 fields (and para 55 for critical
  providers): the BaaS provider, the cloud host, blockchain node providers.
  ([risk and treasury](risk-and-treasury.md))
- A retention table per record type (AML 5 years after the relationship, payment records
  5 years, accounting 10 years by default, audit logs 12 months online).
