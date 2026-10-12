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

`Exchange_core_engine` (`engine/*.mli`): `Position`, `Account_state`, `Clearinghouse`
(settlement, fees, margin, liquidation, funding), `Execution`, `Event`, `Exchange`
(books, clearinghouse, marks, clock, event log; `place`, `cancel`, `modify`, `step`,
`drain_events`) and `Market_sim` (seeded random-walk reference prices and noise traders).

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
