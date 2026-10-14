# rewards-core

OCaml loyalty points library for card programmes: an append-only points ledger per customer,
earn rules for settled card spend with category multipliers, proportional clawback on refunds,
one-off action bonuses, tiers over a rolling window with benefits, cashback redemption booked
as balanced ledger entries, an expiry policy and points statements. Amounts are exact minor
units, with no floats. It deliberately does not persist, talk to a network or know card
networks: a service implements the `Store.S` module type, and the caller appends the cashback
entry to its own journal.

| | |
| --- | --- |
| Repository | `winterchill-trading/rewards-core` |
| opam package | `rewards-core` |
| Library | `rewards-core` (module `Rewards_core`) |
| Binary | none |
| Status | done: library, in-memory store, conformance suite, example and property tests; CI in place |

## Key modules

| Module | Purpose |
| --- | --- |
| `User_id`, `Source_id`, `Redemption_id`, `Action`, `Category` | Validated ids in the ledger's alphabet, at most 100 characters |
| `Kind` | Earn, Bonus, Reversal, Redeem, Adjustment, Expire, with the sign each requires |
| `Cause` | Why an entry exists; its key is unique per customer |
| `Entry`, `Earning` | One ledger line, and how a purchase's points were computed |
| `Points_account` | A customer's entries folded into a balance; `apply` enforces the rules |
| `Earn_rules` | Basis currency, points per unit, category multipliers, action bonuses, clawback arithmetic |
| `Benefit`, `Tier`, `Tiers` | Tier ladder over a rolling window; spread caps, fee schedules and perks |
| `Cashback` | Steps, value per step, minimum and maximum; quotes rounded down |
| `Expiry` | `Never` or `After_days n`; points expiring first are spent first |
| `Program` | The whole configuration, loadable from a sexp |
| `Redemption`, `Booking` | Redemption state machine; the balanced ledger entry that pays it |
| `Summary`, `Statement` | Balance, tier, redeemable and expiring points; statements with running balances |
| `Store`, `Store_memory`, `Store_conformance` | Persistence as a module type, an in-memory store, scenarios any store must pass |
| `Engine` | Settle, refund, bonus, adjust, expire, quote and redeem over any store and monad |
| `Refusal` | Every refusal as data with a stable code |

Rules enforced by `Points_account.apply` and the store contract:

- Entries are append-only and numbered per customer without gaps; corrections are new
  `Adjustment` entries.
- The balance never goes below zero; a clawback is capped at the balance.
- Each cause books at most once per customer; the same cause with other content is
  `Cause_conflict`.
- Refunds claw back in proportion to the refunded share, cumulatively.
- The cashback entry's idempotency key is `rewards:redemption:<id>`.

## Tests

- `dune test`: expect tests per feature and the quickstart example diffed against its
  expected output.
- Quickcheck properties drive random streams of purchases, refunds, bonuses, adjustments,
  redemptions and expiry runs through the engine and check the rules after every step.
- `test_stable.ml` pins the digests of the `Stable.V1` bin_prot and sexp forms.
- `Store_conformance` runs against `Store_memory`; a service runs it against its own store.

## Dependencies

- Depends on: [money](money.md) and [ledger](ledger.md) (through them
  [fixed-decimal](fixed-decimal.md)). External: `core`, `ppx_jane`, `zarith`;
  `expect_test_helpers_core` for tests and `odoc` for docs.
- Used by: none yet.

## CI pin order

`fixed-decimal`, then `money`, then `ledger`. CI pins each from GitHub through the shared
`ox-setup` action, then runs `dune build`, `dune test`, `dune build @examples/runtest` and
`dune build @doc` (odoc warnings fail the step), and the shared `obj-magic` workflow.

## Known gaps

- Partner redemptions (points transferred to another scheme) are not modelled.
- The money ledger is not driven by the engine: the caller appends the cashback entry, so
  a service that wants both in one transaction does that in its own store.
- Tier windows count entries by event time; a very late settlement counts in the window of
  its event date, not of its arrival.
