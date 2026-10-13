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
Self-trade prevention is a per-book policy, `Order_book.Stp.t`, given to
`create ?stp`: `Cancel_taker` (default; matching stops and the taker's remainder is
cancelled), `Expire_maker` (the own resting order is removed and the taker keeps
matching, as on Hyperliquid) or `Cancel_both`. Removed own orders are returned in
`Result.expired_makers`, in the order reached. `exchange-core` takes the policy in
`Exchange.create ?self_trade`; `hl-sim` uses `Expire_maker`. The matching loop uses
OxCaml stack allocation (`local_`, `exclave_`, `global_` fields) for per-order
temporaries.

The best level of each side is cached, so `best_bid`, `best_ask` and `mid` do not go
through `Map.max_elt`; `best_bid_or_null`, `best_ask_or_null` and `mid_or_null` return
`Price.t or_null` and allocate nothing. Each level keeps its orders in a linked list and
the id index points at the node, so cancel is O(1): behind 1000 orders it went from
24.8 us and about 2100 words to 0.26 us and 40 words.

## Tests

Expect tests, `Base_quickcheck` properties (books never cross, filled sizes agree,
cancelling everything empties the book), a bisimulation property against
`test/naive_book.ml` (a sorted-list reference matcher; fills, status, remainder, cancel
result and full L2 must agree after every operation), a byte-string fuzz property,
edge cases pinned with `~examples`, and `test/test_alloc.ml`, which prints minor words
per operation.

## Benchmarks

`bench/main.ml` runs core_bench on a 1000-level book (500 bids, 500 asks, one maker per
level). Apple M3 Max, after the best-level cache, best of two `-quota 3` runs:

| Case | dev | release | release, `-O3` |
| --- | ---: | ---: | ---: |
| submit + cancel, existing level | 223 ns | 195 ns | 158 ns |
| submit + cancel, new level | 329 ns | 321 ns | 288 ns |
| match 1 fill (IOC) | 74 ns, 27 w | 66 ns, 27 w | 37 ns, 22 w |
| sweep 10 levels, then re-add | 3.35 us | 3.29 us | 2.74 us |
| `l2 ~n_levels:10` | 209 ns | 208 ns | 198 ns |
| `best_bid` | 3.6 ns, 5 w | 3.4 ns, 5 w | 2.5 ns, 3 w |

`-O3` (via `OCAMLPARAM='_,O3=1'`, so it covers the sibling libraries built from source)
roughly halves a single fill, because `Price`, `Size` and `Account` comparisons get
inlined; `-O3` on this repository alone only took it from 66 ns to 62 ns. The best-level
cache cut `best_bid` from 5 to 2 minor words, `mid` from 12 to 2 and a single-fill match
from 31 to 26. The README lists hot-path fields that would gain from `or_null` or
unboxing; none is changed yet.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`.
- Used by: `exchange-core-engine`; `hl-sim`, `binance-sim`, `bybit-sim` list it
  directly too.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Known gaps

- One instrument per book; the engine keeps one book per instrument.
- Trade ids come from a caller-supplied `next_tid`; the book never reads a clock.
- `mid_or_null` carries no `[@@zero_alloc]` annotation because the checker fails through
  `Price.of_units` until `fixed-decimal` annotates its own functions.
