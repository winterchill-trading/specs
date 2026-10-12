# Finding Signal in the Noise

- Source: <https://signalsandthreads.com/finding-signal-in-the-noise/>
- Published: 2025-03-12
- Kind: Signals and Threads episode 22

## Summary

- The guest has spent about ten years as a trader and researcher and now leads much of the
  machine learning work in the research group; the path ran from pre-med and competition
  maths through an internship.
- A first-year trader's job blends software engineering (desk tools in OCaml, VBA,
  Bash, SQL), research and live trading, including answering broker calls; the firm
  uses one trader title for all three.
- Since about 2013 the firm also trades bilaterally with onboarded clients. Knowing that
  a large order is a benign pension rebalance, not informed flow, lets it quote tighter
  than an anonymous exchange market maker would.
- Research has four stages. The first is exploration with fast interactive tools (for
  example, looking at a client's portfolio and 13F filings to guess its flow).
- The second is data collection: dates, sizes, times and returns around large trades,
  with corporate actions, splits and ticker changes handled. Building a small dataset by
  hand first builds intuition for which checks matter.
- The third is modelling: choosing features and responders (the firm's term for
  dependent variables), and starting as simple as a linear regression on small data.
- The fourth is productionization: expressing a prediction as trades and executing
  reliably, where the battle is only half won once a model exists.
- Two research styles: simulate changes inside the production system, which ties
  closely to reality but is slow and data-heavy, or study a simplified offline dataset
  and port the result. Exploratory, low-conviction work favours flexibility; mature
  systems favour robust experiments, at the cost of learning the production stack.
- Short iteration time is essential because most research ideas are bad.
- Ten years ago a researcher understood every stage personally with crude tools; today a
  week's study takes minutes, but with a complexity burden and blind trust in vetted data.
- Data tooling provides point-in-time universes (all US-listed stocks in 2005, avoiding
  survivorship bias), corporate actions, market cap, volatility and internal historical
  fair values joined by symbol and time. The guest still urges "trust but verify".
- Visualization tools show market events below one second, beyond what a Bloomberg
  terminal offers, and make arbitrary historical or live plots.
- A shared modelling library offers tree models, deep nets and in-house regressions with
  loss tweaks over a standard dataset format.
- Python notebooks help sharing but evaluate cells in arbitrary order. Researchers want
  to just add a column while production engineers want robustness, and people who
  straddle both roles reduce the friction.
- Reproducibility matters within research too: without it you cannot tell whether one
  change or six (mutated data sources, other code) moved a result.
- Low-data regimes need discipline in the model (priors, few hypotheses, reuse all
  data). High-data deep learning needs discipline in the data (strict holdout,
  train/eval splits, no repeated hypotheses across teams that leak the test set).
- Simple models allow interventional interpretability: during a one-off event such as the
  pandemic you can adjust coefficients by hand; complex models make that hard.
- Financial ML is hard: roughly one useful unit of data per hundred, with no way to tell
  which. Markets are anti-inductive (traded-on patterns disappear), regimes change
  (crises seem to come yearly) and volume can jump tenfold on busy days.
- The firm records tens of terabytes of market data daily and decisions span 10 ns to
  human timescales. At the short end the model is chosen to fit the hardware (CPU, FPGA,
  GPU) and its latency and throughput limits, not the other way round.
- The host is not fully convinced by the Bitter Lesson for trading: data-poor domains
  still benefit from priors and transfer from other markets.
- The GPU fleet is in the mid thousands of high-end cards. Future work: transfer
  learning to data-scarce asset classes, multimodal inputs (text, images, market data)
  and internal AI assistants for engineers.

## Relevance to us

- [market-data](../../../repos/market-data.md) and
  [market-recorder](../../../repos/market-recorder.md) are our research data layer, and
  [mm-core](../../../repos/mm-core.md) is our only model. The client-flow and
  big-model points do not apply.
- **Data platform:** cleaned data still needs independent checks, and our raw files do
  not mark reconnect gaps. **Action:** add a SQL view next to the generated
  `CREATE VIEW`s that reports, per venue, symbol and day, the minutes with zero trades or
  BBO updates, tested on a fixture day with one deliberate gap, in
  [market-data](../../../repos/market-data.md).
- **Data platform:** a point-in-time universe avoids survivorship bias, but we record
  only configured symbols and keep no record of which instruments existed or what their
  tick and lot sizes were each day. **Action:** have `day-close` write an `instruments`
  table per day (venue, symbol, tick, lot, first and last `recv_ts` seen), in
  [market-data](../../../repos/market-data.md).
- **Testing and simulation:** research done in one toolset and production in another
  causes porting pain, and we can avoid it because our strategy is pure OCaml. **Action:**
  add an expect test that drives `Mm_core.Strategy` from a `Market_data.Replay_feed` over
  a small fixture event log and prints the resulting quotes, in
  [mm-core](../../../repos/mm-core.md).
- **Market making and trading systems:** simple models let you adjust parameters by hand
  when a regime changes, but our parameters are fixed for a whole run. **Action:** add a
  `-params FILE` sexp flag and re-read it on SIGHUP, applying it only after
  `Params.validate` passes, in [market-maker](../../../repos/market-maker.md).

Tags: `research-tooling`, `data-platform`, `ml`, `market-data`, `trading`
