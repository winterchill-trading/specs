# A study of sequence weighting at scale

- Source: <https://blog.janestreet.com/a-study-of-sequence-weighting-at-scale/>
- Published: 2026-09-14
- Kind: blog post

## Summary

- Question: when training data is weighted (high-quality versus everything, recent versus
  old regimes), do models learn each sequence in proportion to its weight, and does that
  change predictably with scale? Data mixing often shows "aberrant" scaling that small
  models fail to predict.
- To isolate weight from data quality, every sequence in an internal text benchmark gets a
  random loss weight (log-uniform from 0.01 to 10); after training for up to 3 epochs, the
  loss reduction per sequence is regressed on its weight.
- The fitted exponent is the "effective sequence weight exponent": 0 means weight does
  not matter, 1 means loss reduction is proportional to weight.
- Models: two in-house families (dense and mixture-of-experts, tens of millions to
  hundreds of billions of parameters) and Qwen 2.5 (500M to 72B); hyperparameters for the
  largest models came from Chinchilla-style fits.
- Finding: the exponent rises from small to medium models, then falls again at the
  largest scale; more epochs move the peak toward smaller models; absolute values do not
  line up across families.
- Hypothesis: small models only learn general patterns, medium models learn the
  idiosyncratic patterns with the most weight, large models learn nearly everything. The
  practical advice is to extrapolate data-mix results only from large enough models.

## Relevance to us

- Not relevant: we train no models.
- **Action:** none.

Tags: `ml`, `research-tooling`
