# Using group theory to explore the space of positional encodings for attention

- Source: <https://blog.janestreet.com/using-group-theory-to-explore-positional-encodings-attention/>
- Published: 2026-04-22
- Kind: blog post

## Summary

- Attention compares queries with keys by a dot product that ignores position, so a
  positional encoding perturbs that product, usually so only relative position matters.
  The choice governs how the model perceives time; RoPE, which rotates query and key
  components by position-dependent angles like clock hands, is the most common.
- The author, an ML researcher, asked what encodings are possible at all and found the
  space tightly constrained.
- Setup: queries and keys are time series, with "time" being an index, elapsed wall time
  in a time series, or a learned clock as in Mamba. Time-independent changes of basis are
  treated as not changing the encoding.
- Assumption 1, linearity: queries and keys are transformed by time-dependent matrices, so
  an encoding is fully described by the matrix linking time t to time s.
- Assumption 2, translation invariance: only relative time is observable, which also helps
  generalization to sequences longer than those seen in training. Equal times are
  normalized to the identity, so the encoding reduces to one matrix per time offset.
- Shifting by zero is then a no-op and two shifts compose, so with assumption 3,
  continuity, the matrices form a one-parameter group and equal the matrix exponential of a
  fixed generator. Choosing an encoding means choosing a generator.
- Diagonalizable generators split into independent 1D and 2D pieces. Real eigenvalues give
  growth (ruled out), no encoding (NoPE) or exponential decay, as in linear attention;
  gated models are best read as learning how far to advance time. Decay only makes sense
  with causal masking.
- Complex conjugate pairs give rotations at constant frequency, which is RoPE; with decay
  it is the damped RoPE of RetNet and Mamba-3.
- Defective (Jordan block) generators add polynomial-in-time terms, like a frictionless
  puck's position growing linearly; the author found no literature on them and doubts they
  are practical.
- Addenda: ALiBi (a linear distance penalty) falls outside the linear assumption but can be
  built from a defective generator by augmenting queries and keys, and a related paper
  (GRAPE) uses the same one-parameter-group framework.
- Conclusion: the sensible options are already in use, so hunting for a better encoding of
  this kind is unlikely to pay off.

## Relevance to us

- Not relevant: ML theory with no consumer in our repos.
- **Action:** none.

Tags: `ml`, `education`
