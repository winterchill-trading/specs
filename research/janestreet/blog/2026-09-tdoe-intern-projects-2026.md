# What the TDOE interns have wrought, 2026 edition

- Source: <https://blog.janestreet.com/tdoe-intern-projects-2026/>
- Published: 2026-09-30
- Kind: blog post

## Summary

- Trading Desk Operations Engineers work beside desks on outages, automation in OCaml and
  dashboards with traders, balancing resilience work against urgent trading needs.
  Interns arrive knowing neither OCaml nor trading, complete three desk projects, then
  rotate two weeks through teams such as market data, reference data and order engines.
- These projects were chosen because they could be described publicly; normally such work
  touches sensitive systems.
- Voice trades: brokers and traders agree trades by phone or chat ("shows"); the broker
  sends a receipt, the trade later appears anonymously on the public tape, and an official
  confirmation arrives at end of day. Errors in the internal booking (10,000 versus 100,000
  shares) matter before that confirmation.
- An intern built a checker that matches internal phone-trade records to anonymous public
  prints by time, size and price and flags discrepancies early. A hard case is the split
  print: a half-cent agreed price in a one-cent-tick product appears as two prints whose
  average matches. Working closely with traders kept the tool aimed at valuable cases.
- Exchange specifications: the same field name can mean different things per venue. A
  "primary peg" order on MEMX rests at the national best bid (for a buy), while on IEX it
  rests one tick less aggressive with discretion to trade at the bid. The intern read both
  rulebooks, encoded the attribute per venue in OCaml and FIX without collapsing the two,
  and tested it, all in two weeks.
- ETF holidays: creating or redeeming an ETF depends on whether its constituents' markets
  are open. One emerging-markets ETF has 1,191 constituents on five continents, each with
  its own holiday calendar, and issuers have their own rules.
- That tool, built in the firm's typed spreadsheet-like platform (Webs), shows day by day
  whether a fund is open for placement, trading and settlement, with drill-down into the
  rules that applied; rules stay end-user editable.

## Relevance to us

- **Market making and trading systems:** order flags that look alike across venues can
  differ in meaning. **Action:** in `specs`, add a table to the simulators design page
  listing each [exchange-core](../../../repos/exchange-core.md) `Tif` value (`Gtc`, `Ioc`,
  `Alo`) and market-order slippage handling with its Hyperliquid, Binance and Bybit wire
  value and a one-line semantic note per venue, linking each venue's API docs.
- **Testing and simulation:** the simulators implement one shared semantics for all three
  venues, so venue-specific differences hide there. **Action:** for each row of that table
  where venues differ, add an expect test in the matching simulator
  ([hl-sim](../../../repos/hl-sim.md), [binance-sim](../../../repos/binance-sim.md),
  [bybit-sim](../../../repos/bybit-sim.md)) that pins the venue's documented behavior,
  starting with a post-only order that would cross.
- **Data platform:** reconciling own fills against public trades by time, size and price
  is a cheap correctness check. **Action:** add a DuckDB query to `specs` that joins
  `market-maker` fills (once logged) to the recorded `trades` table on price, size and a
  time window, and lists own fills with no public print.

Tags: `trading`, `market-data`, `testing`, `hiring`
