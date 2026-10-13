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
| `Fee_schedule`, `Instrument` | Fees in bps; size decimals, tick, significant-figure limit, max leverage, validation and rounding |

`Exchange_core_engine` (`engine/*.mli`):

| Module | Purpose |
| --- | --- |
| `Position`, `Account_state`, `Execution` | Per-instrument position, per-account state, one account's side of a fill |
| `Clearinghouse` | Settlement, fees, margin, liquidation, funding, `Account_view` |
| `Event` | Event log entries; `Event.Numbered` adds a sequence number from 1 |
| `Target` | The order a modify replaces, by order id or client order id |
| `Exchange` | Books (self-trade policy from `create ?self_trade`, an `Order_book.Stp.t`, default `Cancel_taker`), clearinghouse, marks, clock, event log; `place`, `cancel`, `modify`, `set_mark`, `step`, `drain_events`, `drain_numbered_events`, `record_inputs`, `apply` |
| `Input` | Every mutating request as a value, with a `bin_prot` encoding |
| `Journal` | Writes inputs to a file (magic `EXJRNL01`, one `bin_prot` value per input; `EXJRNL02` and a `bin_prot` `Journal.Header.t` first when the self-trade policy is not the default), loads and replays them into a fresh exchange |
| `Book_replay` | Rebuilds order books from numbered events alone, with gap detection |
| `Market_sim` | Seeded random-walk reference prices, marks and noise traders; optional inside-the-spread orders; `Config.randomize ~seed`; `set_reference` / `clear_reference` pin a symbol to an external price with an optional mean-reversion half-life, `set_noise_traders` sets a per-symbol trader count; both act through journaled exchange calls |
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

## Known gaps

- Cross margin and one-way positions only.
- Liquidation closes positions at mark with no liquidator or backstop; losses past the
  balance leave a negative balance.
- Funding uses a configured per-instrument rate (default 0.00125% hourly), not a premium
  index.
- `modify` is cancel and replace: the order loses priority, and a rejected replacement
  leaves the original cancelled.
- Market prices come from a random walk; anchoring to real venues is planned
  (`price-anchor`).
