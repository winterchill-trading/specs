# KYC, CDD and AML

Kind: reference.

## Summary

- FATF R.10 requires CDD when establishing a business relationship, for occasional transactions
  above USD/EUR 15,000 (USD/EUR 1,000 for VASPs, INR.15), on suspicion, and on doubts about
  earlier identification data. R.11 keeps records for at least five years.
- In the EU, Directive (EU) 2015/849 (AMLD, amended by 2018/843) applies until Regulation (EU)
  2024/1624 (AMLR) applies from 10 July 2027 (Art. 90). AMLA (Regulation (EU) 2024/1620, seat
  Frankfurt) starts direct supervision in 2028.
- AMLR Art. 26 caps the customer information refresh at 1 year for higher-risk customers and
  5 years for all others. Former PEPs keep EDD for at least 12 months after leaving (Art. 45).
- Beneficial ownership through ownership interest is 25 % or more of shares or voting rights
  (AMLR Art. 52); AMLD used "25 % plus one share" (Art. 3(6)).
- Records are kept 5 years after the relationship ends, the occasional transaction, or the
  refusal; a competent authority may extend by at most 5 more years; then personal data is
  deleted (AMLR Art. 77).
- Suspicions go to the FIU promptly, regardless of amount, including attempted transactions;
  FIU information requests are answered within 5 working days (AMLR Art. 69). Disclosing an
  assessment or report to the customer is prohibited (Art. 73, FATF R.21).

## FATF Recommendations (text updated October 2025)

| Rec. | Requirement |
| --- | --- |
| R.1 | Identify and assess ML/TF risk; apply a risk-based approach; enhanced measures for higher risk, simplified allowed for lower risk |
| R.6 | Freeze funds of UN-designated persons "without delay", meaning ideally within hours of designation |
| R.10 | CDD on (i) business relations, (ii) occasional transactions above USD/EUR 15,000 or R.16 wire cases, (iii) suspicion, (iv) doubts on prior data; measures (a) identify and verify customer, (b) beneficial owner, (c) purpose, (d) ongoing due diligence |
| R.11 | Transaction records and CDD records, account files and analysis results for at least 5 years after the relationship ends |
| R.12 | Foreign PEPs: risk systems, senior management approval, source of wealth and funds, enhanced ongoing monitoring; domestic and international-organisation PEPs on a risk basis; family and close associates included |
| R.15 | New technologies risk assessment before launch; VASPs licensed or registered; INR.15: VASP CDD threshold USD/EUR 1,000, R.16 travel rule applies to virtual asset transfers |
| R.20 | Report suspicions to the FIU promptly |
| R.21 | Safe harbour for good-faith reporting; tipping-off prohibited |

## EU rules: AMLD now, AMLR from 10 July 2027

| Topic | AMLD 2015/849 | AMLR 2024/1624 |
| --- | --- | --- |
| When CDD applies | Art. 11: relationship; occasional EUR 15,000 or more; transfer of funds over EUR 1,000; suspicion; doubts | Art. 19: relationship; occasional EUR 10,000 or more; CASP occasional EUR 1,000 or more; cash EUR 3,000 or more; suspicion regardless of threshold |
| CDD measures | Art. 13(1) | Art. 20(1)(a)-(i): identify/verify customer and BO, purpose, sanctions check (d), ongoing monitoring (f), PEP determination (g) |
| Cannot complete CDD | Art. 14(4) | Art. 21: refrain or terminate, consider reporting to the FIU |
| Verification timing | Art. 14 | Art. 23: before the relationship; SDD may defer, at most 60 days (Art. 33) |
| Ongoing monitoring | Art. 13(1)(d), 14(5) | Art. 26: refresh at most every 1 year (higher risk) and 5 years (others), sooner on change |
| Simplified DD | Art. 15 | Art. 33: lower risk only; stops on suspicion |
| Enhanced DD | Art. 18, 18a | Art. 34: Arts. 29-31, 36-46 cases, own higher-risk cases; complex, unusually large or unusual-pattern transactions |
| High-risk third countries | Art. 9, 18a | Arts. 29-31: Commission lists, EDD measures from Art. 34(4), countermeasures |
| Self-hosted addresses | (none) | Art. 40: assess risk, verify originator or beneficiary, enhanced monitoring |
| PEP | Art. 3(9), 20-23; Art. 22: at least 12 months | Art. 2 def.; Art. 42 measures; Art. 45 at least 12 months after leaving; Art. 46 family and close associates |
| Beneficial owner | Art. 3(6): 25 % plus one share | Art. 52: 25 % or more of shares or voting rights |
| Report to FIU | Art. 33: promptly, attempted included; Art. 35 refrain | Art. 69: promptly, regardless of amount; reply to FIU in 5 working days (can be under 24 hours); Art. 71 refrain |
| Tipping-off | Art. 39 | Art. 73 |
| Retention | Art. 40: 5 years, extension at most 5 years | Art. 77: 5 years from end, transaction or refusal; extension at most 5 years; records unredacted |

AMLR Art. 34(4) EDD measures include more information on customer and beneficial owners,
source of funds and wealth, senior management approval, enhanced monitoring, and a first
payment through an account in the customer's name at a credit institution.

## EBA risk factors and remote onboarding

| Factor group (GL/2021/02 Guideline 2) | What is assessed |
| --- | --- |
| Customer | Business or professional activity (high-corruption sectors, cash-intensive, MSB, casinos), reputation (adverse media), nature and behaviour (TF indicators) |
| Country | Residence of customer and BO, main place of business, personal links; EU high-risk third country list, FATF statements, sanctions |
| Product, service, transaction | Transparency (anonymity, third-party instructions), complexity, value or size |
| Delivery channel (2.20-2.21) | Non-face-to-face, reliability of remote CDD, impersonation controls, introducers |

- Weighting (3.4-3.7): no single factor dominates, profit never influences the rating, high
  risk must remain reachable, legal always-high cases cannot be weighted away, and automated
  scores can be overridden with a documented rationale. Bands: often high, medium, low (3.8).
- Always higher risk (4.46): PEP, third-country correspondent, high-risk third country, and
  complex, unusually large or unusual-pattern transactions without obvious purpose.
- Non-face-to-face (4.29-4.31): verify identity and assess the added risk; electronic
  identification at eIDAS "high" assurance does not by itself raise risk.
- Monitoring (4.72-4.75): decide which high-risk factors force real-time monitoring, and
  sample all transactions ex post to tune the system.
- Remote onboarding (EBA/GL/2022/15, applies from 2 October 2023): time-stamped, readable
  evidence (para. 26); unattended flows need capture at session time, liveness detection and
  face-to-document matching (para. 41); poor evidence interrupts or restarts the flow (para.
  40); randomised actions (para. 43); extra controls such as a first payment from an EEA
  account in the customer's name or a single-use passcode (para. 44).

## Sanctions screening

| List | Publisher, format | Notes |
| --- | --- | --- |
| EU consolidated list | Financial Sanctions Files (FSF), XML, updated daily | Asset freezes under EU restrictive measures |
| UN Security Council consolidated list | UN, XML | Freeze without delay (R.6); AMLR Art. 27 covers the gap before EU transposition |
| OFAC SDN | US Treasury | Includes digital currency addresses (unverified for the field name) |
| UK Sanctions List | UK government | Sole UK source since 28 January 2026; the OFSI Consolidated List closed that day |

- When: at onboarding (customer, BOs, representatives), on every list update (re-screen the
  base against the delta), on customer data change, at periodic review, and on every payment
  for counterparty names (and addresses for crypto). AMLR Art. 20(1)(d) makes the sanctions
  check a CDD measure.
- Matching practice (practice): Unicode NFKD, strip diacritics, casefold, drop punctuation,
  honorifics and legal-form tokens; transliterate to Latin; compare full name and token sets;
  score with Jaro-Winkler and a phonetic key. OFAC's own search pre-filters at 50 % edit-
  distance similarity, then takes the higher of Jaro-Winkler and Soundex scores (FAQ 249);
  OFAC publishes no match cutoff.
- Disposition: compare secondary identifiers (date of birth, nationality, address); OFAC's
  steps end in block or reject and a report within 10 business days. Discounting a hit is a
  documented decision; a second reviewer (four eyes) on discounts is common practice.
- PEP and adverse media come from commercial lists; EBA 4.49 requires firms to understand that
  such lists are not exhaustive.

## Monitoring, periodic review and reporting

- Periodic review cadence of 1 / 3 / 5 years for high / medium / low risk is common practice;
  only the 1-year and 5-year maxima are law (AMLR Art. 26).
- Workflow: alert (rule or screening hit) -> case (grouped alerts) -> investigation ->
  decision (no further action, exit, or report) -> STR/SAR filed with the FIU -> FIU
  acknowledgement and follow-up requests. Many FIUs (Malta among them) take reports in goAML,
  as XML upload or web form; profiles vary by country.
- The Art. 69(2) assessment is retained whether or not a report is filed (Art. 77(1)(b)).
- AMLA drafts the reporting format standard (Art. 69(3)); the national format applies until then.

## What we adopt

1. `kyc-core` `Cdd_level.t = Simplified | Standard | Enhanced`. The demo never selects
   `Simplified` for crypto products; `Enhanced` is forced by any `Edd_trigger.t`.
2. `kyc-core` `Risk_band.t = Low | Medium | High`, with `Risk_score.t = { score : int (0-100);
   band; inputs : Risk_input.t list; model_version : string; override : Override.t option;
   computed_at }`. Bands: Low 0-29, Medium 30-59, High 60-100 (our choice). `Override.t =
   { band; reason : string; by : Staff_id.t; at }` is required to move a band (EBA 3.6).
3. `Risk_input.t` per factor group with points: `Customer` (occupation sector, PEP status,
   adverse media), `Country` (residence, nationality; `High_risk_third_country` from a loaded
   EU list), `Product` (crypto, Lightning, card, expected monthly volume band), `Channel`
   (`Remote_unattended`, `Remote_attended`, `Eid_high`). Hard floors: PEP, high-risk third
   country or confirmed adverse media forces at least `High`; weights live in a versioned table.
4. `Edd_trigger.t = Pep | Family_or_close_associate | High_risk_third_country |
   Unusual_transaction | Self_hosted_exposure | Adverse_media | Manual of string`.
5. `Pep.t = { kind : Pep | Family_member | Close_associate; scope : Domestic | Foreign |
   Intl_org; function_ : string; started : Date.t; ended : Date.t option; edd_until : Date.t
   option; approval : (Staff_id.t * Time.t) option; sow_sof_checked_at : Time.t option }`.
   `edd_until = ended + 12 months` at the earliest; staff may only extend it.
6. `kyc-core` screening: `List_source.t = Eu_fsf | Un_sc | Ofac_sdn | Uk_sanctions_list |
   Pep_list | Adverse_media`; `Screen_reason.t = Onboarding | List_update | Data_change |
   Periodic | Payment`; hits keep `list_version`, `matched_entry_id`, `score`, `algorithm`.
   `Hit_state.t = Open | Under_review | Discounted | Confirmed | Escalated`. `Discounted`
   needs two distinct staff ids and a reason; `Confirmed` sanctions blocks the customer.
7. Name matcher (in `kyc-core`, used by `risk-rules`): NFKD, strip marks, casefold, drop
   punctuation and stopword tokens, ICU-style transliteration, max of Jaro-Winkler on the full
   name and token-sorted name; alert at 0.85 or more (tunable, practice). DOB or country
   mismatch lowers priority but never auto-closes a sanctions hit.
8. `Review.t = { last_reviewed : Date.t; next_due : Date.t }` with `next_due = last + 1y`
   (High), `3y` (Medium), `5y` (Low); a band change recomputes it; overdue reviews raise an alert.
9. Case and report states: `Alert_state.t = Open | Closed_no_action | Escalated`,
   `Case_state.t = Open | Investigating | Pending_decision | Closed_no_report | Closed_reported`,
   `Report_state.t = Draft | Approved | Filed | Acknowledged of { fiu_ref : string } |
   Rejected_by_fiu`. Store `fiu_request_due = received + 5 working days` for FIU requests.
10. Tipping-off rule: customer-facing APIs (`neobank-api`) never expose alerts, cases or
    reports; a held payment shows a generic "under review" status only.
11. Retention fields on customer, application and case: `relationship_ended_at`,
    `refused_at`, `retain_until = (ended or refused) + 5 years`, `legal_hold : { until; reason;
    authority } option` (at most 5 extra years); a deletion job erases PII after `retain_until`
    unless held; the `ledger` journal keeps ids, not PII.
12. `risk-rules`: screen counterparty names on every SEPA in and out payment and destination
    addresses on every crypto withdrawal; potential match -> `Review` with a `ledger` hold;
    confirmed -> `Block`. Unusual-transaction rules (`Review`): amount far above the expected
    profile, structuring just below caps, fiat-in then crypto-out within 48 hours, first
    transfer to a self-hosted address. Customers at `High` get tighter caps and all
    transactions monitored in real time (EBA 4.74).

## Open questions

- Which national FIU and format (goAML profile) applies for the provider's licence.
- Exact OFAC and EU list fields for crypto addresses. The travel-rule data and the EUR 1 000
  self-hosted ownership check are in [payment schemes](payment-schemes.md#travel-rule).

## Sources

- FATF Recommendations, updated October 2025 (mirror):
  <https://www.cr.gov.hk/en/compliance/aml_cft/FATF/FATF_Recommendations.pdf>
- Directive (EU) 2015/849 consolidated: <https://eur-lex.europa.eu/eli/dir/2015/849/2021-06-30/eng>
- Directive (EU) 2015/849 Art. 11: <https://www.legislation.gov.uk/eudr/2015/849/article/11>
- Regulation (EU) 2024/1624 (AMLR): <https://eur-lex.europa.eu/eli/reg/2024/1624/oj/eng>
- AMLR Arts. 69, 73, 77, 90 (article view of the OJ text):
  <https://www.springlex.eu/en/packages/aml/amlr-regulation/article-69/>
- About AMLA: <https://www.amla.europa.eu/about-amla_en>
- EBA ML/TF Risk Factors Guidelines EBA/GL/2021/02:
  <https://www.eba.europa.eu/sites/default/files/document_library/Publications/Guidelines/2021/963637/Final%20Report%20on%20Guidelines%20on%20revised%20ML%20TF%20Risk%20Factors.pdf>
- EBA remote onboarding Guidelines EBA/GL/2022/15:
  <https://www.eba.europa.eu/sites/default/files/document_library/Publications/Guidelines/2022/EBA-GL-2022-15%20GL%20on%20remote%20customer%20onboarding/1043884/Guidelines%20on%20the%20use%20of%20remote%20customer%20onboarding%20solutions.pdf>
- OFAC FAQ 249, Sanctions List Search scoring: <https://ofac.treasury.gov/faqs/249>
- OFAC FAQs on potential matches: <https://ofac.treasury.gov/faqs/topic/1591>
- UK Sanctions List: <https://www.gov.uk/government/publications/the-uk-sanctions-list>
- EU Financial Sanctions Files user manual:
  <https://circabc.europa.eu/d/a/workspace/SpacesStore/9cf02a9e-7604-4178-a21d-d0b6bdcb4114/MA_FSF_EN.pdf>
- goAML services (UNODC): <https://goaml.unodc.org/goaml/en/services.html>
