# order-book

Price-time priority limit order book with matching, for one instrument. Pure and
mutable: no I/O, no margin or account checks.

| | |
| --- | --- |
| Repository | `winterchill-trading/order-book` |
| opam package | `order-book` |
| Library | `order-book` (module `Order_book`) |
| Binaries | none |
| Status | done |

## Key modules

- `Order_book` (`lib/order_book.mli`): submit GTC/IOC/ALO limit orders and
  slippage-bounded market orders, cancel, L2 snapshot, iteration, invariant check.
  `Resting_order`, `Status`, `Cancel_reason`, `Result` (fills in execution order, filled
  and remaining size).
- `Order_book.Fill` (`lib/fill.mli`): taker/maker match with trade id, price, size, both
  order ids, accounts and client ids.

Each side is a `Map` from price to a FIFO `Queue`. Fills execute at the maker's price.
Self-trade prevention stops matching at the taker's own resting order and cancels the
taker's remainder. The matching loop uses OxCaml stack allocation (`local_`, `exclave_`,
`global_` fields) for per-order temporaries.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`.
- Used by: `exchange-core-engine`; `hl-sim`, `binance-sim`, `bybit-sim` list it
  directly too.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Known gaps

- One instrument per book; the engine keeps one book per instrument.
- Trade ids come from a caller-supplied `next_tid`; the book never reads a clock.
- Only "cancel taker remainder" self-trade prevention.
