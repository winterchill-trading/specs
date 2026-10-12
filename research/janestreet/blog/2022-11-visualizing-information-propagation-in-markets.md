# Visualizing information propagation in markets

- Source: <https://blog.janestreet.com/visualizing-information-propagation-in-markets-index/>
- Published: 2022-11-23
- Kind: blog post

## Summary

- The Dojima rice market in Osaka (around 1716) is described as the first organized futures
  exchange; futures let farmers and consumers hedge, and price news travelled only as fast
  as merchants could carry it.
- An 18th-century story tells of a merchant who relayed Dojima prices to another town with a
  runner on a mountain pass signalling price changes by arm angle, read through a telescope,
  and profited daily from knowing prices first.
- Today the limit is the speed of light in fiber; equity index futures (S&P 500 in Chicago,
  FTSE 100 near London, Nikkei 225 in Tokyo, HSCEI in Hong Kong, SPI 200 in Sydney, Euro
  Stoxx 50 in Frankfurt) are distinct baskets whose prices still move together.
- The author defines a price move as a change of more than 0.01% within 5 ms, and pairs a
  move in one future with a move in another that follows right after it.
- Data from a Federal Reserve announcement, centred on Chicago, is rendered on a globe at
  1/30 speed with rings expanding at the speed of light and half of it; most correlated
  moves land between the two rings.
- Keeping related prices consistent across venues is presented as part of Jane Street's role
  in markets.

## Relevance to us

- **Data platform:** our recorder captures the same instruments on Binance, Bybit and
  Hyperliquid with a receive timestamp, which is enough to measure which venue leads.
  **Action:** add a DuckDB query to [market-data](../../../repos/market-data.md)'s views
  that finds mid moves above 1 bp within 5 ms on one venue and reports the delay to the
  next same-direction move on the other two.
- **Market making and trading systems:** a lead-lag table tells the quoter which venue's
  price to trust when they disagree. **Action:** once the query exists, record the measured
  median lag per venue pair in the `mm-core` design notes in `specs` before adding any
  cross-venue fair-value input to [mm-core](../../../repos/mm-core.md).
- **Data platform:** cross-region comparisons of `recv_ts` are only meaningful with
  synchronized clocks, and the [roadmap](../../../roadmap.md) plans collectors in two
  regions. **Action:** expose the host clock offset (from chrony or similar) as a metric in
  [market-recorder](../../../repos/market-recorder.md)'s `/metrics`.

Tags: `market-data`, `latency`, `clocks`, `trading`, `research-tooling`
