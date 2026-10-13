# risk-rules

OCaml library for transaction monitoring and fraud control on outgoing transfers and card
authorisations. Rules are named checks with a severity (`Allow < Challenge < Review <
Block`) and a stable reason code. The engine runs every rule, keeps every hit with its
evidence, and takes the worst severity. The library is pure and synchronous, does no I/O
except reading a policy file, and fails closed.

| | |
| --- | --- |
| Repository | `winterchill-trading/risk-rules` |
| opam package | `risk-rules` |
| Library | `risk-rules` (module `Risk_rules`) |
| Binary | `risk-rules` (`check-policy`, `evaluate`, `features`, `reason-codes`) |
| Status | done: rules, policy loading, review queue and tests are in place; CI green |

## Key modules

| Module | Purpose |
| --- | --- |
| `Severity` | `Allow < Challenge < Review < Block` |
| `Reason_code` | Stable codes carried by every hit; customer messages use them without tipping off the customer |
| `Typology` | Structuring, money mule (pass-through, fan-in, new-account payout), account takeover, authorised push payment scam, card testing |
| `Hit`, `Decision` | A rule's hit with its evidence; a decision is the worst severity over all hits, with the full list |
| `Rule`, `Rule_spec` | A named check over a context, built in code or from a spec |
| `Engine` | Runs every rule over a `Context.t`; no rule is skipped after a hit |
| `Context` | Inputs for one decision: customer, tier, time, balances, history, incoming transfers, card history, geo, session. Built from `payments-core` transfer drafts and beneficiaries |
| `Features` | 39 numeric fields, `schema_version` 1, with a versioned JSON form, for model scoring and training |
| `Model` | `Model.S` interface; `Score`, a `logistic` model and a `constant` model |
| `Limits` | Per-currency caps |
| `Rules` | The built-in rules; `Thresholds` for their numbers; `Tra` for the PSD2 transaction risk analysis bands |
| `Sca_outcome` | Whether strong customer authentication is needed, exempt, or refused |
| `Policy` | Maps customer tiers to rule sets; loads from a sexp file (`Policy.load`) |
| `Shadow` | Shadow mode: rules run and are logged but do not change the decision |
| `Review_queue` | Immutable queue of decisions that need an operator |
| `Tier`, `Country`, `Mcc` | Customer tier, sanctions-relevant country lists, merchant category codes |

Stable digests of the context and the decision are pinned in tests. The context digest
follows the `payments-core` transfer types it summarises, so a change there changes the
digest on purpose.

## Tests

- `dune test`: expect tests per rule, each with its evidence in the output.
- Base_quickcheck properties: adding a rule never lowers a decision; logistic scores are in
  `[0, 1]`.
- Pinned digests for `Context` and `Decision` (see the note above).

## Dependencies

- Depends on: [money](money.md), [payments-core](payments-core.md) (transfer drafts,
  beneficiaries with trust, first use and payee check, travel-rule records).
  External: `core`, `core_unix` (CLI), `ppx_jane`, `ppx_yojson_conv`, `yojson`, `zarith`.
- Used by: `neobank-api` and the card authoriser (planned, see
  [design/neobank.md](../design/neobank.md)); `risk-models` implements `Model.S`.

## CI pin order

`fixed-decimal`, `money`, `ledger`, `payments-core`, then `risk-rules`. CI pins each from
GitHub, then runs `dune build` and `dune test`, and the shared `obj-magic` workflow.

## Known gaps

- No FX: caps are per currency, and the TRA bands apply to EUR only.
- SCA exemptions cover only the trusted beneficiary and TRA exemptions.
- The TRA fraud rate comes from the policy file, not from a rolling count of the book.
- No sanctions name screening; only country lists.
- Card spend is not counted in transfer caps, and transfer spend is not counted in card
  limits.
- `risk-models` must adopt the `Model.S` interface before its scores reach a decision; the
  bundled models are shadow-mode only.
