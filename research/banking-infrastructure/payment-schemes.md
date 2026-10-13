# Payment schemes and ISO 20022

Kind: reference.

## Summary

- The 2025 EPC rulebooks (in force since 5 October 2025, 03:30 CET) carry the Instant Payments
  Regulation: SCT Inst has a 10-second hard limit from the AT-T056 timestamp, a 5-7-9 second
  sub-timeline (replacing 10-20-25) and no scheme maximum amount (AM02 is retired).
- SCT credits the Beneficiary PSP within one Banking Business Day (D+1); cut-offs are outside
  the rulebook. Returns go back within 3 Banking Business Days of settlement.
- Recall (camt.056): DUPL and TECH within 10 Banking Business Days, FRAD within 13 months;
  the Beneficiary PSP answers within 15 Banking Business Days (pacs.004 positive, camt.029
  negative). SCT Inst confirms positively with pacs.002 status `ACCP`, negatively with `RJCT`.
- Regulation (EU) 2024/886 adds free Verification of Payee (MTCH/CMTC/NMTC/NOAP), price parity
  with ordinary transfers, and daily sanctions screening of own customers instead of
  per-transaction screening. Payment and e-money institutions comply by 9 April 2027.
- SEPA identifiers are Max35Text in the Latin set, never starting or ending with `/` and
  never containing `//`; remittance is one `Ustrd` of at most 140 characters; charge bearer
  is `SLEV` only.
- Ethereum finality takes about 15 minutes (two epochs); Bitcoin has only probabilistic
  finality and exchanges credit after 1-6 confirmations (3 is common).
- Lightning: the preimage whose SHA-256 is the invoice `p` field proves payment; invoices
  expire after `x` seconds (default 3600).
- The EU Transfer of Funds Regulation 2023/1113 (from 30 December 2024) requires travel-rule
  data on every CASP-to-CASP transfer with no threshold, and an ownership assessment for
  self-hosted addresses above EUR 1 000.

## SEPA rulebooks (2025)

| Item | SCT (EPC125-05 2025 v1.0) | SCT Inst (EPC004-16 2025 v1.1) |
| --- | --- | --- |
| Amount | 0.01 to 999 999 999.99 EUR (AT-T002) | No scheme maximum since 2025; the PSU may set its own limit (IPR Art. 5a(6)) |
| Execution | Credited to Beneficiary PSP within one Banking Business Day | Funds available within 10 s of time of receipt (IPR Art. 5a(4)(c)) |
| Sub-timeline | Cut-offs agreed bilaterally, outside the rulebook (s. 4.2.2) | Target under 5 s (s. 4.2.3 B); TIPS time-out 7 s (was 20 s); 5-7-9 s; roles of 7 and 9 (unverified) |
| No answer | n/a | Restore the payer's account at 10 s (Art. 5a(5)); pacs.028 investigation 2 s after time-out |
| Timestamp | Creation and settlement dates | `AccptncDtTm` (AT-T056), in milliseconds, starts the clock |
| Return | Within 3 Banking Business Days of settlement (pacs.004) | No returns; reject before acceptance only |
| Availability | Banking Business Days | 24/7/365, with announced planned downtime allowed |

Before 2025 the SCT Inst scheme had a 10 s target, a 20 s time-out and a scheme maximum
amount (100 000 EUR in the 2023 rulebook, unverified); none of these apply now.

### Recall and request for recall

| Procedure | Who, why | Deadline to send | Answer |
| --- | --- | --- | --- |
| Recall (camt.056) | Originator PSP: DUPL, TECH | 10 Banking Business Days after execution | Beneficiary PSP within 15 BBD: pacs.004 with `FOCR`, or camt.029 |
| Recall (camt.056) | Originator PSP: FRAD | 13 months after execution | Same; the returned amount may be lower than the original |
| RFRO (camt.056) | Originator wish: AC03, AM09, CUST | Per rulebook (unverified) | 15 BBD; depends on the Beneficiary's consent |
| Status update (pacs.028) | No answer after 15 BBD | Once per recall | n/a |

Only one Recall and one RFRO may be sent per transaction. SCT Inst uses the same 15 BBD
answer rule; the 10 BBD and 13 month sending windows are assumed to match SCT (unverified).

### Reason codes (EPC135-18 and EPC059-18 v6.0)

| Code | Meaning | Used in |
| --- | --- | --- |
| AB05 | Time-out at the creditor agent (Beneficiary PSP) | SCT Inst reject |
| AB06 | Time-out at an instructed agent (CSM) | SCT Inst reject |
| AC01 | Account identifier incorrect (invalid IBAN) | Reject, return |
| AC03 | Wrong creditor account (originator chose wrong IBAN) | RFRO |
| AC04 | Account closed | Return / Inst reject, negative recall answer |
| AC06 | Account blocked | Return / Inst reject |
| AG01 | Transaction forbidden on this account type | Return / Inst reject |
| AG02 | Invalid bank operation code | Reject, return |
| AM02 | Amount above scheme maximum (retired for SCT Inst from 2025) | SCT Inst reject |
| AM04 | Insufficient funds (for the recall debit) | Negative recall answer |
| AM05 | Duplicate payment | Reject, return |
| AM09 | Wrong amount | RFRO |
| AM23 | Amount exceeds settlement limit (pre-funding) | SCT Inst reject |
| ARDT | Already returned | Negative recall answer |
| BE04 | Creditor address missing or invalid | Return / Inst reject |
| CUST | Requested by customer; or beneficiary refuses | RFRO; negative answer |
| DUPL | Duplicate sending | Recall |
| FF01 | Invalid file format | Reject |
| FOCR | Following cancellation request (positive answer) | pacs.004 |
| FRAD | Fraudulent origin | Recall |
| LEGL | Legal reasons | Negative recall answer |
| MD07 | Beneficiary deceased | Return / Inst reject |
| MS02 | Refused by the beneficiary | Return / Inst reject |
| MS03 | Reason not specified | Reject, return |
| NOAS | No answer from beneficiary | Negative recall answer |
| NOOR | Original transaction never received | Negative recall answer |
| RC01 | Invalid BIC | Reject, return |
| RR01 | Missing debtor account or identification (regulatory) | Reject, return |
| RR02 | Missing debtor name or address (regulatory) | Reject, return |
| RR03 | Missing creditor name or address (regulatory) | Reject, return |
| RR04 | Other regulatory reason (AML, embargo, CTF hit) | Reject, return |
| TECH | Technical problem | Recall |
| TM01 | Cut-off missed (SCT); maximum execution time exceeded (SCT Inst) | Reject |

## Instant Payments Regulation (EU) 2024/886

- **Art. 5a** reachability 24 hours a day on any calendar day; 10 s execution; account restored
  if no confirmation; on request a per-transaction or daily maximum the PSU can change at any
  time, with the order refused and the PSU told how to change the limit.
- **Art. 5b** charges for instant transfers are not higher than for other credit transfers;
  Verification of Payee is free.
- **Art. 5c** Verification of Payee runs immediately after the payer enters the payee data and
  before authorisation. EPC VoP API codes: `MTCH` match, `CMTC` close match (the actual name is
  shown to the payer), `NMTC` no match (the payer is warned and may still authorise), `NOAP`
  verification not possible. A PSP that complied is not liable for a misdirected payment; one
  that did not refunds the payer without delay.
- **Art. 5d** PSPs screen their own customers against EU targeted financial restrictive measures
  at least once every calendar day and on new listings, and do not screen per transaction.
- Deadlines (euro area): receive 9 January 2025, send and VoP 9 October 2025; payment and
  e-money institutions: send and receive 9 April 2027.

## ISO 20022 messages

| Message | Purpose | SEPA version | What we read or write |
| --- | --- | --- | --- |
| pain.001 | Customer credit transfer initiation | pain.001.001.09 | `MsgId`, `CreDtTm`, `PmtInfId`, `ReqdExctnDt`, `InstrId`, `EndToEndId`, `UETR`, `InstdAmt`, `ChrgBr` |
| pain.002 | Customer payment status report | pain.002.001.10 | SEPA C2PSP uses it for rejects (`RJCT` + reason) |
| pacs.008 | Inter-PSP credit transfer | pacs.008.001.08 | `TxId`, `IntrBkSttlmAmt`, `IntrBkSttlmDt`, `AccptncDtTm` (Inst) |
| pacs.002 | Inter-PSP status report | pacs.002.001.10 | `TxSts`: `ACCP` positive (SCT Inst), `RJCT` negative |
| pacs.004 | Payment return | pacs.004.001.09 | Return and positive recall answer, `RtrdIntrBkSttlmAmt`, reason |
| camt.056 | Cancellation request (recall, RFRO) | camt.056.001.08 | Reason DUPL, TECH, FRAD, AC03, AM09, CUST |
| camt.029 | Resolution of investigation | camt.029.001.09 | Negative recall answer with reason |
| pacs.028 | Payment status request | pacs.028.001.03 | Inst investigation; recall status update |
| camt.052 / 053 / 054 | Intraday report / statement / debit-credit notification | n/a | Reconciliation input |

Generic `TxSts` codes: `ACSP` accepted, settlement in process; `ACSC` settlement completed on the
debtor account; `ACCC` settlement completed on the creditor account; `PDNG` pending, more checks
to follow; `RJCT` rejected; `ACCP` accepted after customer profile checks.

Field rules (EPC132-08 2025): references are Max35Text; `ChrgBr` "Only SLEV is allowed";
`UETR` is a UUIDv4; `InstdAmt` has at most two decimals; one `Ustrd` of 1..140 characters or
structured remittance (one creditor reference); originator name Max140Text with SEPA length
1..70; purpose is `Purp/Cd` and category purpose `CtgyPurp/Cd`
(ExternalPurpose1Code, for example `SALA`, `SUPP`). Unstructured postal addresses stop being
accepted on 15 November 2026 (2025 SCT Inst v1.1).

Character set: `a-z A-Z 0-9 / - ? : ( ) . , ' +` and space. Identifiers and references use only
this set, must not start or end with `/` and must not contain `//`.

## UK rails

- **Faster Payments**: real-time, 24/7/365, scheme limit GBP 1 million per payment (since
  February 2022); bank limits are lower. ISO 20022 arrives with the New Payments Architecture
  (timing unverified).
- **CHAPS**: RTGS at the Bank of England, no limit, migrated to ISO 20022 in June 2023;
  purpose codes and LEIs mandatory from 1 May 2025 for FI-to-FI and property payments;
  fully unstructured addresses rejected from November 2026; structured remittance from
  November 2027. Operating day roughly 06:00 to 18:00 UK time (unverified).

## Crypto rails

| Chain | Finality | Credit policy observed |
| --- | --- | --- |
| Bitcoin | Probabilistic; attacker with 10 % hash power reverses 5 blocks with P < 0.1 % (whitepaper s. 11) | 1-6 confirmations; 3 is common (about 45 min at one large exchange) |
| Ethereum | Checkpoint finalized after two epochs, about 15 min (64 slots of 12 s); reverting costs at least one third of staked ETH | 10-30 blocks on help pages (secondary), or the `finalized` block tag |
| ERC-20 (USDC, USDT) | As Ethereum | As Ethereum |

Reorg handling: store the block hash and height per deposit; on a new head, walk back to the
common ancestor and mark deposits in orphaned blocks as `Reorged`; re-credit only when the
transaction reappears and reaches the threshold again.

Lightning (BOLT 11 and BOLT 4): prefixes `lnbc`, `lntb`, `lntbs`, `lnbcrt`; multipliers m, u,
n, p; mandatory `p` (payment hash) and `s` (payment secret), one of `d` or `h`; optional `n`,
`x` expiry (default 3600 s), `c` min_final_cltv_expiry_delta (default 18), `f`, `r`, `9`, `m`;
signature mandatory. Payers should not pay after `timestamp + expiry`. Final-node failures:
`incorrect_or_unknown_payment_details` (PERM|15: unknown hash, wrong secret, underpayment,
expiry too soon), `final_incorrect_cltv_expiry` (18), `final_incorrect_htlc_amount` (19),
`mpp_timeout` (23). The PERM bit (0x4000) makes a failure permanent; otherwise the payer may
retry another route. An HTLC in flight is neither failed nor paid until it resolves.

## Travel rule

- **FATF R.16** (revised 13 June 2025, implementation by end of 2030): above a de minimis of
  at most USD/EUR 1 000, originator name, account or unique reference and address (or national
  ID, customer number, date and place of birth); beneficiary name and account. R.15 INR 7(b)
  applies it to virtual asset transfers.
- **TFR 2023/1113**, applies from 30 December 2024. Art. 14(1) originator: name, DLT address and
  account number, address with country, official document number and customer number (or
  date and place of birth), LEI if available. Art. 14(2) beneficiary: name, DLT address and
  account number, LEI if available. No threshold between CASPs; data travels before or with
  the transfer (Art. 14(4)) and is verified (Art. 14(6)).
- Self-hosted address: collect and hold the data; above EUR 1 000 assess that the customer owns
  or controls the address (Art. 14(5) outgoing, Art. 16(2) incoming). Missing data: execute,
  reject, return or suspend on a risk basis (Art. 17). Records kept 5 years (Art. 26).

## What we adopt

1. `payments-core` identifiers per transfer: `transfer_id` (internal UUID), `end_to_end_id`
   (Max35, Latin set, no leading or trailing `/`, no `//`, generated from `transfer_id`),
   `instr_id`, `uetr` (UUIDv4), and from the provider `msg_id`, `pmt_inf_id`, `tx_id` as
   `string option`. A `Sepa_text` validator rejects any other character.
1. Persisted SEPA fields: amount as `money` EUR minor units in 1..99_999_999_999,
   `charge_bearer = SLEV` (constant), debtor and creditor name, IBAN, optional BIC,
   `remittance : Ustrd of string (<= 140) | Scor of string`, `purpose : string option`
   (4 letters), `creation_ts`, `acceptance_ts` (ms, Inst), `requested_execution_date`,
   `settlement_date`.
1. Status enum: `Draft | Awaiting_sca | Submitted | Accepted (ACSP, PDNG) | Settled (ACSC,
   ACCC, ACCP) | Rejected of reason | Timed_out | Returned of reason | Recall_requested |
   Recalled | Recall_refused of reason`. `Timed_out` may be followed by a late `Settled`.
1. `Reason_code.t`: a variant of every code in the table above plus `Other of string`
   (4 chars), with `of_string`, `to_string`, `kind : Reject | Return | Recall | Rfro |
   Answer` and `is_customer_error` (AC01, AC04, AC06, AG01, BE04, MD07, MS02).
1. VoP result type `Match | Close_match of string | No_match | Not_possible`, kept with the
   transfer; `risk-rules` sends `No_match` to `Review` and `Close_match` to a re-confirm step.
1. Timeouts: SCT Inst wait 10 s from `acceptance_ts`, then `Timed_out`; status investigation at
   12 s; SCT expected settled by D+1 and alerted after 2 Banking Business Days; recall allowed
   10 BBD (DUPL, TECH) or 13 months (FRAD), answer expected within 15 BBD.
1. `ledger` booking: `Submitted` places a hold (customer available to `payments_pending`);
   `Settled` moves the hold to `provider_clearing` and books fees; `Rejected` and `Timed_out`
   release the hold; a late `Settled` after `Timed_out` books a fresh debit; `Returned` and
   `Recalled` book a new credit to the customer referencing the original entry (never an edit);
   incoming SEPA credits only on the provider's settled notification.
1. Crypto deposits: `Seen | Confirming of int | Credited | Reorged`; credit BTC at 3
   confirmations (6 above EUR 10 000), ETH and ERC-20 at the `finalized` tag; a reorg after
   credit books a reversal and opens a case. Lightning out: hold, then settle on preimage
   (stored as proof) or release on a final failure; Lightning in credits only when settled.
1. Travel rule: `kyc-core` supplies a `Travel_rule.t` with the Art. 14(1) and 14(2) fields on
   every crypto transfer; withdrawals above EUR 1 000 to self-hosted addresses need an
   ownership proof (signed message or test transfer) before release; data retained 5 years.

## Open questions

- Does the provider expose pacs.002 codes and AT-T056, or only its own status strings?
- Does the provider deliver camt.053/054 files, or only webhooks, for reconciliation?
- Exact 7 s and 9 s obligations in the 2025 SCT Inst rulebook section 4.2.3.

## Sources

- SCT Rulebook 2025 v1.0 (EPC125-05):
  <https://europeanpaymentscouncil.eu/sites/default/files/kb/file/2024-11/EPC125-05%202025%20SCT%20Rulebook%20version%201.0.pdf>
- Guidance on reason codes for SCT R-transactions (EPC135-18 v6.0):
  <https://europeanpaymentscouncil.eu/sites/default/files/kb/file/2024-11/EPC135-18%20v6.0%20Guidance%20on%20Reason%20Codes%20for%20SCT%20R-transactions.pdf>
- Guidance on reason codes for SCT Inst R-transactions (EPC059-18 v6.0):
  <https://europeanpaymentscouncil.eu/sites/default/files/kb/file/2024-11/EPC059-18%20v6.0%20Guidance%20on%20Reason%20Codes%20for%20SCT%20Inst%20R-transactions.pdf>
- SCT C2PSP Implementation Guidelines 2025 (EPC132-08):
  <https://www.europeanpaymentscouncil.eu/sites/default/files/kb/file/2025-10/EPC132-08%20SCT%20C2PSP%20IG%202025%20V1.0.pdf>
- SCT Inst Inter-PSP Implementation Guidelines 2025 (EPC122-16):
  <https://www.europeanpaymentscouncil.eu/sites/default/files/kb/file/2025-10/EPC122-16%20SCT%20Inst%20Inter-PSP%20IG%202025%20V1.0.pdf>
- VOP API Specifications (EPC103-24 v1.0):
  <https://www.europeanpaymentscouncil.eu/sites/default/files/kb/file/2024-11/EPC103-24%20v1.0%20VOP%20API%20Specifications.pdf>
- EPC status update on SCT Inst for the ERPB (2025 rulebook changes):
  <https://www.ecb.europa.eu/paym/groups/erpb/shared/pdf/22nd-ERPB-meeting/Status_update_on_SCT_Inst_scheme.pdf>
- TIPS change request aligning to the 2025 SCT Inst rulebook:
  <https://www.ecb.europa.eu/paym/target/tips/governance/pdf/cr/ecb.tipscr250414_TIPS-0087-SYS.en.pdf>
- Regulation (EU) 2024/886: <https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R0886>
- Regulation (EU) 2023/1113: <https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32023R1113>
- ISO 20022 change request on payment status codes: <https://iso20022.org/milestone/17751/download>
- Faster Payment System, Pay.UK:
  <https://www.wearepay.uk/what-we-do/payment-systems/faster-payment-system/>
- Mandating ISO 20022 enhanced data in CHAPS, Bank of England:
  <https://www.bankofengland.co.uk/paper/2024/policy-statement/mandating-iso-20022-enhanced-data-in-chaps>
- Proof-of-stake finality: <https://ethereum.org/en/developers/docs/consensus-mechanisms/pos/>
- Single slot finality (current time to finality):
  <https://ethereum.org/en/roadmap/single-slot-finality/>
- Bitcoin whitepaper, section 11: <https://bitcoin.org/bitcoin.pdf>
- Exchange deposit confirmations (BTC):
  <https://support.kraken.com/hc/en-us/articles/203325283-Cryptocurrency-deposit-processing-times>
- BOLT 11 invoice encoding: <https://github.com/lightning/bolts/blob/master/11-payment-encoding.md>
- BOLT 4 onion routing and failure codes:
  <https://github.com/lightning/bolts/blob/master/04-onion-routing.md>
- FATF R.16 revision summary:
  <https://www.cgap.org/blog/fatfs-revised-travel-rule-key-changes-for-payment-transparency>
