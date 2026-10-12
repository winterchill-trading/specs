# Mitigating memorization in LLMs

- Source: <https://blog.janestreet.com/mitigating-memorization-in-llms/>
- Published: 2026-09-30
- Kind: blog post

## Summary

- To test whether LLMs can predict, one builds benchmarks of questions with known answers,
  but pretraining data often contains those answers. A model can then look good on history
  and fail on new questions after its knowledge cutoff. An ML research intern tried to
  measure and remove this effect.
- Testbed: predicting cricket match outcomes from match previews, a low-stakes stand-in for
  market-relevant predictions.
- Finding a model that clearly memorized was hard: the previews shifted from mostly men's
  internationals before the cutoff to a broader mix after it, some models were near chance,
  and some could not format answers consistently.
- Three checks: does the model add value over a baseline after the cutoff; is it better
  before the cutoff; and is it more overconfident before the cutoff. Larger models
  predicted better and memorized more.
- Divergence decoding steers the large model's logits using two small auxiliary models
  trained on data up to an earlier and a later cutoff, approximately erasing knowledge from
  the years between. It lowered pre-cutoff accuracy without hurting post-cutoff accuracy, the
  strongest result.
- Distilling the steered model back into weights underperformed both the steered and the
  original model, probably because the general web-text distillation data contained too
  few cricket-related tokens.
- Rewriting previews as basketball did not help; rewriting them as podcast-style
  transcripts (dropping player quotes) improved accuracy on both sides of the cutoff, more
  after it, suggesting less memorization.
- A natural language autoencoder (an encoder mapping activations to text and a decoder
  mapping back, trained jointly with RL) gave decodings whose team-mention counts
  correlated about 0.93 with the prediction, but equally before and after the cutoff, so it
  did not isolate memorization; decodings also hallucinated placeholder teams.
- Decoding the difference between a fine-tuned and a base model's embeddings described the
  fine-tuning task itself. On a synthetic task, readouts showed the model decided around the
  middle layers and spent the last layers on formatting; dropping them sped training 1.5x.
- The project produced no de-memorizer but ranked future directions, with divergence
  decoding the most promising.

## Relevance to us

- **Research tooling:** any backtest of a model on data that may be in its training set is
  contaminated; split evaluation at the model's knowledge cutoff. Context only: none of our
  repos use LLM predictions, so there is nothing to change.
- **Action:** none.

Tags: `ml`, `research-tooling`
