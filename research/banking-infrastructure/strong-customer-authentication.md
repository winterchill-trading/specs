# Strong customer authentication (PSD2 RTS)

Kind: reference.

## Summary

- PSD2 Art 97(1) requires SCA when the payer (a) accesses its payment account online,
  (b) initiates an electronic payment, or (c) does anything remotely that may imply a risk
  of fraud. Art 97(2) adds dynamic linking to amount and payee for remote payments.
- SCA (PSD2 Art 4(30)) is two or more independent elements from knowledge, possession and
  inherence. Commission Delegated Regulation (EU) 2018/389 (the RTS) applies from
  14 September 2019; amended by (EU) 2022/2360, applying from 25 July 2023.
- RTS Art 4: the code is accepted once; failures never reveal which element was wrong; at
  most five consecutive failures before a block; at most 5 minutes of inactivity after
  authentication for online account access.
- RTS Art 5: the payer sees amount and payee, the code is specific to both, and any change
  to either invalidates the code.
- Exemptions (Arts 10-18) are optional for the PSP ("may"), except Art 10a (access through
  an AISP), where the PSP "shall not" apply SCA within the 180-day window.
- Transaction risk analysis (Art 18) needs a rolling 90-day fraud rate under the Annex
  reference rate for the threshold band; two quarters over the rate stops the exemption.
- If the payer's PSP does not require SCA, the payer bears no loss unless it acted
  fraudulently (PSD2 Art 74(2)): every exemption is a liability decision.

## Elements and independence

| Category | Counts (EBA) | Does not count (EBA) |
| --- | --- | --- |
| Knowledge | PIN, password chosen by the user | Card number, CVV printed on card; transaction history; contact details (Q&A 2020_5215) |
| Possession | Device bound by app key; SMS OTP (the SIM is the element, Q&A 2018_4039); dynamic CVV card | Card details printed on the card; printed OTP lists (EBA-Op-2019-06, Table 2) |
| Inherence | Fingerprint, face and similar biometrics with very low false-accept (Art 8) | Not listed here |

- Arts 6-8: knowledge must resist disclosure, possession must resist replication, inherence
  must give "a very low probability" of an impostor passing.
- Art 9: a breach of one element must not compromise the others. On a multi-purpose device
  (phone holding the app key and receiving the OTP) the PSP uses separate secure execution
  environments and checks the software has not been altered.
- Two elements of the same category are not SCA. An SMS OTP plus an app-bound key are both
  possession; pair the OTP with a PIN/password or a biometric.

## Authentication code (Art 4)

| Rule | Text or value |
| --- | --- |
| 4(1) | Code "shall be only accepted once" |
| 4(2) | No element derivable from a disclosed code; no new code from old codes; unforgeable |
| 4(3)(a) | A failure does not reveal which element was incorrect |
| 4(3)(b) | Consecutive failures before temporary or permanent block "shall not exceed five within a given period of time" |
| 4(3)(c) | Sessions protected against capture and manipulation |
| 4(3)(d) | Inactivity after authentication for online account access: at most 5 minutes |
| 4(4) | Block length and retries set by risk; alert the payer before the block becomes permanent; secure re-enablement procedure |

The RTS sets no lifetime for an unanswered challenge; the 5 minutes is session inactivity.

## Dynamic linking (Art 5)

1. 5(1)(a) the payer is made aware of the amount and the payee.
1. 5(1)(b) the code is specific to that amount and payee.
1. 5(1)(c) the code accepted corresponds to the original amount and payee.
1. 5(1)(d) any change to the amount or payee invalidates the code.
1. 5(2) confidentiality, authenticity and integrity of amount and payee through all phases.
1. 5(3)(a) card payment with a blocked amount: the code is specific to the blocked amount;
   5(3)(b) batch: specific to the batch total and the payees.

## Exemptions

| Art | Exemption | Conditions |
| --- | --- | --- |
| 10 | Account info, direct | Balance or last 90 days of transactions, no sensitive payment data; SCA on first access and when more than 180 days since last SCA access (was 90 before 2022/2360) |
| 10a | Account info via AISP | Mandatory ("shall not apply"); same 90-day data, same first-access and 180-day rule; PSP may still apply SCA for objectively justified, documented suspicion |
| 11 | Contactless at POS | Single tx at most EUR 50, and cumulative since last SCA at most EUR 150 or at most 5 consecutive tx |
| 12 | Unattended terminal | Transport fare or parking fee |
| 13 | Trusted beneficiaries | SCA to create or amend the list; payments to a listed payee exempt |
| 14 | Recurring | SCA for the first payment of a series with the same amount and same payee; later ones exempt |
| 15 | Own accounts | Payer and payee same natural or legal person, both accounts at the same ASPSP |
| 16 | Low-value remote | Single tx at most EUR 30, and cumulative since last SCA at most EUR 100 or at most 5 consecutive tx |
| 17 | Secure corporate | Legal persons only, dedicated processes, authority confirms equivalent security |
| 18 | Transaction risk analysis | Remote tx; see below |

## Transaction risk analysis (Arts 18-21 and Annex)

Reference fraud rates (Annex), by exemption threshold value (ETV):

| ETV | Remote card-based | Remote credit transfers |
| --- | ---: | ---: |
| EUR 100 | 0.13% | 0.015% |
| EUR 250 | 0.06% | 0.01% |
| EUR 500 | 0.01% | 0.005% |

- 18(2)(a) the PSP's fraud rate for the type is at or below the reference for the band;
  18(2)(b) amount at or below the ETV.
- 18(2)(c) real-time analysis finds none of: abnormal spending or behavioural pattern of
  the payer; unusual device/software access information; malware in any session of the
  authentication; a known fraud scenario; abnormal payer location; high-risk payee location.
- 18(3) at least: payer's previous spending patterns; transaction history of each user;
  payer and payee location at payment time; abnormal payment patterns against history;
  combined into "a risk scoring for each individual transaction".
- Art 19: rate = value of unauthorised or fraudulent remote tx (recovered or not) divided
  by value of all remote tx of the same type, both SCA and exempted, rolling quarter
  (90 days).
- Art 20: report immediately to the authority when over the reference; stop the exemption
  for that band after two consecutive quarters over; resume after one quarter at or below,
  notifying the authority first.
- Art 21: record at least quarterly, per payment type, remote and non-remote separately:
  fraud value, total value and fraud rate (split by SCA and by each exemption), average
  tx value, and count of tx per exemption.

## Transaction monitoring (Art 2)

Art 2(1): mechanisms to detect unauthorised or fraudulent payments, based on elements
typical of the user. Art 2(2) minimum risk factors:

- lists of compromised or stolen authentication elements;
- the amount of each payment transaction;
- known fraud scenarios;
- signs of malware infection in any session of the authentication procedure;
- for an access device or software provided by the PSP, a log of its use.

## What to log per SCA event

PSD2 and the RTS set no field list; this set covers Arts 2, 4, 5, 19-21 and Art 74(2):
challenge id, customer id, operation kind, amount and currency, payee identifier, binding
hash, element categories used, method, channel and device id, created/answered/expiry
times, attempt number, result, block applied, exemption claimed with its article and
inputs (cumulative counters, TRA score, fraud rate and band), the risk decision id, and
later the fraud flag on the payment.

## PSR and PSD3

Council and Parliament reached a provisional agreement on 27 November 2025; the SCA
provisions sit around PSR Arts 85-89 in drafts. Reported content: SCA accessible to users
without smartphones, two inherence elements allowed, SCA when outsourced to technical
providers, merchant-initiated transactions outside SCA. Final text not confirmed
(unverified); the RTS stays the reference until replaced.

## What we adopt

1. `payments-core` `Sca.Element`: `Knowledge | Possession | Inherence`; each
   `Sca.Kind` maps to its element (`Otp` and `Totp` and `Passkey` to `Possession`;
   add `Pin` to `Knowledge`, `Biometric` to `Inherence`). `Challenge` carries
   `factors : Element.t list` and verifies only when two distinct categories pass.
1. `payments-core` `Sca.Binding.create ~operation ~amount ~currency ~payee`: SHA-256 over
   a canonical string `operation|amount_minor|currency|payee_id`. Any change to amount or
   payee yields `Binding_mismatch` and invalidates the challenge (Art 5(1)(d)); batches
   bind the total and the sorted payee list (Art 5(3)(b)). The UI renders amount and payee
   from the same fields hashed.
1. `payments-core` `Sca.Challenge`: `max_attempts` default 3, hard ceiling 5
   (`create` rejects more); a verified code is consumed (`Already_verified` never
   authorises twice, Art 4(1)). Default `ttl` 5 minutes is our choice, not the RTS. Fix the
   mli comment: attempts are Art 4(3)(b), the 5 minutes is Art 4(3)(d) session inactivity.
1. `payments-core` `Sca.Lock`: per customer, `Temporary of { until }` after 5 consecutive
   failures across challenges (30 minutes), `Permanent` after a second temporary lock in
   24 hours; notify before `Permanent` (Art 4(4)). Wrong answers return one generic error.
1. `payments-core` `Sca.Exemption.t`: `Account_info_direct` (Art 10),
   `Account_info_aisp` (10a), `Contactless` (11), `Unattended_transport_parking` (12),
   `Trusted_beneficiary` (13), `Recurring_same_amount_payee` (14), `Own_accounts` (15),
   `Low_value_remote` (16), `Corporate_process` (17), `Tra of { band : Etv.t; score : int }`
   (18), with `article : t -> string`. `Etv.t = Eur_100 | Eur_250 | Eur_500`.
1. `payments-core` `Sca.Counters` since last SCA per customer and channel:
   `remote_count`, `remote_sum_minor`, `contactless_count`, `contactless_sum_minor`;
   reset on every successful SCA. Art 16 holds when amount <= 3000 and
   (sum + amount <= 10000 or count < 5); Art 11 with 5000/15000/5.
1. `risk-rules` decides `Sca_required | Exempt of Exemption.t` per payment, after
   Allow/Review/Block. Order: Art 15, 13, 14, 16, 18. Any `Review` or `Block`, a beneficiary
   list change, a standing-order setup, a new device, or a crypto payout forces SCA. The
   demo enables only 15, 13, 14 and 16; TRA stays off until bookkeeping exists.
1. `risk-rules` `Tra_book`: per type (`Card_remote | Credit_transfer`) daily buckets of
   `fraud_value_minor` and `total_value_minor`, rolling 90 days; `rate` in basis points
   against Annex rates (13/6/1 bp card, 1.5/1/0.5 bp transfers). Band disabled after two
   consecutive quarters over, re-enabled after one quarter under; emit `Report_due`.
   Art 18(2)(c) checks map to existing velocity, device, country and block-list rules.
1. `risk-rules` quarterly `Sca_report` (Art 21): per type and remote/non-remote, fraud
   value, total, rate by SCA versus each exemption, average value, count per exemption.
1. `neobank-api`: idle session timeout 5 minutes after SCA login (Art 4(3)(d)); balance and
   90-day history readable without new SCA for 180 days since the last SCA access
   (Art 10); everything else (payments, beneficiaries, card PAN, limits, profile, device
   enrolment) requires fresh SCA. Errors never name the wrong factor.
1. `kyc-core` audit: one append-only `Sca_event` per challenge transition with the fields in
   "What to log per SCA event"; payee and amount kept, OTP and PIN never stored; retention
   follows the audit policy. `ledger` stores the challenge id or exemption on each payment
   posting so Art 74(2) liability is traceable.

## Open questions

- Does the provider's SMS OTP confirmation count as our SCA, or must we add a knowledge
  factor ourselves before calling it? Two-factor needs a second category.
- Which party applies SCA for card payments (issuer side at the provider) and what it
  reports back for the audit trail.

## Sources

- Commission Delegated Regulation (EU) 2018/389 (RTS on SCA and CSC):
  <https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32018R0389>
- Commission Delegated Regulation (EU) 2022/2360 (Arts 10 and 10a):
  <https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32022R2360>
- Directive (EU) 2015/2366 (PSD2), Arts 4(30), 74(2), 97:
  <https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32015L2366>
- EBA Q&A 2018_4039 (SMS OTP is possession):
  <https://www.eba.europa.eu/single-rule-book-qa/qna/view/publicId/2018_4039>
- EBA Q&A 2018_4135 (card details not a factor; EBA-Op-2019-06 Table 2):
  <https://www.eba.europa.eu/single-rule-book-qa/qna/view/publicId/2018_4135>
- EBA Q&A 2020_5215 (history and contact details not knowledge):
  <https://www.eba.europa.eu/single-rule-book-qa/qna/view/publicId/2020_5215>
- EBA Q&A 2023_6820 (Arts 10 and 10a after 2022/2360):
  <https://www.eba.europa.eu/single-rule-book-qa/qna/view/publicId/2023_6820>
