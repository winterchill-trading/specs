# card-core

Provider-neutral card issuing: the card lifecycle, card controls and limits, the issuer's
authorization decision (including PSD2 strong customer authentication and 3-D Secure for card
payments), clearing and settlement against holds with FX, disputes, per-card statements, and
the ledger entries for each event. It persists nothing: callers keep cards, authorizations and
clearings in their own store and pass them in. It never sees a full card number, CVV or PIN.

| | |
| --- | --- |
| Repository | `winterchill-trading/card-core` |
| opam package | `card-core` |
| Library | `card-core` (module `Card_core`) |
| Binary | `card` (`codes`, `hold-expiry`, `demo`) |
| Status | done: library, CLI and property tests are in place; CI pinned |

## Key modules

| Module | Purpose |
| --- | --- |
| `Card` | Id, holder, funding account, billing currency, kind (virtual or physical), masked PAN, limits, and the status machine below |
| `Masked_pan`, `Pan_display_token`, `Pan_guard` | Last four digits and expiry only; an opaque token for the provider's PAN display component that never prints; a Luhn guard that refuses or masks card numbers in free text |
| `Limits` | Per-transaction, daily and monthly caps; ATM amount and count caps; card-absent, contactless and ATM toggles; MCC and country block lists; `check` and `headroom` |
| `Authorization` | Requested and approved amounts, merchant, MCC, country, entry mode, 3-DS result, SCA evidence, response code, and the captured, cleared, released and refunded totals; increments, partial reversals, expiry, clearings and refunds; `usage` for the limits |
| `Decision` | Pure: card, limits, usage, available balance, SCA and a risk hook give `Approve { amount; partial; sca }` or `Decline reason`, with a fixed check order (funds before SCA) |
| `Card_sca`, `Three_ds` | SCA for a card payment: authenticated by 3-DS or the terminal, exempt under RTS articles 11, 12, 13, 14, 16, 17 or 18, out of scope (merchant-initiated, mail or telephone order), or the `1A` soft decline; ECI per scheme and liability shift |
| `Settlement` | Clearing records (debit and credit, FX at the scheme rate with our fee) and how each settles against its authorization; excess above 20 % goes to review |
| `Booking` | Ledger entries for every event, pure over `Ledger.Balances.t` |
| `Dispute` | Visa-style reason categories 10 to 13, stages with their time limits, evidence and outcome; a 120-day window; fraud disputes checked against the 3-DS liability shift |
| `Statement` | One card's purchases, refunds, FX fees, pending holds and optionally declines for a period |
| `Response_code`, `Decline_reason` | ISO 8583 field 39 codes with retry categories; why a request was declined |
| `Mcc`, `Country`, `Entry_mode`, `Merchant`, `Ids` | The small types the rest is built from |

### Card states

| From | To |
| --- | --- |
| Requested | Active, Destroyed |
| Active | Frozen, Blocked, Expired, Destroyed |
| Frozen | Active, Blocked, Expired, Destroyed |
| Blocked | Destroyed |
| Expired | Destroyed |
| Destroyed | (terminal) |

Every state but Active declines: Requested and Frozen with `57`, Blocked with `62`, Expired with
`54`, Destroyed with `46`.

### Authorization states

`Pending -> Authorized -> Partially_cleared -> Cleared`, or `Declined`, `Reversed` or `Expired`.
A hold stays valid for 7 days, or 30 days for some MCCs (for example 7011, hotels).

## Tests

- `dune test`: expect tests for approval, insufficient funds, a frozen card, partial settlement,
  reversal, refund, a tip above the hold, an unpayable clearing, a late clearing after expiry,
  and FX with a fee; a duplicate webhook through a real journal. Further tests cover SCA,
  disputes, statements and stable digests; cram tests cover the CLI.
- Base_quickcheck properties: holds reconcile with the ledger; approved authorizations never
  exceed limits. Both were checked against deliberately broken code.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md), [payments-core](payments-core.md)
  (SCA types, exemptions and counters).
- Used by: none yet; planned for `banking-provider` (see
  [design/neobank.md](../design/neobank.md)).

## CI pin order

`fixed-decimal`, then `money`, then `ledger`, then `payments-core`. CI pins each from GitHub,
then runs `dune build` and `dune test`, and the shared `obj-magic` workflow.

## Known gaps

- Ledger hold builders take no SCA evidence; a follow-up in `ledger` is needed.
- Hold validity is simplified to the 7-day and 30-day rule.
- Usage windows are UTC.
- Partial approval applies to funds only.
- SCA counters are EUR only.
- The receivable is not netted against later deposits.
- No network tokens and no interchange.
- One dispute window applies to all reasons.
