# chain-books

OCaml double-entry books for an organisation's on-chain treasury. Venue records (fills,
funding payments, deposits, withdrawals and transfers, staking rewards, builder-fee income)
are normalised into activities, booked as balanced `ledger` entries over a chart of
accounts, tracked as positions with a cost basis, valued at market through a price hook,
and reconciled against the balances the chain reports. The library is pure: no storage,
no network, no clock. Each chain write is prepared with a nonce, resent with the same body
after an unknown outcome, and confirmed only when a sync sees the movement.

| | |
| --- | --- |
| Repository | `winterchill-trading/chain-books` |
| opam package | `chain-books` |
| Library | `chain-books` (module `Chain_books`), `chain-books.hyperliquid` (module `Chain_books_hyperliquid`) |
| Binary | none |
| Status | done: libraries, quickstart example and tests are in place; not on opam yet |

## Key modules

| Module | Purpose |
| --- | --- |
| `Short_id`, `Binding_id`, `Address`, `Event_id` | Identifiers; event ids are deterministic from venue ids |
| `Venue`, `Location`, `Assets` | Venues, a venue of one address (`perp`, `spot`, `rewards`, `vault`, `staking`), and assets as `money` currencies |
| `Category`, `Chart` | Counterparty categories with account kinds, and the chart of accounts per binding |
| `Activity`, `Fill`, `Instrument`, `Exact` | One movement at one location, a perpetual or spot fill, an instrument, and exact quantities and prices |
| `Observed`, `Normalized`, `Normalizer` | Venue records as observed balances and normalised values; the `Normalizer.S` module type |
| `Booking` | Activities as single-currency ledger entries, with a classification hook |
| `Opening` | Opening balances, derived once at the first observation |
| `Positions` | FIFO and average cost positions per address and instrument |
| `Reconciliation` | Balances and perpetual positions against the chain's reports: matched, difference, untracked, not reported |
| `Price_source`, `Valuation` | Marks and rates through a price hook; stale or missing prices are listed, not guessed |
| `Chain_write` | Prepare, submit, resend and confirm record for writes to a chain |
| `Books` | Ties the above into one immutable value: ingest, open balances, reconcile, value |
| `Chain_books_hyperliquid.Adapter` | Implements `Normalizer.S` over Hyperliquid records; decoders for the info answers hl-protocol does not cover (`Config`, `Ledger_update`, `Funding`, `Staking_reward`, `Spot_state`, `Delegator_summary`, `Builder_fill`) |

Rules enforced by the books:

- One activity, one single-currency entry, keyed `chain:<binding>:<event id>`. Reading the
  same history twice books it once; an event id reused for another movement is an error.
- A movement between two locations of the binding is one activity with both locations in one
  entry. Custody accounts may go negative, because one side of a transfer can be read before
  the other.
- Amounts are rounded to the asset's minor unit once, half-even, in the adapter.
- Reconciliation never books. Untracked records are reported, never booked.
- Positions: fees are not capitalised, matching how venues report closed profit; each fill
  applies once.
- Chain writes: a reused nonce or exhausted attempts end `unconfirmed`, never reversed
  automatically. A refusal needs a reversal.
- Every persisted value has a `Stable.V1` with a pinned `bin_digest`; a change needs a `V2`.

## Hyperliquid adapter

The adapter reads fills (`userFills`, `userFillsByTime`, websocket `userEvents`), funding,
ledger updates (`userNonFundingLedgerUpdates`), staking rewards (`delegatorRewards`), a daily
builder-fill file given by the caller, and balances (`clearinghouseState`,
`spotClearinghouseState`, `delegatorSummary`). Fills become `:pnl`, `:fee`, `:builder`, `:base`
and `:quote` activities; ledger updates cover deposits, withdrawals, transfers, vault
movements and rewards claims. Other update types are decoded and book nothing. The info
answers are described in `docs/hyperliquid.md` in the repository. Fixtures have the same
shapes as mainnet answers, checked in October 2026.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md) and [hl-protocol](hl-protocol.md)
  (the Hyperliquid sub-library); through them `fixed-decimal` and `exchange-core`.
- External: `core`, `zarith`, `yojson`, `ppx_yojson_conv`, `ppx_jane`.
- Used by: none in the organization yet.

## CI pin order

`fixed-decimal`, `exchange-core`, `hl-protocol`, `money`, then `chain-books`. CI pins each from
GitHub through the `infra` ox-setup action, then runs `dune build`, `dune test`, the quickstart
example, the odoc build with warnings as errors, and the shared `obj-magic` workflow.

## Known gaps

- `rewardsClaim` is decoded from its documented `amount` field; no mainnet sample was at hand.
  Where claims are credited is configurable.
- `liquidation`, `borrowLend` and `activateDexAbstraction` updates book nothing, so lending
  balances show as reconciliation breaks.
- A vault withdrawal books the net amount withdrawn; the vault's gain or loss stays in the
  `vaults` account until valued by the caller.
- Spot USDC is reported with 8 digits and booked with 6, so reconciliation uses a tolerance of
  one minor unit.
- Reconciliation has no "sync in progress" status; the caller decides when a report is current
  enough to compare.
- Opening balances and transfers in create no cost-basis lots; `Positions.add_lot` adds them
  at a known price.
- The Hyperliquid info decoders could move into hl-protocol.
