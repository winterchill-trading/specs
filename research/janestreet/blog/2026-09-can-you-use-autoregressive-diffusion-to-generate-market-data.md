# Can you use autoregressive diffusion to generate market data?

- Source: <https://blog.janestreet.com/can-you-use-autoregressive-diffusion-to-generate-market-data/>
- Published: 2026-09-30
- Kind: blog post

## Summary

- Most quant models map a stream of book events to a price forecast; a generative model
  would instead synthesize the events themselves, including their arrival times, giving
  rollouts with far more texture than a point forecast.
- The core question is what kind of data market data is. The action space is discrete
  (orders added, cancelled, executed), yet prices have such high cardinality that they look
  continuous, and timing is truly continuous. Distributions are spiky: improving by one tick
  ("pennying") is far more common than two, and orders arrive in bursts, for example at
  whole-second times.
- An ML research intern built an event-level autoregressive diffusion model, following
  autoregressive image generation without vector quantization, on four years of US
  equities events (timestamp, price, kind and other fields).
- Architecture: a causally masked transformer encoder gives a latent per event; a small
  categorical head predicts whether the next event is a trade or a BBO update; a diffusion
  head conditioned on the latent and the true kind (AdaLN) generates the continuous fields.
  At inference the sampled kind conditions the diffusion head.
- A DDPM head (noise prediction, 1,000-step cosine schedule, DDIM sampling) diverged, with
  88% to 95% of samples beyond 8 standard deviations on all seven continuous targets,
  because small noise errors are amplified at high noise. More steps and stochastic sampling
  helped, but rectified flow matching (predicting velocity along a straight noise-to-data
  path) worked without tuning.
- The central difficulty: market data has continuous snapshots but evolves discretely, by
  microstructure. Inter-arrival times have point masses at zero (simultaneous events), at the
  fastest reaction time and at whole seconds; prices cluster at the bid, ask and mid.
- Class imbalance (only 8% of events are trades) made the head overpredict trades.
  Splitting BBO changes into finer classes (size only, ask up, bid down and so on) let
  point masses become their own classes, such as zero elapsed time, and left simpler
  diffusion targets (the size of a nonzero gap, the magnitude of a price move). A 20-class
  head gave much better marginals but does not scale to many features, for example venue
  identity.
- "Atom smoothing" instead smooths a spiky distribution and re-sculpts the spike's mass
  without a discontinuity; it works only if variables are represented so the spikes are
  exposed.
- Evaluation: one-step generation after a real context of 10,240 events, scored by total
  variation distance per marginal, plus a classifier trained to tell generated next events
  from real ones (which captures joint and temporal structure). Atom-smoothed
  representations produced much more realistic samples.
- Autoregressive rollouts degrade with horizon (for example spreads widen); the model is
  not yet a realistic generator, but the project clarified the key choices: what to predict
  categorically versus continuously, and how to represent features for diffusion.

## Relevance to us

- **Testing and simulation:** the post's realism checks (trade share of events,
  inter-arrival point masses, price clustering at touch and mid) are cheap metrics for our
  synthetic market. **Action:** in `specs`, add a DuckDB query over the
  [market-data](../../../repos/market-data.md) `bbo` and `trades` tables that reports the
  trade share of events and a histogram of BBO inter-arrival times (zero, under 1 ms, 1 to
  10 ms and up), then record its output for one live Hyperliquid hour and one
  [hl-sim](../../../repos/hl-sim.md) hour.
- **Testing and simulation:** the `Market_sim` noise traders in
  [exchange-core](../../../repos/exchange-core.md) are driven by a seeded random walk,
  while real flow is lumpy. **Action:** add a `Market_sim` option that places a configurable
  share of noise orders exactly one tick inside the touch, and compare the resulting
  histogram with the live one from the query above.
- **Research tooling:** a discriminator that tries to tell synthetic events from real
  ones is a single-number realism score. Context for the planned price-anchor work
  ([roadmap](../../../roadmap.md)); no change yet.

Tags: `simulation`, `market-data`, `ml`
