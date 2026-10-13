# Transaction monitoring and fraud detection

Kind: reference.

## Summary

- EU law fixes the minimum inputs: RTS 2018/389 Art. 2(2) requires monitoring of compromised
  credentials, amount, known fraud scenarios, malware signs and abnormal device use.
- Rules catch named typologies (structuring, mules, takeover, APP, card testing); a gradient
  boosted tree model ranks what the rules let through. Both emit `Allow`, `Review`, `Block`.
- Fraud is rare: 0.172% in the public European card set, 3.5% in IEEE-CIS. Evaluate with average
  precision (AUPRC) and precision at a fixed daily alert budget, not ROC AUC.
- Trees beat deep nets on tabular data (45-dataset benchmark; XGBoost vs four deep models)
  and on synthetic AML graphs (GBT with graph features beats GNNs on all AMLworld sets).
- Labels arrive late (chargebacks, claims); validation must be time-ordered with a delay gap.
- Model export is plain JSON. A tree walk in OCaml reproduces XGBoost to 6e-8 and LightGBM to
  1e-15 on raw scores (checked locally with XGBoost 3.4.1 and LightGBM 4.7.0).
- The EU AI Act excludes fraud detection from the high-risk creditworthiness item (Annex III
  5(b)), but reason codes are still needed for operators and customer complaints.

## Regulatory frame

| Instrument | Requirement | Number |
| --- | --- | --- |
| RTS SCA 2018/389 Art. 2(2) | Monitoring factors (a)-(e): stolen credentials, amount, known scenarios, malware, device log | Minimum set |
| RTS Art. 18 + Annex (TRA) | Remote card reference fraud rate per ETV | 0.13% at EUR 100, 0.06% at 250, 0.01% at 500 |
| RTS Art. 18 + Annex (TRA) | Remote credit transfer reference fraud rate per ETV | 0.015% at EUR 100, 0.01% at 250, 0.005% at 500 |
| Reg. 2024/886 Art. 5a | Instant transfer: payee PSP confirms within 10 s of receipt by payer PSP, else reverse | 10 s end to end |
| Reg. 2024/886 Art. 5c | Verification of payee before authorisation; "no match" warns, "almost match" shows name | Euro area from 2025-10-09 |
| Reg. 2024/886 Art. 5d | Sanctions screening of own users at least daily, not per instant transfer | From 2025-01-09 |
| PSR PS24/7 (UK) | APP reimbursement cap per claim (Faster Payments; CHAPS matched) | GBP 85,000 from 2024-10-07 |
| PSR policy (UK) | Optional excess; claim window; cost split sending:receiving | GBP 100; 13 months; 50:50 |
| AI Act 2024/1689 Annex III 5(b) | Creditworthiness is high-risk "with the exception of AI systems used for the purpose of detecting financial fraud" | Exempt |

The UK 50:50 split makes the receiving (mule) side pay half, so inbound mule detection has a
direct cost, not only an AML duty. Volumes for scale: EEA payment fraud EUR 4.3 bn in 2022;
H1 2023 card fraud rate 0.031% of value, credit transfers 0.001%; SCA-authenticated payments
show lower fraud (EBA/ECB 2024). UK 2024: APP losses GBP 450.7 m, under 186,000 cases, 70% of
cases start online; unauthorised fraud GBP 722 m (UK banking trade association, 2025).
Europol EMMA 8 (2022): 8,755 mules identified, 2,469 arrests; EMMA 9: 10,759 mules, 1,013
arrests (year unverified).

## Rule typologies

| Typology | Signals | Rule shape (defaults are our choice) | Severity |
| --- | --- | --- | --- |
| Structuring / smurfing | Many amounts just under a reporting or limit line, or round amounts | >= 3 transfers in 7 d within 5% below the threshold or multiples of 1,000 | Review |
| Mule: pass-through | Inbound credit followed by outbound of most of it | Outbound >= 80% of inbound received <= 60 min ago | Review; Block if account age < 30 d |
| Mule: fan-in | Many unrelated payers | >= 5 distinct inbound senders in 24 h, account age < 30 d | Review |
| Mule: new account | Funds in the first days, early payout | Account age < 7 d and outbound > tier cap / 2 | Review |
| Velocity | Burst of payments | > N transfers in 1 h or 24 h (existing `velocity`) | Review |
| Account takeover | New device + credential or phone change + new beneficiary + max payout | All within 24 h and amount >= 90% of available balance or cap | Block |
| APP scam | New payee, first large payment, VoP not matched, customer under coaching | New beneficiary and amount > 5x 30-day mean, or VoP `No_match`/`Close_match` | Review (step-up warning) |
| Card testing | Many tiny auths, many merchants, high declines, CNP | >= 5 auths < EUR 2 in 10 min, or >= 3 declines in 10 min on one card | Block card auth |

FATF reporting places mules as the main laundering channel for cyber-enabled fraud (2023) and
lists mule networks with cash withdrawal and wires as a layering method (2018). The rule
thresholds above are starting points (unverified as industry figures) to be tuned on data.

## Data sets and metrics

| Data set | Size | Positives | Notes |
| --- | --- | --- | --- |
| European card set (OpenML 1597) | 284,807 tx, 2 days, Sept 2013 | 492 (0.172%) | PCA features V1-V28 |
| Handbook simulator | 1,754,155 tx, 183 days | 14,681 (0.84%) | 5,000 customers, 10,000 terminals |
| IEEE-CIS (Vesta) | 590,540 train tx | 20,663 (3.5%) | Transaction + identity tables |
| PaySim | About 6.36 m rows, 744 hourly steps (unverified count) | Small share | Mobile money; balances leak labels |
| Elliptic (Bitcoin) | 203,769 nodes, 234,355 edges, 166 features, 49 steps | 4,545 illicit, 42,019 licit | RF + GCN embeddings: illicit F1 0.796 |
| AMLworld HI/LI Small to Large | 5 m to 180 m tx | 1 in 807 to 1 in 1,948 | 8 patterns: fan-in/out, cycles, stack... |

- A random classifier has AP equal to the positive rate, so AP shows imbalance; ROC AUC stays
  0.5. The handbook shows a model winning on ROC AUC (0.788 vs 0.763) and losing on AP
  (0.309 vs 0.496).
- Operational metric: precision of the top k alerts per day, k = investigator capacity
  (the realistic-modeling paper, 2018). Cost metric: fraud value caught minus review cost
  per alert.

## Models

- "Why do tree-based models still outperform deep learning on tabular data?" (2022): on
  45 medium (about 10K rows) datasets trees stay best; nets need
  robustness to uninformative features, rotation-variance and irregular functions.
- "Tabular data: deep learning is not all you need" (2021): XGBoost beats four deep
  tabular models on their own datasets, with less tuning; an ensemble of both is best.
- AMLworld (2023), minority F1 %: HI-Small GBT 63.23 vs GNN 56.77; HI-Medium
  65.70 vs 59.71; LI-Small 27.30 vs 20.62. GBT here means XGBoost or LightGBM over graph
  features (fan-in/out degrees, cycles). Elliptic: random forest beats GCN on node features.
- Undersampling biases scores; correct with p = b*p_s / (b*p_s - p_s + 1), b the negative
  sampling rate ("Calibrating probability with undersampling", 2015), then calibrate
  (sigmoid or isotonic).

## Features, labels, validation

The handbook baseline: per customer count and mean amount over 1, 7, 30 days; per terminal
count and fraud share over 1, 7, 30 days shifted back by a 7-day delay (labels are not
known for the last week); weekend and night (hour <= 6) flags. Prequential validation:
7-day train, 7-day delay gap, 7-day test, 4 folds shifted back one week each.

The realistic-modeling paper (2018) separates investigator feedback (fast, biased to
alerts) from delayed labels (chargebacks, claims) and aggregates two
classifiers; this raises alert precision.

Point-in-time correctness: every training row uses feature values as of its event timestamp,
never later (Feast point-in-time joins scan back from the entity timestamp up to a TTL).
Training/serving skew is avoided only if one code path computes features for both.

Monitoring: population stability index per feature and on the score,
PSI = sum over 10 bins of (a - e) * ln(a / e); practice reads < 0.1 stable, 0.1-0.25 watch,
> 0.25 retrain (rule of thumb, unverified as a standard). Elliptic models degrade after a
dark-market shutdown (concept drift; unverified detail).

## Explainability and latency

- TreeSHAP gives exact Shapley values for trees in polynomial time; XGBoost
  `pred_contribs=True` and LightGBM `pred_contrib=True` return n_features + 1 columns (last is
  the bias) that sum to the raw margin (checked locally). Path attribution (value
  change at each split along the taken path) is cheaper and order-dependent.
- Reason codes: the top positive contributions mapped to fixed codes, logged with the score.
- Budgets: SCT Inst gives 10 s end to end for both PSPs; a card issuer must answer within 5 s
  in the European region and an issuing platform's authorization webhook allows 2 s (see
  [cards](cards.md#authorization-messages-iso-8583)). Target scoring
  under 5 ms p99 in process; rules and model together under 20 ms.

## Model export formats (verified locally)

XGBoost `save_model("m.json")` (3.4.1): `learner.learner_model_param.base_score` is a string
in probability space, `"[1.47E-1]"` in 3.x (bracketed) and plain in older files;
`learner.objective.name` (`binary:logistic`); trees at `learner.gradient_booster.model.trees`,
each with parallel arrays `split_indices`, `split_conditions`, `left_children`,
`right_children`, `default_left` (0/1), `split_type` (0 numeric), `base_weights`, `parents`.
A node is a leaf when `left_children[i] = -1`; its value is `split_conditions[i]`. Go left
when `x < split_conditions[i]` (float32 compare); NaN follows `default_left`. Margin is
logit(base_score) plus the sum of leaves.

LightGBM `dump_model()` (4.7.0): `objective` (`"binary sigmoid:1"`), `tree_info[]` with
`tree_structure` nested nodes: internal `split_feature`, `threshold`, `decision_type` (`<=`),
`default_left`, `missing_type` (`None`, `Zero`, `NaN`), `left_child`, `right_child`; leaves
`leaf_value`. Go left when `x <= threshold`; with `NaN`, NaN follows `default_left`; with
`None`, NaN is read as 0. `Zero` semantics (0 and NaN follow default) are unverified.

## What we adopt

1. `risk-rules` `Context` gains `session : Session.t` (`device_id`, `device_first_seen`,
   `credential_changed_at : Time_ns.t option` covering password, phone, email,
   `failed_sca_last_24h : int`), `inbound : Past_inbound.t list` (`at`, `amount`,
   `sender : string` hashed IBAN or address), `account_opened_at`, `vop : Vop.t option` with
   `Match | Close_match | No_match | Not_possible`, and `card_history : Past_auth.t list`
   (`at`, `amount`, `merchant_id`, `approved`).
1. New `Rules` (same optional `?name ?severity` shape): `mule_pass_through ~share_bps:8000
   ~within:(Time_ns.Span.of_min 60.)`, `fan_in ~min_senders:5 ~window:24h ~max_account_age:30d`,
   `new_account_payout ~max_age:7d ~above`, `account_takeover ~window:24h ~balance_share_bps:9000`
   (Block; needs new device and credential change and new beneficiary),
   `app_first_large_payment ~mean_multiple:5` and `vop_not_matched` (Review),
   `card_testing ~max_small:(EUR 2) ~count:5 ~window:10min ~max_declines:3` (Block).
1. Every rule reason names the facts used ("inbound 950.00 EUR 12 min ago, outbound 900.00").
1. New library `risk-models`, modules: `Feature` (stable names, index, `schema_version`),
   `Features.of_context : Risk_rules.Context.t -> float array` (NaN = missing; the only code
   path used for training export and serving), `Forest` (flat arrays per tree: `feature`,
   `threshold`, `left`, `right`, `default_left`, `leaf`, `cmp : Lt_f32 | Le_f64`,
   `nan_as_zero`), `Xgboost_json` and `Lightgbm_json` parsers into `Forest` that reject
   `split_type <> 0`, `num_class <> "0"`, booster other than `gbtree`, and unknown objectives,
   `Calibration` (`Sigmoid of {a; b}` or `Isotonic of {x : float array; y : float array}`),
   `Contrib` (Path attribution in OCaml), `Reason_code`, `Score`.
1. First feature vector (all over `Context`): `amount_eur`, `log1p_amount`, `rail`
   (one-hot: sepa, sepa_inst, onchain, lightning, intraledger, swap, card), `hour_utc`,
   `is_weekend`, `new_beneficiary`, `beneficiary_age_days`, `account_age_days`, `kyc_tier`,
   `count_out_1h`, `count_out_24h`, `count_out_7d`, `sum_out_1h`, `sum_out_24h`, `sum_out_7d`,
   `amount_over_mean_30d`, `distinct_beneficiaries_24h`, `new_device`,
   `hours_since_credential_change`, `failed_sca_24h`, `minutes_since_last_inbound`,
   `inbound_sum_24h`, `vop_result`, `share_of_balance`.
1. Training in Python (LightGBM or XGBoost, `scale_pos_weight` instead of undersampling) on
   rows exported from journaled `Context` values, so features are point-in-time by
   construction. Validation is prequential: 4 weekly folds with a 7-day delay gap; report AP
   and precision at the daily alert budget.
1. Test vectors: the training script writes `vectors.jsonl` (features, raw margin, calibrated
   probability, contributions) for 1,000 rows including NaN and values exactly at split
   thresholds; the OCaml test requires |diff| <= 1e-6 on margin and probability.
1. `Score.to_rules` returns two `Risk_rules.Rule.t`: `model_review` (Review when calibrated
   p >= `t_review`) and `model_block` (Block when p >= `t_block`). `t_review` is the score
   quantile that keeps alerts within the daily budget over the last 4 weeks; `t_block` the
   lowest score with precision >= 0.9 on validation. Reasons carry score, model version and
   the top 3 reason codes.
1. Shadow mode: the same rules built with severity `Allow`, so hits are journaled but change no
   decision; promote after 2 weeks of shadow PSI < 0.1 and stable alert counts.
1. Labels table keyed by transfer or auth id: `Chargeback`, `Customer_reported`,
   `App_claim_upheld`, `Ops_confirmed`, `Ops_cleared`, `Sar_filed` with `labelled_at`; ops
   outcomes are kept as a separate feedback label, not merged with delayed labels.
1. Weekly PSI per feature and score in `risk-models`; Review at 0.1, retrain at 0.25.

## Open questions

- Does the provider expose device and VoP results, or must `neobank-api` compute them?

## Sources

- RTS on SCA, Regulation (EU) 2018/389: <https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32018R0389>
- Instant Payments Regulation (EU) 2024/886: <https://eur-lex.europa.eu/legal-content/EN/TXT/HTML/?uri=CELEX:32024R0886>
- AI Act Annex III: <https://artificialintelligenceact.eu/annex/3/>
- PSR PS24/7 maximum reimbursement: <https://www.psr.org.uk/publications/policy-statements/ps247-faster-payments-app-scams-reimbursement-requirement-confirming-the-maximum-level-of-reimbursement/>
- PSR PS25/5 consolidated policy: <https://www.psr.org.uk/media/rhelv4op/ps25-5-app-scams-reimbursement-consolidated-policy-statement-may-2025.pdf>
- EBA/ECB 2024 Report on Payment Fraud: <https://www.ecb.europa.eu/press/pr/date/2024/html/ecb.pr240801~f21cc4a009.en.html>
- UK annual fraud report 2025 (banking trade association): <https://www.ukfinance.org.uk/news-and-insight/press-release/fraud-report-2025-press-release>
- Europol EMMA results: <https://www.europol.europa.eu/media-press/newsroom/news/2-469-money-mules-arrested-in-worldwide-crackdown-against-money-laundering>
- FATF, Illicit financial flows from cyber-enabled fraud (2023): <https://www.fatf-gafi.org/content/dam/fatf-gafi/reports/Illicit-financial-flows-cyber-enabled-fraud.pdf.coredownload.inline.pdf>
- FATF, Professional money laundering (2018): <https://www.fatf-gafi.org/content/dam/fatf-gafi/reports/Professional-Money-Laundering.pdf>
- European credit card fraud data, OpenML 1597: <https://www.openml.org/api/v1/json/data/1597>
- Fraud detection handbook (features, validation, metrics): <https://fraud-detection-handbook.github.io/fraud-detection-handbook/>
- Credit card fraud detection: a realistic modeling and a novel learning strategy (2018): <https://boracchi.faculty.polimi.it/docs/2017_FraudsTNNLS.pdf>
- Why do tree-based models still outperform deep learning on tabular data? (2022): <https://arxiv.org/abs/2207.08815>
- Tabular data: deep learning is not all you need (2021): <https://arxiv.org/abs/2106.03253>
- Elliptic data set, anti-money laundering in Bitcoin with graph convolutional networks (2019): <https://arxiv.org/abs/1908.02591>
- AMLworld, realistic synthetic financial transactions for AML models (2023): <https://arxiv.org/abs/2306.16424>
- PaySim, EMSS 2016: <https://msc-les.org/proceedings/emss/emss2016/emss2016_249.html>
- XGBoost model IO and schema: <https://xgboost.readthedocs.io/en/stable/tutorials/saving_model.html>
- LightGBM missing values: <https://lightgbm.readthedocs.io/en/latest/Advanced-Topics.html>
- Feast point-in-time joins: <https://docs.feast.dev/getting-started/concepts/point-in-time-joins>
- TreeSHAP, consistent individualized feature attribution for tree ensembles: <https://arxiv.org/abs/1802.03888>
