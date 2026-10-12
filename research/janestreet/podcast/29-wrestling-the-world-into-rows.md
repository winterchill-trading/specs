# Wrestling the world into rows

- Source: <https://signalsandthreads.com/wrestling-the-world-into-rows/>
- Published: 2026-09-02
- Kind: Signals and Threads episode 29

## Summary

- The guest joined Jane Street about a decade ago after spending his three undergraduate summers
  trying academic research, tech and trading. He traded commodities, helped start the commodities
  desk-dev effort, and now helps lead the alternative data team.
- Markets are anti-inductive: unlike a physics result, a discovered pattern gets competed away, so
  research has to keep finding new effects and what is left looks increasingly like noise. Acting in
  the market also changes how others behave, in ways your training data never saw.
- The internship invests heavily in teaching: mock trading on a simulated exchange, one- to two-hour
  scenarios that distil a real market concept, and Figgie, a four-player card game about trading on
  private information. Low stakes make it easier to learn decision-making under uncertainty and
  market-making language.
- New traders learn next to a mentor: propose a change, hear what else should be weighed, repeat.
  Within months a newcomer can add value by becoming the firm's expert on one narrow thing, such as
  one ETF or how much a faster trading-system generation was actually gaining.
- Futures add layers of metadata risk. Spreads decompose into two legs with sign conventions that
  differ by product (crude versus S&P 500 spreads). Quoted prices are per unit while a contract
  delivers many units (1,000 barrels of crude). Sources quote in dollars or cents. A mix-up means
  trading 100 times the intended size.
- Risk systems that sit outside the strategy and cap its exposure are only as good as their contract
  metadata.
- On 2020-04-20 the expiring CME crude contract settled below zero: storage at Cushing was full and
  demand had collapsed. Order entry and models that assumed positive prices broke, and it was
  unclear whether other products should be modelled off the negative price.
- Trading mixes technology and maths with grotty real-world detail (storage at a delivery point,
  cattle delivered by weight), especially in commodities.
- Desk devs: Jane Street moved from central teams building core systems (trading, market data,
  bookings) to developers embedded on each desk. Commodities was an early case and now every desk
  has them.
- The desk's risk view lived in a VBA-driven Excel workbook that rebuilt sheets from positions on a
  button press. It was slow at critical moments, impossible to version-control (the guest wrote a
  firm-wide Excel grep tool), and full of forgotten one-off formulas. It was rebuilt as typed,
  tested software around a clear data model.
- The guest praises spreadsheets as the most widely used functional language (with lambdas and let
  bindings now), with data in front and logic behind, the reverse of code.
- The desk-dev role translates both ways: it turns trader requirements into data atoms and flows
  engineers can build on, and shows traders with high pain thresholds what better tools would make
  possible.
- Alt data is defined relative to Jane Street's history: exchange market data and instrument
  metadata are traditional; satellite images and even SEC filings count as alternative. Separate
  teams own market data, metadata and alt data.
- Before the team existed, each desk ingested vendor data ad hoc into NFS corners or some database,
  at perhaps 60% of possible quality. The team grew by making one hard dataset easy, which revealed
  effects nobody could see before, creating induced demand. The first data engineer was hired in
  2023; there are now more than twenty.
- The team has three parts: data strategy (internal needs, vendor catalogs such as Neudata,
  buyer-seller speed-dating conferences, approaching firms whose exhaust data isn't for sale yet),
  data infrastructure (ingestion, transformation and monitoring tools) and data engineering (the
  product is a correct dataset).
- Data buyers include hedge funds, multi-strategy firms, banks and private equity. Sellers range
  from large aggregators (Bloomberg, S&P, LSEG) to specialists and firms selling exhaust data.
  Unlike ad tech, trading wants aggregates and never individual identities.
- Even company financials need careful modelling: what counts as a company (dual-listed structures
  that are economically one firm), whether a figure applies to an issuer, a share class or a listing
  (ISIN, SEDOL), and restatements or fiscal-calendar changes that break comparability.
- Satellite parking-lot counts are noisy and indirect (online sales, cities, visits rather than
  spend). Card-transaction panels are closer to the truth but biased: a panel's demographics differ
  from the population, and cardholders join and leave, so more spend may just mean a bigger panel.
- Vendors revise history: missing days, recomputed columns, merchants re-mapped to different brands.
  Backtesting on the corrected data simulates a time machine rather than what a subscriber would
  have known.
- Jane Street therefore stores every vendor delivery with its own receive time, so any later
  transformation can reconstruct what was knowable when. The host draws the parallel to market data,
  where the firm trusts its own capture timestamps more than exchange timestamps.
- AI raises the value of clean data: stronger models exploit any future leak in data that should be
  point-in-time, and outliers matter more for some training procedures. LLMs make text extraction
  practical but add look-ahead risk, because a model may already know what later happened to a
  company.
- LLMs speed data engineering for people who can judge the output, but make it easier than ever to
  produce bad code and to think a problem is solved without understanding it.
- Tooling: dbt for composable, tested, code-reviewed SQL transformations (instead of 300-line
  Postgres views), Trino as the query engine, Python dataframe tools, and the in-house Superstore
  warehouse.
- On-premises hardware is cheaper than cloud warehouse pricing (per bytes scanned or compute slots),
  and cloud pricing would push teams to shape their research around cost. Jane Street already runs
  data centers for latency, multicast and FPGAs.
- Hiring: curiosity, a careful investigative process and real software skill. Data-investigation
  interviews hand candidates an unfamiliar dataset and watch how they test their assumptions.
  Candidates often come from science, social science or being the data person at a startup. Intern
  hiring starts with a multi-year pipeline.

## Relevance to us

- Our raw-first design already follows the receive-time rule: every raw line and event carries our
  own `recv_ts` next to venue timestamps; see [market-data](../../../repos/market-data.md) and
  [market-recorder](../../../repos/market-recorder.md).
- Negative values that break assumptions: perpetual prices stay positive, but funding rates go
  negative, and [exchange-core](../../../repos/exchange-core.md) tests already charge a negative
  rate, so no change is needed there.
- **Data platform:** Contract multipliers make raw prices incomparable across venues. Crypto has the
  same trap: `1000PEPEUSDT` on Binance and Bybit and `kPEPE` on Hyperliquid quote per 1,000 tokens.
  **Action:** add a per-instrument `units_per_contract` table to
  [market-data](../../../repos/market-data.md) (1 by default, 1000 for those three) exposed as a
  DuckDB view, with a ppx_expect test over a small BBO fixture showing per-token mids from the three
  venues agree within 1%.
- **Data platform:** Rebuilt history must say what produced it, or a backtest can't tell old outputs
  from corrected ones. **Action:** make `day-close` in [market-data](../../../repos/market-data.md)
  write a `<date>.manifest.sexp` beside each table recording the producing binary's version, the
  source `norm/` files with sizes, and the run time, so a re-run after a normalizer fix is visible.
- **Research tooling:** Tested, reviewable transformations (dbt style) catch bad data at each stage.
  **Action:** add a `market-data check -dir D -date YYYY-MM-DD` command to
  [market-data](../../../repos/market-data.md) that runs a fixed list of DuckDB assertions (no
  crossed BBO, positive sizes, `recv_ts` non-decreasing within a file, no minute without trades on a
  liquid symbol) and exits non-zero on failure, so the day-close CronJob can run it next.
- **Market making and trading systems:** Risk limits that sit outside the strategy depend on correct
  contract units. **Action:** add an expect test in [mm-core](../../../repos/mm-core.md) showing how
  `Params.for_instrument` and the `max_position` check behave on a `1000PEPEUSDT`-style instrument,
  documenting whether limits are counted in contracts or tokens.

Tags: `market-data`, `data-platform`, `trading`, `risk`, `research-tooling`
