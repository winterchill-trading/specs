# mm-core

Venue-neutral market-making core: a pure quoting strategy, a reconciler, risk checks,
the `Venue.S` client signature and the `Live.Make` event loop that runs the strategy on
any venue implementing it.

| | |
| --- | --- |
| Repository | `winterchill-trading/mm-core` |
| opam package | `mm-core` |
| Library | `mm-core` (module `Mm_core`) |
| Binaries | `mm-core` (package `mm-core-replay`): `replay -norm DIR -symbol S` drives `Strategy` from a `Replay_feed` event log and prints the plans; no fills are simulated |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Fx` | Fixed-point helpers: notionals, bps shifts, tick and lot rounding |
| `Params` | Strategy parameters, `Params.btc` defaults, `for_instrument`, `validate` |
| `Fill`, `Order_update` | Account events as the strategy sees them |
| `Market_state` | Last book, mid, microprice, EWMA volatility |
| `Inventory` | Position, average entry, realized and unrealized PnL, fees |
| `Quote`, `Quoter` | Desired orders; `quote : Params.t -> Market_state.t -> Inventory.t -> Quote.t list`; `quote_with_reasons` (typed `Unquoted.t` per empty side); `For_testing.explain` |
| `Action`, `Reconciler` | `Keep`/`Cancel`/`Place`; minimal plan from resting orders, deterministic client ids |
| `Risk` | Kill switch, one second `Action_rate` window, flatten plan; non-sticky pull reasons `Reference_divergence`, `Reference_missing`, `Toxic_flow` |
| `Toxicity_gate` | Pure decision from a toxicity signal (a percentile in `[0, 1]`) and the signed flow imbalance: `Normal`, `Widen` (wider half-spread, reservation shift towards the flow, smaller size, linear between the thresholds) or `Pull`; stale signals count as none |
| `Reference_guard` | Plausibility of the venue mid against an independent reference mid: `Diverged` (pull) after `grace_ms` outside `band_bps`, at once after a reference jump over `max_jump_bps`; `Reference_missing` (pull) or `Unchecked` without a fresh reference; typed events |
| `Latency_histogram` | Count, p50, p99 at two significant digits, exact max |
| `Strategy` | State machine: `on_book`, `on_fill`, `on_open_orders`, `on_account`, `on_reference`, `on_toxicity`, `tick ~now`, `tick_with_events`, `events_between` |
| `Venue` | `module type S`, the Async venue client contract |
| `Live` | `Make (V : Venue.S)`: feeds, polls, sequenced plan execution, shutdown, `Report` with `tick_to_order` latency and `gc` counts (minor and major collections, heap words), `stop_signal`; optional `?time_source`; `on_reference`, `on_toxicity` and `on_strategy_event` for the plausibility checks |

New parameters, defaulting when absent from a sexp: `max_actions_per_sec` (100; more
cancels and places in the last second trip the kill switch), `soft_max_position` and
`bump_budget` (past the soft limit only the side that would grow the position is pulled).
`Market_state` is a flat record with `Float_u.t` fields and `or_null` accessors;
`Strategy.tick_u` returns an unboxed pair and allocates nothing on an idle tick; `Fx` has
`float#` conversions. A bisimulation test runs 300 random event scripts against the pure
reference modules in `test/ref_*.ml`.

`Params.validate` names every field and rejects NaN and infinity in every float. The five
`_ms` duration fields are `Time_ns.Span.t`; their sexp accepts a span (`1s`) or an integer
of milliseconds and prints a span.

Hot parameter updates: `Strategy.update_params` returns a new strategy that keeps market
state, inventory and resting orders (symbol changes and invalid parameters are rejected);
`Live.connect_and_start` returns the running loop, on which `update_params` swaps
parameters without a restart or cancel-all, and `stop` ends it. The action-rate kill
switch is a rolling one-second window; `action_rate_grace_ms` (5000) suspends it after
every venue reconnect (`Strategy.on_resync`) and `action_rate_cooldown_ms` (none) clears
an action-rate halt only. Position and drawdown halts stay permanent. `Live.on_resync live
~f` runs `f` on every venue reconnect after the loop's own grace period starts, and
`?on_venue` on `connect_and_start` and `connect_and_run` attaches observers to the venue
before the loop starts.

Plausibility checks (both optional parameters, absent from a sexp by default):
`reference_guard` pulls quotes while the venue mid stays outside a band around a reference
mid fed with `on_reference` (data that is fresh but wrong, next to the age check on data
that stopped); `toxicity_gate` widens, skews and shrinks quotes, then pulls them, as a
toxicity signal fed with `on_toxicity` rises. Both run after the risk checks and only
pull. mm-core does not depend on market-data: `mm-core-replay`'s `Toxicity_input` turns
market-data's VPIN buckets into the signal. `Quoter` takes an optional `?shift_bps`
reservation shift for the gate's skew. An idle tick allocates nothing with both
configured (79 ns against 67 ns without, dev profile); a requote is 3061 words (3050
before the strategy record grew).

## Tests and benchmarks

Expect and `Base_quickcheck` tests of the strategy (quotes never cross or breach the
limit; reconciling right after applying a plan only keeps; `Risk.flatten` only sends
reduce-only orders; one fixed state quoted under each preset); live-loop tests over an
in-memory `Venue.S` with a seeded bug mode (random rejects, late cancel acks, split fills,
stale polls, places that time out but rest later, slow answers); a property test feeding
random book, fill and wait scripts through `Live.Make` on a synthetic `Time_source`; and
`test/stepped.ml`, a deterministic stepped harness with a toy exchange and seeded fills,
one run pinned line by line.

The live-loop property test found a real bug: the reconciler could keep a resting order
at the next ladder level's price, so the ladder held two orders on one price level. It
now keeps an order only if it lies strictly between the previous level's final price and
the next desired price (commit `c7697d9`).

core_bench, M-series Mac, dev profile:

| Case | Time/run | Minor words/run |
| --- | ---: | ---: |
| `quote` flat | 362 ns | 357 |
| `quote` long | 363 ns | 357 |
| `quote` + `reconcile` (all kept) | 1125 ns | 748 |

Before the ladder kept per-rung terms for `explain` and the unquoted reasons, `quote` was
317 ns and 221 words.

## Dependencies

- Depends on: `exchange-core`, `fixed-decimal`.
- Used by: `hl-mm`, `binance-client`, `bybit-client`, `market-maker`.

## CI pin order

`fixed-decimal`, `exchange-core`.

## Design

See [design/market-making.md](../design/market-making.md).

## Known gaps

- The position is not flattened on exit; `stop` only cancels resting orders.
- One symbol per `Live.Make` run.
- Venue calls have no timeout in mm-core; a venue that never answers blocks the loop and `stop`.
- No producer is wired in `market-maker` yet: the guard needs a reference feed (another
  venue's mid or a price-anchor mark) and the gate a `Toxicity_feed` per symbol.
  `market-maker`'s params-file field list does not include the two new fields.
- The toxicity percentile relaxes under one-sided flow that lasts; a sustained toxic
  regime needs a threshold on VPIN itself.
