# fx-core

OCaml foreign exchange pricing the way a retail or business bank does it: a table of reference
rates per currency, date and origin, cross rates through a pivot currency, staleness and
maximum-age rules, spreads in basis points with per-tier caps, single-use quotes with a short
time to live, card conversion re-pricing and estimates in a base currency. An executed quote is
booked as balanced [ledger](ledger.md) entries through [payments-core](payments-core.md)'s
`Swap`. Rates are exact rationals and amounts are integer minor units; each rule rounds once, in
a stated direction, so rounding never favours the customer. The library is pure and never
persists anything, and it ships no HTTP rate fetcher.

| | |
| --- | --- |
| Repository | `winterchill-trading/fx-core` |
| opam package | `fx-core` |
| Library | `fx-core` (module `Fx_core`) |
| Binary | `fx-core` (`rates`, `quote`, `bundle`) |
| Status | done: library, CLI, quickstart example and property tests are in place; nothing released yet |

## Key modules

| Module | Purpose |
| --- | --- |
| `Ratio` | Exact non-negative rationals with rounding to significant digits and a stable text form |
| `Origin`, `Observation`, `Basis` | A reference rate per pivot unit, date and origin (live or bundled), and the basis a price shows |
| `Rate_table` | As-of lookup (live before bundled), history, cross rates through the pivot |
| `Freshness` | Stale and maximum-age rules, with an offline policy |
| `Spread` | Spread in basis points (at most 1000) with caps and a per-tier `Schedule` |
| `Pricing` | Customer rate rounded down, sell-fixed floor, buy-fixed ceiling, fee included in the sold amount |
| `Quote`, `Quote_book` | Firm 30 second quotes; open, executed once per execution key, or expired |
| `Exchange` | Executes a quote and returns the ledger entries to append |
| `Card_fx` | Authorisation, re-pricing at the authorisation rate, refund shares |
| `Valuation` | Estimates at mid in a base currency, with thresholds |
| `Rate_source`, `Simulated_source` | Module type for rate suppliers; a deterministic simulated source |
| `Bundled` | Rate tables shipped as CSV text, for deployments without network access |
| `Refresh` | Pure fetch schedule, reported status, and a fetch that never empties a table on failure |
| `Refusal` | Every refusal, with a stable snake_case `code` (`no_rate`, `rate_too_old`, ...) |

Rules the pricing functions follow:

- Rates are stored as units of each currency per one pivot unit; the newest date on or before
  the request day wins, and a live rate beats a bundled one on the same date.
- The customer rate is the mid rate times one minus the spread, rounded down to 10 significant
  digits; cross mids are published to 20 significant digits.
- A rate is stale after 3 hours (still usable) and refused when the rate date or the fetch is
  more than 7 days old; the offline policy drops the maximum age.
- Every pricing function returns `(_, Refusal.t) Result.t`.

## Tests

- `dune test`: expect tests for every module and a cram test of the CLI, including offline mode.
- Quickcheck properties: significant-digit rounding stays within one unit of the last kept digit;
  a cross rate times its reverse is exactly one; the customer rate never exceeds mid and the
  bought amount misses its exact worth by less than one minor unit; the fee never exceeds the
  sold amount; executed quotes keep the ledger balanced and move the quoted amounts; partial card
  refunds never exceed the amount paid; simulated rates stay within their volatility band.
- `Ratio`, `Origin`, `Observation`, `Basis`, `Spread`, `Pricing.Fixed_side` and `Quote` have
  pinned `bin_digest`s; a change needs a new `Stable.V2`.
- `examples/quickstart.ml` runs in CI.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md), [payments-core](payments-core.md) and,
  transitively, [fixed-decimal](fixed-decimal.md). External: `core`, `core_unix`,
  `async_kernel`, `async`, `ppx_jane`, `zarith`.
- Used by: none yet.

## CI pin order

`fixed-decimal`, then `money`, then `ledger`, then `payments-core`. CI pins each from GitHub,
then runs `dune build`, `dune test` and the quickstart example, and the shared `obj-magic`
workflow.

## Known gaps

- No HTTP rate fetcher: services implement `Rate_source.S` over their own client.
- Rates are per business day; intraday or streaming rates would need a timestamp rather than a
  date in `Observation`.
- `Quote_book` is a value; a service with several replicas needs its own store with an atomic
  claim per quote, using the same rules.
- The pivot is fixed per table; currencies quoted only against another base need converting
  before they are added.
- Tokens without a reference rate (stablecoins priced from a market) are not modelled apart.
