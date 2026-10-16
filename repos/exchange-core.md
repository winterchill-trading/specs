# exchange-core

Venue-neutral building blocks: trading primitives and views (package `exchange-core`) and
a deterministic perpetuals exchange engine (package `exchange-core-engine`). Nothing here
knows a venue's wire format; venue simulators are adapters over the engine.

| | |
| --- | --- |
| Repository | `winterchill-trading/exchange-core` |
| opam packages | `exchange-core`, `exchange-core-engine` |
| Libraries | `exchange-core` (`Exchange_core`, `lib/`), `exchange-core-engine` (`Exchange_core_engine`, `engine/`) |
| Binaries | none |
| Status | done |

The repository holds two packages because `order-book` sits between them:
`fixed-decimal -> exchange-core -> order-book -> exchange-core-engine`.

## Key modules

`Exchange_core` (`lib/*.mli`):

| Module | Purpose |
| --- | --- |
| `Price`, `Size`, `Usd` | Distinct `Fixed_decimal.Make ()` types, 8 decimals |
| `Side`, `Tif`, `Order_type` | `Buy`/`Sell`; `Gtc`/`Ioc`/`Alo`; `Limit of Tif.t` or `Market { slippage_bps }` |
| `Symbol`, `Account`, `Client_order_id` | Opaque strings |
| `Order_id`, `Trade_id` | Exchange-assigned ids (`int64`, `int`) |
| `Order_request`, `Order_status`, `Reject_reason`, `Cancel_status` | Requests and outcomes |
| `Open_order`, `L2`, `Position_view`, `Account_view` | Views reported to clients |
| `Fee_schedule`, `Instrument` | Fees in bps; size decimals, tick, significant-figure limit, max leverage, optional margin tiers, validation and rounding |
| `Margin_tier` | Notional tiers of maximum leverage; continuous tiered maintenance margin |
| `Trigger` | Trigger price and kind (take-profit or stop-loss) of a trigger order |

`Exchange_core_engine` (`engine/*.mli`):

| Module | Purpose |
| --- | --- |
| `Position`, `Account_state`, `Execution` | Per-instrument position, per-account state, one account's side of a fill |
| `Clearinghouse` | Settlement, fees, margin, liquidation, funding, `Account_view` |
| `Event` | Event log entries; `Event.Numbered` adds a sequence number from 1 |
| `Target` | The order a modify replaces, by order id or client order id |
| `Trigger_order`, `Trigger_event` | Trigger orders waiting for the mark and their log (placed, triggered, cancelled), ordered against `Event` by `before_seq` |
| `Price_index`, `Premium_funding` | Oracle-based mark median with its moving averages; impact prices, premium and the clamped, capped funding rate |
| `Book_liquidation` | Liquidation through the book with slices, cooldown and a backstop liquidator; its steps' log |
| `Exchange` | Books (self-trade policy from `create ?self_trade`, an `Order_book.Stp.t`, default `Cancel_taker`), clearinghouse, marks, clock, event log; `place`, `place_trigger`, `cancel`, `modify`, `set_mark`, `set_oracle`, `step`, `drain_events`, `drain_numbered_events`, `drain_trigger_events`, `drain_liquidation_events`, `record_inputs`, `apply`; `create ?premium_funding ?book_liquidation`; guards: `set_collar`, `collar`, `collar_reference`, `set_halt_rule`, `set_session_reference`, `reopen`, `halt_status`, `drain_guard_events`, `guard_stats` |
| `Input` | Every mutating request as a value, with a `bin_prot` encoding; `Set_collar`, `Set_halt_rule`, `Set_session_reference` and `Reopen` appended (2026-10-16), so journals carry the guard settings |
| `Journal` | Writes inputs to a file (magic `EXJRNL01`, one `bin_prot` value per input; `EXJRNL02` and a `bin_prot` `Journal.Header.t` first when the self-trade policy is not the default; `EXJRNL03` and a header with the book liquidation settings when there are some), loads and replays them into a fresh exchange |
| `Book_replay` | Rebuilds order books from numbered events alone, with gap detection |
| `Market_sim` | Seeded random-walk reference prices, marks (or oracle prices with `Config.oracle_interval`) and noise traders; optional inside-the-spread orders; `Config.randomize ~seed`; `set_reference` / `clear_reference` pin a symbol to an external price with an optional mean-reversion half-life, `set_noise_traders` sets a per-symbol trader count; both act through journaled exchange calls |
| `Price_collar` | Per-symbol band around a reference price (`Last_trade`, `Mid` or `Mark`, the mark being what `Market_sim.set_reference` feeds) in bps or ticks, bounds rounded inward to valid prices; action `Reject` or `Reprice` |
| `Halt_rule` | Circuit-breaker levels (move in bps from a session reference, duration or until reopened), `Market_wide` or `Per_symbol`, `Automatic` reopening or `On_request` (the hook for a front end's reopening auction); default 7% and 13% for 15 minutes, 20% until reopened |
| `Guard_event` | Audit log of collar rejections and re-pricings, halt rejections, halts, pending reopens and reopens, ordered against `Event` by `before_seq`; `Stats` counters |
| `Stepped` | Deterministic stepped harness: exchange and simulation advanced one step (100 ms by default) at a time, a strategy reacting to each step's events, `check_replay` |

Types carry no JSON codecs: encodings live in the `*-protocol` repositories.

## Dependencies

- `exchange-core` depends on `fixed-decimal`.
- `exchange-core-engine` depends on `fixed-decimal`, `exchange-core`, `order-book`.
- Used by (`exchange-core`): `order-book`, every `*-protocol`, every `*-sim`,
  `market-data`, `mm-core`, `binance-client`, `bybit-client`, `hl-mm`, `market-maker`.
- Used by (`exchange-core-engine`): `hl-sim`, `binance-sim`, `bybit-sim`; test-only in
  `binance-client` and `bybit-client`.

## CI pin order

`fixed-decimal`, `exchange-core` (`.`), `order-book`. CI installs `exchange-core.opam`
first, then builds and tests with `--only-packages exchange-core-engine`, because
`order-book` must find an installed `exchange-core`.

## Design

See [design/simulators.md](../design/simulators.md): determinism (caller-advanced `int`
nanosecond clock, sequential ids), validation order, cross margin, fees, mark price,
liquidation, funding, modify, market simulation.

## Journals, replay and testing

The engine is deterministic, so a journal of `Input.t` values applied in order to a fresh
exchange with the same `Config.t` reproduces the run, event log included. The tests
journal a seeded run, replay it and diff the event streams; rebuild books from drained
numbered events with `Book_replay` and compare L2 after every tick; print a text trace of
book, margin and accounts per step; and run a random-flow `Base_quickcheck` property with
steps and mark moves mixed in, checking that positions net to zero once liquidated sizes
are counted and that order and trade ids are unique. `Stepped` and `Journal` are the
offline strategy harness and the base of the planned price anchor.

## Price collar and halts

Both are off until set through recorded calls, so an exchange without them behaves,
journals and replays exactly as before (allocation pins unchanged), and an exchange with
them replays its guard events from the journal. The collar is checked on the aggressor's
side of orders that would trade on entry: a marketable limit order beyond the band is
rejected (`Rejected Invalid_price`) or re-priced to the bound; a market order's protection
price is clamped to the bound. Post-only and liquidation orders are exempt. While a symbol
is halted, orders that would trade are rejected (`Rejected (Unsupported "trading
halted")`); passive orders rest and cancels work. No new `Event.t` or `Reject_reason.t`
constructor was added, so front ends that match every constructor build unchanged; the
details are in the guard log. A `Base_quickcheck` property checks that no fill happens
beyond the collar on the aggressor's side; the bench measures 8 words and about 0.1 us per
order with a collar and the default halt rule set.

## Known gaps

- Cross margin and one-way positions only.
- By default liquidation closes positions at mark with no liquidator or backstop; losses
  past the balance leave a negative balance. `create ?book_liquidation` liquidates
  through the book instead; backstop takeovers there produce no fills.
- Without an oracle price, funding uses a configured per-instrument rate (default
  0.00125% hourly); with one (`set_oracle`), Hyperliquid's premium formula.
- Trigger orders have no parent-child (TP/SL grouping) relations.
- `modify` is cancel and replace: the order loses priority, and a rejected replacement
  leaves the original cancelled.
- Market prices come from a random walk unless a front end anchors a symbol to a
  reference (`Market_sim.set_reference`, driven by `price-anchor`).
- The collar does not bust or flag trades after the fact (no aberrant-trade band on
  executions), and resting orders left outside the band by a moving reference can still
  fill, at a price better than the band for the aggressor.
- Halts are venue-neutral; the TradFi simulators keep their own LULD bands and auctions
  and do not use `Halt_rule` yet.
