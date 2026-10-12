# A study of sequence weighting at scale

- Source: <https://blog.janestreet.com/a-study-of-sequence-weighting-at-scale/>
- Published: 2026-09-14
- Kind: blog post

## Summary

- Data mixing questions (general versus OCaml-specific code, old versus recent market
  regimes, high-quality versus all data) decide where a model spends capacity, and are too
  expensive to grid-search at large scale, so hyperparameters are usually fit at small scale
  and extrapolated, Chinchilla style.
- Extrapolation works only for behavior that is scale-invariant or changes predictably.
  The authors call unpredictable scaling "aberrant" and report that data mixing is prone to
  it; a published report saw the ranking of a code-heavy and a STEM-heavy mix flip with size.
- To separate mix weight from data quality and uniqueness, they study sequence weighting:
  each training sequence gets a random loss weight, log-uniform from 0.01 to 10, and after
  training the model is re-evaluated on its own training set.
- They fit an "effective sequence weight exponent": the power of a sequence's weight that
  best explains its loss reduction. Zero means weight does not matter, one means proportional
  learning, above one means learning concentrated on the heaviest sequences.
- Prior work predicts different limits: interpolation results suggest large models tend
  toward zero, while a 2026 study found optimal repetition of valuable domains rises
  mildly with size.
- Models: two in-house families (dense, and mixture-of-experts) from tens of millions to
  hundreds of billions of parameters, plus Qwen 2.5 from 500M to 72B; 3 epochs on an
  internal text benchmark, heavy regularization, and hyperparameters for the largest models
  from power-law fits.
- Result: within a family, the exponent tends to rise through small and medium scales
  (up to tens of billions of parameters) and fall at the largest; more epochs move the peak
  toward smaller models; absolute values do not line up across families.
- Hypothesis: small models only learn general patterns, medium models add the
  idiosyncratic patterns with the most weight, and large models can learn nearly all of
  them regardless of weight.
- Remedies: extrapolate data-mix results only from sufficiently large models, or adjust
  training weights for the observed exponent (untested); and keep checking where scaling
  predictions fail.

## Relevance to us

- We train no models; nothing here applies to our repos.
- **Action:** none.

Tags: `ml`, `research-tooling`
