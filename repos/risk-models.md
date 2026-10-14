# risk-models

Machine-learned scores for transaction monitoring and fraud. Models are trained offline in
Python and scored in OCaml from a small committed JSON export. The features are the ones
`risk-rules` defines (`Risk_rules.Features`); the scores reach a decision through
`Risk_rules.Model.S` as two rules, `model_review` and `model_block`, which start in shadow
mode.

| | |
| --- | --- |
| Repository | `winterchill-trading/risk-models` |
| opam package | `risk-models` |
| Library | `risk_models` (module `Risk_models`) |
| Binary | `risk-models` (`schema`, `encode`, `check`, `score`, `bench`) |
| Python | `python/` (`generate.py`, `train.py`, `evaluate.py`, `export.py`, run with `uv`) |
| Status | done: OCaml scorer, models and parity tests in place; CI green. Trained on synthetic data only |

## Key modules

| Module | Purpose |
| --- | --- |
| `Schema` | Ordered feature names with a digest (hex MD5 of the names joined by newlines, identical in Python) |
| `Encoding` | `Risk_rules.Features.t` to `float array`: `Features.to_floats` order, then one-hot columns for `rail`, `card_channel` and `payee_check` |
| `Forest` | Tree ensemble in flat arrays with per-split missing-value modes; scoring is `[@zero_alloc]` |
| `Linear` | Logistic baseline (log1p on heavy-tailed features; missing features contribute nothing) |
| `Calibration` | Isotonic, Platt or identity calibration; applying it is `[@zero_alloc]` |
| `Lightgbm_dump` | Reads LightGBM `Booster.dump_model()` JSON into a `Forest` |
| `Scorer` | Loads `model.json` and refuses a schema digest mismatch; margin, probability, calibrated score, and `explain` returning a `Risk_rules.Model.Score.t` with the top three reasons |
| `Risk_model` | The `Risk_rules.Model.S` adapter, the two rules, shadow mode and policy specs |
| `Monitor` | Live score histogram, PSI against the calibration window, Stable, Review or Retrain, Prometheus text |
| `Bench` | Scoring latency and allocation |

## Contract with risk-rules

- `Risk_rules.Features` defines every feature once. `risk-models schema` writes the
  encoding schema to `python/risk_models_train/features.json`, which the Python side reads;
  a test fails when the file and the library disagree.
- Every `model.json` records the schema digest; `Scorer.load` refuses a model trained on
  another layout.
- The Python generator mirrors the meaning of each risk-rules field in its own code. That
  second implementation is a known source of training and serving skew. The real-data path
  exists: `risk-rules features` turns a journaled context into features and
  `risk-models encode` turns those into CSV rows in model order. Joining labels to those
  rows for `train.py` is not built.

## Two rules, shadow first

- `model_review` (Review) sits at the lowest score that keeps the calibration window within
  the daily alert budget.
- `model_block` (Block) sits at the lowest score whose precision on the calibration window
  reaches the target (absent when no score does).

Both thresholds ship in `model.json`, chosen by `evaluate.py`. `Risk_model.rules` caps both
at Allow by default, and `rule_specs` wraps them in `Shadow`: hits are journaled with score,
model name, version and reasons, but change no decision. The model's version is the first
12 hex digits of the MD5 of its JSON.

## Model format

`model.json` (format 1), written by `python/export.py`, holds the schema (name, version,
feature names, digest), the `kind` (`gbdt` as parallel arrays, `lightgbm`, or `logistic`),
the isotonic calibration knots, the score histogram of the calibration window for `Monitor`,
and the review and block thresholds with the budget and precision they were chosen for.
Tree semantics follow scikit-learn: `x <= threshold` goes left, NaN follows `missing_left`.

## Results on the synthetic set

Time-ordered split with a 7-day label delay gap: days 0 to 51 train, 52 to 65 calibrate,
66 to 72 are dropped, 73 to 90 test (146 504 rows, 504 positive, 0.34%).

| | scikit-learn trees | LightGBM | Logistic baseline |
|---|---|---|---|
| Average precision | 0.547 | 0.544 | 0.436 |
| ROC-AUC | 0.979 | 0.980 | 0.972 |
| Recall at 50 alerts a day | 0.647 | 0.635 | 0.565 |
| Recall at 1% FPR | 0.736 | 0.726 | 0.635 |

Recall at 1% FPR by typology (trees): account takeover 1.00, structuring 1.00, money mules
0.95, push payment fraud 0.92, card-not-present bursts 0.51. Card bursts are weakest because
risk-rules' outgoing counts and sums cover transfers only. These numbers describe how the
pipeline separates the patterns the generator injects; they say nothing about real payments.

## Latency and parity

Apple M-series, release build, 150 trees (4350 nodes): `Scorer.score` 2.1 us with 0 words
allocated; `Scorer.explain` with three reason codes 3.4 us. Logistic scoring 0.18 us. An
expect test pins zero words for scoring and for feeding `Monitor.observe_u`.

`test/test_parity.ml` scores 1000 committed rows per model, including missing values and
values exactly at split thresholds, and requires the margin, probability and calibrated score
within 1e-9 of the Python reference. Reason codes may swap only when their contributions are
within 1e-12. The tolerance covers the last-bit differences in `log1p` and `exp` between macOS
and Linux, and the test says so where it applies.

## CI

`ci.yml` builds and tests the OCaml side on the committed models and fixtures, pinning
fixed-decimal, money, ledger, payments-core and risk-rules. `nightly.yml` runs the whole
Python pipeline (about a minute) and checks an average precision floor; it never replaces the
committed models.

## Dependencies

- Depends on: [risk-rules](risk-rules.md). Its CI also pins `fixed-decimal`, `money`,
  `ledger` and `payments-core` through risk-rules' own graph.
- Used by: none yet; the neobank demo is planned to load a model into `risk-rules` through `Risk_model`.
- External: `core`, `core_unix`, `yojson`, `ppx_jane`, `stdlib_upstream_compatible`; Python
  `numpy`, `scikit-learn` 1.9.1 and `lightgbm` 4.7.0 for training only.

## Known gaps

- Synthetic data only. The public transaction-monitoring sets need a registration to download,
  so there is no loader for one. Retrain and re-choose thresholds on real labelled traffic
  before relying on a model.
- The generator re-implements the risk-rules feature definitions in Python instead of exporting
  rows through `Features.of_context`.
- No XGBoost import.
- Reason codes are path credits, not TreeSHAP.
- The nightly training workflow has not run yet.
