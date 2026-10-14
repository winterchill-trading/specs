# money

OCaml library for currencies, exact amounts, exchange rates and fees in payment systems.
Every value is an integer count of minor units; there are no floats in the API, every
rounding step names its mode, and arithmetic across two currencies is an error. It is the
base of the banking libraries: `ledger`, `payments-core`, `card-core`, `risk-rules` and
`banking-provider` all take their amounts from here.

| | |
| --- | --- |
| Repository | `winterchill-trading/money` |
| opam package | `money` |
| Library | `money` (wrapped as `Money`) |
| Binary | `money` (`convert`, `fee`, `currencies`), opam package `money-cli` |
| Status | done: library, CLI, example and tests in place; opam metadata ready, not published |

## Key modules

| Module | Purpose |
| --- | --- |
| `Currency` | Code, optional network tag (`USDC@polygon`), minor-unit exponent, fiat or crypto kind. A process-wide registry holds 40 ISO 4217 fiat currencies (exponents 0, 2 and 3), BTC (8), BTC@lightning (11, millisatoshis), ETH (18), and USDC and USDT (6) untagged and on Ethereum, Polygon, Solana and Tron. The registry is an immutable map behind an atomic reference (lock-free reads, compare-and-set writes); `register` validates and is idempotent; `freeze` stops new registrations; equality is by text form |
| `Amount` | Currency plus a Zarith integer of minor units. Text form `"12.34 EUR"` with exactly `exponent` digits. `add`, `sub`, `sum` and `compare_value` return an error on a currency mismatch; `scale`, `mul_ratio`, `mul_bps` and `mul_bps_q` (fractional basis points) take a `Rounding`; `split ~parts` and `allocate ~ratios` divide without losing a minor unit (largest remainder method); `to_q`/`of_q`, `to_fixed_decimal`/`of_fixed_decimal` (exact or error) and `minor_units_int` (when it fits) convert at the edges |
| `Rounding` | `Down`, `Up`, `Toward_zero`, `Away_from_zero`, `Half_even` (default), `Half_up` |
| `Rate` | Base, quote, exact rational price, timestamp and source. `convert` rounds once; `inverse` is exact |
| `Fee` | Fixed amount plus whole (`~bps`) or rational (`~bps_q`) basis points, clamped to a minimum and maximum. `Payable` rounds down, `Receivable` rounds up. `Stable.V1` keeps the whole-bps wire shape, `Stable.V2` carries bps as text |
| `Decimal_text` | Shared layout of an integer count as a decimal string with exactly `digits` fractional digits, with no floats |

Serialization: sexp for every type; JSON with all numbers as strings; `Stable.V1` bin_io
modules with pinned digests, so a changed wire shape fails a test rather than a replay.

## Tests

- `dune test`: expect tests per module, Base_quickcheck properties (text and sexp round
  trips, rounding bounds, conversion monotonicity, fee bounds, fractional bps against
  whole bps, allocation sums and the largest-remainder rule), a separate test library for
  the registry freeze, the quickstart example against its expected output, and a cram
  test of the `money` CLI (`convert`, `fee`, `currencies`).
- No environment variables and no network.

## Dependencies

- Depends on: [fixed-decimal](fixed-decimal.md) (for handing amounts to the trading stack).
  External: `core`, `zarith`, `yojson`, `ppx_jane`, `ppx_yojson_conv`; `core_unix` for the
  CLI only.
- Used by: `ledger`, and by the other banking libraries planned in
  [design/neobank.md](../design/neobank.md).

## CI pin order

`fixed-decimal`, then `money`. CI pins `fixed-decimal` from GitHub, then runs `dune build`
`dune test` and the examples, and the shared `obj-magic` workflow.

## Known gaps

- `Amount.allocate` takes integer ratios; a rational-ratio variant waits for a caller.
- No rate table or cross-rate derivation; `Rate` is a single quote, and choosing a source
  and a staleness rule is an application decision.
- No `Fixed_decimal` for crypto amounts: a fixed 8-digit type would not fit ETH (18
  digits), so amounts use Zarith minor units. The cost is that `Amount` values are larger
  than `Fixed_decimal` values for the same magnitude.
- OxCaml only; see [research/opam-readiness/money.md](../research/opam-readiness/money.md).

Fixed on 2026-10-14: fractional basis points (`Amount.mul_bps_q`, `Fee.create ~bps_q`),
amount allocation (`Amount.split`, `Amount.allocate`), and the unsynchronised registry
(atomic map plus `Currency.freeze`).
