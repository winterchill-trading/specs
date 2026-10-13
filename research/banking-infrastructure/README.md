# Banking infrastructure

Kind: reference.

Research notes for the [neobank demo](../../design/neobank.md) and its provider-neutral
libraries (`money`, `ledger`, `kyc-core`, `payments-core`, `card-core`, `risk-rules`,
`banking-provider`, `risk-models`, `neobank-api`): what standards bodies, rulebooks,
regulators, papers and the documentation of real core-banking systems say, reduced to the
fields, codes, thresholds and state names our code should use. The per-repository
checklist is [implications.md](implications.md); the must-follow rules for agents are the
`banking-standards` skill in
[oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md).

## How the notes were made

- Read 2026-10-13 from primary sources where they could be fetched: EUR-Lex texts (or the
  Publications Office and national mirrors of the same text when EUR-Lex refused
  automated access), EPC rulebooks and implementation guidelines, EBA guidelines and Q&A,
  FATF recommendations, card scheme public rules, PCI SSC, NIST, EMVCo, BOLT
  specifications, peer-reviewed papers and product documentation.
- Anything not confirmed in a fetched source is marked "(unverified)"; rule thresholds we
  chose ourselves are marked as our choice or as practice.
- Gradient-boosted model export formats were checked locally (XGBoost 3.4.1, LightGBM
  4.7.0): a plain tree walk reproduced their scores to 6e-8 and 1e-15.
- Regulation changes quickly here: the 2025 SEPA rulebooks, the Instant Payments
  Regulation, DORA's reporting RTS and the AMLR (from July 2027) were all checked for the
  version in force on the date above.

## Notes

| Note | One line | Main consumer |
| --- | --- | --- |
| [Core ledger design](ledger.md) | Double entry, two-phase holds, linked entries, idempotency, close, reconciliation | `ledger` |
| [Payment schemes and ISO 20022](payment-schemes.md) | SCT and SCT Inst 2025, reason codes, pacs/pain/camt fields, crypto finality, Lightning, travel rule | `payments-core` |
| [Strong customer authentication](strong-customer-authentication.md) | PSD2 RTS: elements, dynamic linking, attempts, exemptions, TRA fraud bands | `payments-core`, `risk-rules` |
| [KYC, CDD and AML](kyc-aml.md) | FATF, AMLD and AMLR, EBA risk factors, screening, PEPs, reporting, retention | `kyc-core` |
| [Transaction monitoring and fraud](fraud-and-monitoring.md) | Rule typologies, data sets and metrics, GBDT export to OCaml, thresholds, drift | `risk-rules`, `risk-models` |
| [Card issuing](cards.md) | Auth messages and codes, holds, clearing, disputes, 3DS2, tokens, roles | `card-core` |
| [Risk, treasury and regulatory basics](risk-and-treasury.md) | Safeguarding, capital, LCR, MiCA custody, outsourcing, DORA incidents, retention | `ledger`, `neobank-api` |
| [Reliability and security](reliability-and-security.md) | Idempotency, outbox and inbox, four-eyes, keys, PCI DSS scope, audit, GDPR, continuity | all |
| [Implications](implications.md) | Per-repository checklist and the top ten | all |

## Key numbers

| Fact | Value | Note |
| --- | --- | --- |
| SCT Inst hard limit | 10 s from acceptance; no scheme maximum amount since October 2025 | [payments](payment-schemes.md) |
| SCT recall windows | 10 business days (DUPL, TECH), 13 months (FRAD); answer in 15 | [payments](payment-schemes.md) |
| SCA failed attempts, idle session | At most 5; 5 minutes | [SCA](strong-customer-authentication.md) |
| Low-value remote exemption | EUR 30 each, EUR 100 or 5 payments since last SCA | [SCA](strong-customer-authentication.md) |
| TRA reference fraud rates, transfers | 0.015 % / 0.01 % / 0.005 % at EUR 100 / 250 / 500 | [SCA](strong-customer-authentication.md) |
| CDD refresh maximum (AMLR) | 1 year high risk, 5 years others | [KYC](kyc-aml.md) |
| AML record retention | 5 years after the relationship ends | [KYC](kyc-aml.md) |
| Card hold validity | 5 days card present, 10 days card absent, 30 days lodging and rental (one scheme) | [cards](cards.md) |
| Safeguarding deadline | End of the business day after receipt | [treasury](risk-and-treasury.md) |
| DORA major incident reports | 4 h after classification (24 h after detection at most), 72 h, 1 month | [treasury](risk-and-treasury.md) |
| PCI DSS audit logs | 12 months, latest 3 immediately available | [reliability](reliability-and-security.md) |
| Self-hosted wallet ownership check | Above EUR 1 000 (TFR) | [payments](payment-schemes.md) |
