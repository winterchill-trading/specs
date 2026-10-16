# transaction-monitoring

Real-time anti-money-laundering transaction monitoring for a bank. Every payment
initiated or booked goes through `Monitor.on_event`: bounded-memory rolling profiles of
the customer and the counterparty are updated, eleven typology rules (on risk-rules) and
a gradient-boosted model (scored through risk-models) decide `Allow`, `Hold` or `Block`
with explanations, and holds open alerts with a case lifecycle. Provider-neutral: events
carry stable keys, amounts and countries, never names or account numbers.

| | |
| --- | --- |
| Repository | `winterchill-trading/transaction-monitoring` |
| opam package | `transaction-monitoring` |
| Library | `transaction-monitoring` (module `Transaction_monitoring`) |
| Binary | `transaction-monitoring` (`generate`, `features`, `replay`, `bench`, `typologies`, `check-model`, `default-config`) |
| Status | done (2026-10-16) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Event` | Stable transaction event (`Stable.V1`, JSON lines): rail (SEPA, SCT Inst, Faster Payments, CHAPS, ACH, wire, card, intraledger, crypto), direction, `money` amounts in the payment and the reporting currency, times, MCC, card channel, device and country hints |
| `Window`, `P2_quantile`, `Recent`, `Country_set` | Bucketed sliding counters, P-square quantiles, a bounded recent-keys table, a country bitmap |
| `Profile` | Customer and counterparty profiles: 1 h / 24 h / 7 d / 30 d windows, quantiles, new counterparties, dormancy, round amounts, sub-threshold sums, cash, card bursts, pass-through, countries and devices; bin_prot snapshots |
| `Typology`, `Rules`, `Explanation` | Eleven typologies as `Risk_rules.Rule.t` with FATF, EBA, EU and US references; sexp config with shadow and disabled typologies; explanation records |
| `Features`, `Model` | risk-rules `Features.t` from event and profiles, laid out by `Risk_models.Encoding`, plus 32 AML features, each with a reviewer-facing label; a risk-models scorer on that schema and its explainer |
| `Policy`, `Decision`, `Alert` | Rules and score combined (model `Off`, `Shadow`, `Active`, optional abstain band); `Allow`/`Hold`/`Block` decisions (`Stable.V2`: rule explanations, score, the model's top feature contributions, abstention); the alert lifecycle as a pure state machine with SAR-candidate flag and four eyes on reopen |
| `Evaluator`, `Monitor`, `Replay` | Synchronous core; Async pipeline with bounded intake, idempotent per event id, LRU profile cache; history replay with baseline diffs, reasons per change and an accuracy-coverage table |
| `Store`, `Store_memory`, `Store_pg` | `Store.S` per ADR 0009; PostgreSQL schema `transaction_monitoring`, one transaction per event |
| `Synthetic` | Seeded generator of labelled activity: four personas, nine injected typologies, a third of episodes under rule thresholds, benign look-alikes |

## Design

- Profiles are read as views before an event and updated after it, so windows never
  include the event being judged. Windows are bucket-aligned (exact and reproducible,
  constant memory); times are clamped so a late event never moves a window backwards.
  A Quickcheck property checks every view against a from-scratch recomputation.
- One feature implementation: `transaction-monitoring features` writes training rows with
  the OCaml code that scores live events; `ml/train.py` trains scikit-learn trees, takes
  the positive weight out of the base score, picks thresholds from an alert budget and a
  precision target, and exports risk-models' format 1 with a parity fixture (1e-9).
- Decisions are stamped with the event's `received_at`, not a clock, so replays
  reproduce them; alert ids derive from event ids.
- Explanations: every hold and block (and every score from the hold threshold or the
  abstain band up) carries risk-models' exact path-dependent attributions, top five under
  reviewer-facing labels, which also give the model explanation its reasons. They are
  model contributions, not causes, and never reach the customer. Computing one costs
  about 65 us, so allowed payments skip it.
- Abstention: `Policy.abstain` sets a band in log-odds around the hold threshold; an
  abstaining score is held with "model uncertain" or left to the rules. `replay` prints
  the model's accuracy, precision and recall per coverage to choose the band from.
- `Monitor` serializes events (profiles need order), answers `Overloaded` past
  `max_pending` instead of buffering, awaits `on_decision` (a slow consumer slows
  intake), and evicts cached profiles on a failed or duplicate commit.
- Storage: event row first with `ON CONFLICT DO NOTHING`, then decision, alert, events
  and both snapshots in the same transaction; snapshots only replace older ones (by event
  count); alert updates are optimistic on the alert version. One conformance transcript
  for both stores; a restart test checks decisions through the store equal an
  uninterrupted replay. Decision and alert bodies carry a `body_version` (migration
  0002): V2 rows also store the explanation as JSON in `attribution`; V1 rows are
  upgraded on read.

## Numbers

Synthetic data only (5 000 customers, 75 days, 862 904 events, 0.2% positive events),
test window of 16 days:

| | Rules | Model (review) | Either |
| --- | --- | --- | --- |
| Alerts a day | 57.6 | 40.5 | 83.9 |
| Alert precision | 0.207 | 0.610 | 0.296 |
| Episode recall | 81/92 | 91/92 | 92/92 |

Model ROC-AUC 0.9999, average precision 0.960 (made-up patterns; not a real-world
estimate). Latency, release build on an M-series laptop: views 1.5 us, views and rules
2.3 us, views, rules and model 5.9 us; an explanation 68 us; full step with profile
updates p99 37 us (the tail is the decisions that get an explanation).

Abstaining on the whole synthetic history, band of 0.5 in log-odds around the hold
threshold (4 415 abstentions), against the active policy without it: routed to holds,
2 131 more alerts and recall 0.997 to 0.998; left to the rules, 1 932 fewer alerts,
recall 0.995 and alert precision 0.063 to 0.067.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md) (account and validated ids),
  [risk-rules](risk-rules.md) (rules, engine, features, country and MCC types),
  [risk-models](risk-models.md) (scorer, encoding, schema), [pg-async](pg-async.md)
  (`Store_pg`). External: `core`, `core_unix`, `async`, `core_bench`, `yojson`,
  `zarith`; Python `numpy`, `pandas`, `scikit-learn` for training only.
- Used by: none yet. Payment initiation, inbound booking and card authorisation call
  `Monitor.on_event`; the review tool uses `Monitor.review_queue` and `apply_alert`.

## CI pin order

`pg-async`, `fixed-decimal`, `money`, `ledger`, `payments-core`, `risk-rules`,
`risk-models`. CI installs `libpq-dev`, runs a Postgres service
(`TM_TEST_DATABASE_URL`), `dune build`, `dune test` and the odoc build with warnings as
errors.

## Known gaps

- Synthetic data only; thresholds and the model need real labelled cases.
- No multi-hop graph features; the counterparty table saturates at 64 entries.
- One monitor per customer partition for fresh profiles; alerts are per event (case
  grouping belongs to case management).
- Counterparty names are screened by [sanctions-screening](sanctions-screening.md), not
  here; no FX conversion (callers supply the reporting-currency amount).
