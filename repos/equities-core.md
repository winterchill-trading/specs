# equities-core

Shared semantics for the traditional-finance venue simulators: US equities trading
calendars, tick and lot rules, symbology, auctions, order attributes, volatility halts
and fee schedules. Pure OCaml, no I/O; matching stays in `exchange-core-engine`.

| | |
| --- | --- |
| Repository | `winterchill-trading/equities-core` |
| opam package | `equities-core` |
| Library | `equities-core` (module `Equities_core`) |
| Binaries | none |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Session` | New York and Chicago time without a tz database; US equities day (pre-market, core 09:30-16:00, post-market, early closes), NYSE 2026 holidays; CME Globex week and trade dates |
| `Tick_size` | Equity ticks ($0.01, $0.0001 below $1), Cboe option tick classes, CME products ES, NQ, CL, GC with multipliers and tick values |
| `Lot` | Round, odd and mixed lots, price-tiered round lots, CME contract units and notional |
| `Symbol` | Equity tickers with suffixes, test symbols, futures codes and expiry rules, OCC OSI option symbols |
| `Auction` | Call auction clearing price (max volume, min imbalance, nearest reference), imbalance, on-open and on-close participation, allocation |
| `Order_types` | TIF (Day, IOC, FOK, GTC, OPG, CLO), display (visible, hidden, reserve), ISO, post-only, minimum quantity, self-trade prevention, short sale and Rule 201; validation and mapping to `Exchange_core.Order_request` |
| `Halts` | LULD bands and the limit state and pause machine, market-wide circuit breakers |
| `Fees` | Per-share maker and taker schedules with rebates, per-contract futures fees |

It reuses `Exchange_core.Price`, `Side`, `Usd`, `Symbol` and `Order_request`. The
repository's `docs/` hold the protocol summaries the simulators implement: NYSE Pillar
Gateway and XDP Integrated Feed, Cboe BOE v2 and Multicast PITCH, CME iLink 3 and MDP 3.0,
each ending with the minimal message set a simulator needs.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`.
- Used by: `nyse-sim`, `cboe-sim`, `cme-sim`.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Known gaps

- Calendars cover 2026 NYSE holidays only, and no CME holiday schedule.
- Auctions have no collars, freeze periods, imbalance-offset orders or extensions.
- Order mapping to the engine covers visible Day, GTC, IOC and post-only; pegs, stops,
  routing, and hidden or reserve matching are left to each simulator.
- Fee schedules are illustrative, not the venues' current published prices.
