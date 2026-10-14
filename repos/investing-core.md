# investing-core

OCaml retail brokerage as pure values: instruments and listings, end-of-day prices, market
orders for fractional shares, positions with average cost basis, and the double-entry ledger
entries for the cash side of each order. It has no storage and no network code, and it is not
a matching engine; a service keeps the values in its own store and reaches a broker or data
vendor through the module types `Broker.S` and `Market_data.S`. A simulated market-data source
and a simulated broker make the whole flow runnable in tests and demos.

| | |
| --- | --- |
| Repository | `winterchill-trading/investing-core` |
| opam package | `investing-core` |
| Library | `investing-core` (module `Investing_core`) |
| Status | done: library, quickstart example and property tests are in place; CI configured |

## Key modules

| Module | Purpose |
| --- | --- |
| `Symbol`, `Isin` | Ticker symbols; ISINs with their Luhn check digit |
| `Listing`, `Instrument`, `Catalog` | Exchange (MIC), currency and status; the security; search by text and kind |
| `Price`, `Quantity` | Positive prices to 8 places; share quantities to 6 places, never negative; products rounded in a named direction |
| `Close`, `Price_history` | End-of-day closes with an origin preference (feed over seed over simulated); quotes with previous close, windows and 52-week range |
| `Staleness` | How old a close may be: stale after 4 days and refused after 10 by default |
| `Market_data` | `S` (a source of closes), `Simulated` (deterministic random walk), `Fixed` (serves given closes) |
| `Order_request`, `Order_limits`, `Placement` | Buy by amount or quantity, sell by quantity, amount or all; minimum and maximum order value; sizing and typed refusals |
| `Order_id`, `Side`, `Order` | Order identifiers and side; the state machine `pending -> filled, rejected or cancelled` with submission tracking |
| `Position`, `Portfolio` | Holdings with reservations, average cost basis, realised and unrealised results; a valued summary in one currency |
| `Booking` | Ledger entries for holds, settlement (with over-capture), release and proceeds |
| `Broker`, `Sim_broker` | The brokerage port (`Broker.S`) and an in-memory simulated broker with spread, delay and manual decisions |
| `Recurring_buy` | Due dates, deterministic order ids and failure pausing for scheduled buys |

Rules the library enforces:

- Cash becomes shares rounded down to a millionth; a buy's cost rounds up and a sale's proceeds
  round down to the currency's minor unit. Quantities with more than six decimals are refused.
- A buy holds its amount or estimated cost; a sell reserves shares and holds no cash. Only
  `Sell_all` is exempt from the minimum order value.
- A broker fill is always for the whole quantity. A sent order with no answer cannot be
  cancelled here.
- A sale removes `basis * sold / held` (half-even) from the cost basis, or all of it when the
  position empties.
- Booking idempotency keys are `order:<id>:hold`, `:settlement`, `:release` and `:proceeds`.

## Tests

- `dune test`: expect tests per module, `test_flows.ml` for whole flows, and the quickstart
  output checked against `examples/quickstart.expected`.
- Quickcheck properties: shares bought for an amount never cost more than the amount; a hold
  covers the estimated cost; cost basis is conserved over random buys and sells; final order
  states never change and nothing is cancelled in transit; a simulated range query equals
  single-day closes; recurring dates from a range agree with dates by index.
- `test/test_stable.ml` pins the Stable `bin_prot` digests; a change means a new `Stable.V2`.

## Dependencies

- Depends on: [fixed-decimal](fixed-decimal.md), [money](money.md) and [ledger](ledger.md).
  External: `core`, `async_kernel` (time source), `zarith`, `ppx_jane`, and
  `expect_test_helpers_core` for tests. It needs the OxCaml compiler.
- Used by: none yet.

## CI pin order

`fixed-decimal`, then `money`, then `ledger`. CI pins each from GitHub through the `ox-setup`
action, then runs `dune build`, `dune test` and the quickstart example, and the shared
`obj-magic` workflow.

## Known gaps

- Cash legs are booked in the instrument's currency; an account in another currency must
  convert first. Conversion inside the order flow belongs with an FX library.
- Partial fills, limit orders and order expiry are not modelled; orders are market orders
  filled whole.
- Fees (commission, FX markup) are not charged or added to the cost basis.
- Corporate actions and tax-lot methods other than average cost are not modelled.
- Portfolio history (value per day) is not provided; only current positions are valued.
- A real market-data fetcher and broker adapter implement `Market_data.S` and `Broker.S`
  outside this library.
- Nothing has been released yet.
