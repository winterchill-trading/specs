# Risk, treasury and regulatory basics

Kind: reference.

## Summary

- An EMI does not lend customer money: it safeguards it (EMD2 Art 7 via PSD2 Art 10),
  redeems e-money at par on request (Art 11) and pays no interest on it (Art 12). A credit
  institution may lend deposits and is bound by capital ratios and the LCR/NSFR instead.
- Safeguarded funds are never commingled; funds still held at the end of the business day
  after receipt sit in a separate account at a credit institution or in secure, liquid,
  low-risk assets, or are covered by insurance or a guarantee.
- EMI capital: EUR 350,000 initial capital; own funds for issuing e-money by Method D,
  at least 2 % of average outstanding e-money. Credit institution: EUR 5 million initial
  capital, CET1 4.5 %, Tier 1 6 %, total 8 % plus a 2.5 % conservation buffer.
- MiCA CASPs hold the higher of Annex IV capital (EUR 50,000 / 125,000 / 150,000 by
  class) and a quarter of last year's fixed overheads; client crypto is kept in a
  per-client register of positions and segregated legally and operationally (Art 75).
- DORA applies from 17 January 2025 to banks, payment institutions, EMIs and CASPs: ICT
  risk framework reviewed yearly, major-incident reports at 4 h / 72 h / 1 month, a
  register of ICT third-party arrangements, yearly testing and TLPT every 3 years.
- AML records are kept 5 years after the relationship ends; GDPR storage limitation
  requires deletion after that unless another legal obligation applies.

## Liquidity (credit institutions)

| Item | Rule | Source |
| --- | --- | --- |
| LCR definition | Liquidity buffer / net liquidity outflows over a 30 calendar day stress period | 2015/61 Art 4(1); CRR Art 412(1) |
| LCR minimum | At least 100 % | 2015/61 Art 4(2) |
| Stable retail deposits (DGS-covered) | 5 % outflow; 3 % with a qualifying DGS and approval | 2015/61 Art 24 |
| Other retail deposits | 10 %; 10-15 % or 15-20 % when higher-risk criteria (e.g. large balances) apply | 2015/61 Art 25 |
| Inflow cap | Inflows recognised up to 75 % of outflows | 2015/61 Art 33(1) |
| Level 2A assets | Cap 40 % of buffer, 15 % haircut | 2015/61 recital 32 |
| NSFR | Available / required stable funding over one year, at least 100 % | CRR2 (2019/876) recital 110 |
| Breach | Notify the authority immediately, restoration plan, daily reporting until compliant | CRR Art 414 |

Intuition: a neobank's retail balances are the outflow side; with a 10 % run-off on
EUR 10m of non-covered demand deposits, the bank holds at least EUR 1m of HQLA net of
capped inflows. An EMI has no LCR; the safeguarding account plays the same role at 100 %.

## EMI versus credit institution

| Topic | EMI (EMD2 2009/110/EC) | Credit institution (CRD/CRR) |
| --- | --- | --- |
| Customer money | Safeguarded, not lent (Art 7) | Deposits, may be lent |
| Initial capital | EUR 350,000 (Art 4) | EUR 5 million (CRD Art 12) |
| Ongoing capital | Method D: 2 % of average outstanding e-money (Art 5(3)); authority may move it +/- 20 % (Art 5(5)) | CET1 4.5 %, Tier 1 6 %, total 8 % of RWA (CRR Art 92) + 2.5 % CET1 conservation buffer (CRD Art 129) |
| Interest | Prohibited on holding time (Art 12) | Allowed |
| Redemption | At any moment, at par (Art 11(2)); fee only in listed cases | Deposit terms |
| Liquidity | Safeguarding covers it | LCR >= 100 %, NSFR >= 100 % |

Safeguarding, PSD2 Art 10(1), applied to EMIs by EMD2 Art 7(1) (references to 2007/64
read as 2015/2366 per PSD2 Art 114):

- (a) segregation: funds "shall not be commingled at any time" with others' funds; those
  still held "by the end of the business day following the day when the funds have been
  received" go to a separate account in a credit institution or secure, liquid, low-risk
  assets, insulated from other creditors in insolvency; or
- (b) insurance or a comparable guarantee from an unaffiliated insurer or credit
  institution for the same amount.
- EMD2 Art 7(1): funds paid by payment instrument (card) need safeguarding once credited,
  and in any case within five business days after issuance of the e-money.
- PSD2 Art 21: records kept at least 5 years.

Daily reconciliation in practice (UK, FCA PS25/12, CASS 15, in force 7 May 2026): an
internal and an external safeguarding reconciliation at least once each reconciliation
day (excludes weekends, bank holidays, closed foreign markets); compare the "D+1
segregation requirement" with the "D+1 segregation resource"; a shortfall is topped up,
from own funds if needed; e-money and unrelated payment-service funds are reconciled
separately; monthly safeguarding return; annual safeguarding audit above GBP 100,000 of
relevant funds; a resolution pack.

## Crypto (MiCA, Regulation 2023/1114, applies from 30 December 2024)

| Item | Rule | Article |
| --- | --- | --- |
| CASP prudential floor | Higher of Annex IV amount and 1/4 of last year's fixed overheads | 67(1) |
| Class 1 | Execution, placing, transfer services, RTO, advice, portfolio management: EUR 50,000 | Annex IV |
| Class 2 | Class 1 + custody, crypto-for-funds, crypto-for-crypto exchange: EUR 125,000 | Annex IV |
| Class 3 | Class 2 + operating a trading platform: EUR 150,000 | Annex IV |
| Client funds (non-EMT) | Placed with a credit institution or central bank by end of next business day, separately identifiable | 70(3) |
| Custody register | Register of positions per client; movements recorded as soon as possible | 75(2) |
| Statements | Statement of position at least once every three months and on request | 75(5) |
| Segregation | Client crypto segregated from own holdings, legally and operationally; access means identified | 75(7) |
| Liability | Liable for loss attributable to the CASP, capped at market value | 75(8) |
| EMT | Deemed e-money (48(2)); issued and redeemed at par (49(3)-(4)); no interest by issuer or CASP (50) | 48-50 |
| EMT reserve | At least 30 % of funds in separate credit-institution accounts | 54(a) |

## Operational risk and outsourcing (EBA/GL/2019/02, applies from 30 September 2019)

- A function is critical or important when its failure would materially impair compliance
  with authorisation conditions, financial performance, or continuity of services (para 29).
- Register (para 54), all arrangements: reference number; start, renewal, end dates and
  notice periods; function description, data outsourced, personal data yes/no; category;
  provider name, registration number, LEI, address, parent; countries of service and data;
  critical yes/no with reasons; cloud service and deployment model and data location;
  date of last criticality assessment.
- Extra for critical or important (para 55): group users, intra-group yes/no, last risk
  assessment and result, approving body, governing law, last and next audit, material
  sub-outsourcers and locations, substitutability (easy, difficult, impossible),
  alternative providers, time-critical yes/no, estimated annual cost.
- Exit strategy for critical or important functions (paras 106-108): termination,
  provider failure, quality deterioration, material risks; documented, tested exit plans.

## DORA (Regulation 2022/2554, applies from 17 January 2025)

| Item | Rule | Source |
| --- | --- | --- |
| ICT risk framework | Documented, reviewed at least once a year and after major incidents | Art 6(5) |
| Testing | Systems supporting critical or important functions tested at least yearly | Art 24(6) |
| TLPT | Identified entities, at least every 3 years | Art 26(1) |
| Third-party register | All ICT contractual arrangements, critical or important flagged; yearly report to the authority | Art 28(3); ITS 2024/2956 templates B_01.01-B_07.01 |
| Exit strategies | Required for ICT services supporting critical or important functions | Art 28(8) |
| Initial notification | Within 4 h of classification as major, no later than 24 h from awareness | RTS 2025/301 Art 5(1)(a) |
| Intermediate report | Within 72 h of the initial notification; updated when operations recover | Art 5(1)(b) |
| Final report | No later than 1 month after the latest intermediate report | Art 5(1)(c) |
| Weekend relief | Next working day noon, not for credit institutions' initial/intermediate | Art 5(4)-(5) |

Classification (RTS 2024/1772 Art 8-9): major when critical services are affected and
either the data-loss threshold is met or two or more other thresholds are met:

| Criterion | Threshold |
| --- | --- |
| Clients, counterparts, transactions | > 10 % of clients or > 100,000 clients of the service; > 30 % of counterparts; > 10 % of daily average transaction count or value; relevant clients hit |
| Reputational impact | Any condition in Art 2 (media, complaints, regulatory breach, client loss) |
| Duration and downtime | Duration > 24 h, or downtime > 2 h for services supporting critical or important functions |
| Geographical spread | Impact in two or more Member States |
| Data losses | Adverse impact on availability, authenticity, integrity, confidentiality; or successful malicious unauthorised access |
| Economic impact | Costs and losses > EUR 100,000 |

Recurring incidents: two or more in 6 months with the same root cause that together meet
the test count as one major incident; checked monthly (Art 8(2)).

## Data retention

| Record | Period | Source |
| --- | --- | --- |
| CDD documents, transaction records | 5 years after the relationship ends or the occasional transaction; up to 5 more on request | AMLD 2015/849 Art 40; AMLR 2024/1624 Art 77(3) from 10 July 2027 |
| Payment-service records | At least 5 years | PSD2 Art 21 |
| Accounting records | National law, commonly 6-10 years (unverified per state) | Not harmonised |
| Personal data | No longer than necessary (storage limitation) | GDPR Art 5(1)(e) |

The tension resolves through GDPR Art 17(3)(b): erasure does not apply while a legal
obligation requires the processing; after the retention period ends, data is deleted or
anonymised.

## What we adopt

1. `ledger`: account classes `Customer_funds_liability` (one per customer and currency,
   credit-normal) and `Safeguarding_asset` (one per safeguarding bank account and
   currency, debit-normal), plus `Own_funds` and `Fees_income`; customer money never posts
   to an own-funds account. A posting moving fees from customer to own funds is the only
   path out, and is tagged `Fee`.
2. `ledger`: `Safeguarding_recon.t = { date; currency; requirement : Money.t
   (* sum of Customer_funds_liability *); resource : Money.t (* sum of Safeguarding_asset
   by internal books *); external_balance : Money.t (* provider statement *);
   internal_diff; external_diff; status : Balanced | Shortfall | Excess; resolved_by :
   Posting_id.t option }`, one per currency per reconciliation day, produced by a
   `safeguarding-report` command. Shortfall creates an `Own_funds -> Safeguarding_asset`
   top-up posting proposal; the report never edits balances.
3. `ledger`: `Exposure.t` per currency (EUR, BTC, ETH, USDC, USDT): customer liability,
   held assets, house position, net open position; `exposure-report` daily and on demand.
4. `ledger`: crypto custody keeps a register of positions per customer and asset;
   `kyc-core` statements include a quarterly crypto statement of position (MiCA Art 75(5)).
5. `money`/`ledger`: `Outstanding_emoney.average ~days:180` and
   `Own_funds_requirement.method_d = 2 %` of it, compared against EUR 350,000.
6. `neobank-api` ops: `Incident.t = { id; detected_at; classified_at option; severity :
   Minor | Major; criteria_met : Criterion.t list; services_affected; clients_affected;
   transactions_affected; amount_affected; member_states; data_impact; costs_eur;
   root_cause; status : Open | Mitigated | Resolved; reports : Report.t list }` where
   `Criterion.t = Clients | Reputation | Duration | Geography | Data_loss | Economic` and
   `Major` iff a critical service is hit and (`Data_loss` or two others). Deadlines are
   computed: initial = min(classified_at + 4h, detected_at + 24h); intermediate =
   initial + 72h; final = last intermediate + 1 month.
7. `specs`: `specs/ops/outsourcing-register.md`, one row per provider with the para 54
   fields and, for critical ones, the para 55 fields; the BaaS provider, cloud host and
   blockchain node providers are rows; each critical row links an exit plan.
8. `kyc-core`, `payments-core`, `ledger`: every record type carries `retention : {
   basis : Aml | Psd2 | Accounting | Consent; starts : Relationship_end | Event_date;
   years : int }`; AML and PSD2 are 5 years, accounting 10 years by default; a purge job
   lists records past retention and anonymises PII fields, leaving ledger amounts intact.
9. `risk-rules`: no interest accrual on EUR or EMT balances; redemption at par is a
   transfer state, not a rule exception.

## Open questions

- Which licence does the provider hold (EMI, bank, CASP), and does it reconcile
  safeguarding per end customer or pooled? The demo mirrors pooled with per-customer
  liabilities.
- National accounting retention for the target Member State.

## Sources

- EMD2, Directive 2009/110/EC: <http://publications.europa.eu/resource/celex/32009L0110>
- PSD2, Directive 2015/2366: <http://publications.europa.eu/resource/celex/32015L2366>
- CRR, Regulation 575/2013: <http://publications.europa.eu/resource/celex/32013R0575>
- CRR2, Regulation 2019/876: <http://publications.europa.eu/resource/celex/32019R0876>
- CRD, Directive 2013/36/EU: <http://publications.europa.eu/resource/celex/32013L0036>
- LCR Delegated Regulation 2015/61: <http://publications.europa.eu/resource/celex/32015R0061>
- MiCA, Regulation 2023/1114: <http://publications.europa.eu/resource/celex/32023R1114>
- DORA, Regulation 2022/2554: <http://publications.europa.eu/resource/celex/32022R2554>
- RTS 2024/1772, incident classification: <http://publications.europa.eu/resource/celex/32024R1772>
- RTS 2025/301, incident reporting: <http://publications.europa.eu/resource/celex/32025R0301>
- ITS 2024/2956, register of information: <http://publications.europa.eu/resource/celex/32024R2956>
- AMLD4, Directive 2015/849: <http://publications.europa.eu/resource/celex/32015L0849>
- AMLR, Regulation 2024/1624: <http://publications.europa.eu/resource/celex/32024R1624>
- GDPR, Regulation 2016/679: <http://publications.europa.eu/resource/celex/32016R0679>
- EBA Guidelines on outsourcing arrangements, EBA/GL/2019/02:
  <https://www.eba.europa.eu/sites/default/files/documents/10180/2551996/38c80601-f5d7-4855-8ba3-702423665479/EBA%20revised%20Guidelines%20on%20outsourcing%20arrangements.pdf>
- FCA PS25/12, safeguarding regime for payments and e-money firms:
  <https://www.fca.org.uk/publication/policy/ps25-12.pdf>
