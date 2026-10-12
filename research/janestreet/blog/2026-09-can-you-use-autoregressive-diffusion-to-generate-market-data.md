# Can you use autoregressive diffusion to generate market data?

- Source: <https://blog.janestreet.com/can-you-use-autoregressive-diffusion-to-generate-market-data/>
- Published: 2026-09-30
- Kind: blog post

## Summary

- An ML research intern built an event-level generative model of market data: given the
  stream of trades and BBO updates for a symbol, sample the next event's kind, price,
  sizes and arrival time, then append it and continue.
- Data: four years of US equities events. Architecture follows autoregressive generation
  without vector quantization: a causal transformer encoder yields a latent per event, a
  small categorical head picks the event kind, and a diffusion head conditioned on the
  latent generates the continuous fields.
- A DDPM head on a 1,000-step cosine schedule blew up (88% to 95% of samples beyond 8
  standard deviations); rectified flow matching worked without tuning.
- The central difficulty: market data is continuous in value but discrete in evolution.
  Inter-arrival times have point masses at zero, at the fastest reaction time and at whole
  seconds; prices cluster at bid, ask and mid; only 8% of events are trades.
- Splitting BBO changes into 20 categorical classes (size only, ask up, bid down, zero
  elapsed time) fixed marginals but needs hand engineering per feature; "atom smoothing"
  (smooth the spike, then re-sculpt its mass) in a well-chosen representation scaled better.
- Evaluation: total variation distance per marginal after a 10,240-event real context,
  and a classifier that tries to tell a generated next event from a real one. Rollouts
  degrade with horizon (spreads widen); the model is not yet a realistic generator.

## Relevance to us

- The noise traders in [exchange-core](../../../repos/exchange-core.md) are our synthetic
  market; the post's checks (point masses in inter-arrival time, clustering at
  tick-improvement prices, trade share of events) are cheap realism metrics we can compute
  with [market-data](../../../repos/market-data.md) SQL on recorded versus simulated data.
- Real-data anchoring is already planned as price-anchor ([roadmap](../../../roadmap.md)).
- **Action:** in `specs`, add a DuckDB query over the `bbo` and `trades` tables that
  reports the trade share of events and a histogram of BBO inter-arrival times (zero,
  under 1 ms, 1 to 10 ms, and so on), then run it once on a live Hyperliquid recording and
  once on an `hl-sim` recording and record both results.

Tags: `simulation`, `market-data`, `ml`
