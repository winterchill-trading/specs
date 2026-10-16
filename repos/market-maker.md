# market-maker

One `market-maker` binary that runs the `mm-core` strategy on Hyperliquid, Binance or
Bybit, or on their local simulators, by wrapping each venue adapter in
`Mm_core.Live.Make`.

| | |
| --- | --- |
| Repository | `winterchill-trading/market-maker` |
| opam package | `market-maker` |
| Library | `market-maker` (module `Market_maker`) |
| Binary | `market-maker` (`-venue hyperliquid\|binance\|bybit`, `-network local\|testnet\|mainnet`, `-base-url`, `-address`, `-i-understand-mainnet`, `-symbol`, strategy flags, `-max-actions-per-sec`, `-params FILE`, `-shadow-params FILE`, `-strategy-log FILE`, `-order-log FILE`, `-reference anchor\|VENUE:SYMBOL[@URL]`, `-toxicity-bucket`, `-toxicity-window`, `-toxicity-signal percentile\|vpin`, `-run-for`) |
| Status | done |

## Key modules

- `Market_maker.Venues` (`lib/venues.mli`): `Venue_choice.t`, `Network.t`,
  `module type RUNNER` (`venue`, `endpoint`, `min_notional`, `connect_and_run` with
  optional `time_source`, `reload`, `shadow_params`, `strategy_log`, `order_log`,
  `cycle_monitor`, `reference` and `toxicity`) and
  `runner ?base_url ?address ?allow_mainnet ?getenv choice ~network`.
- `Session.Make (V)`: one run over `Mm_core.Live.Make`; its outcome is the live report,
  tick-to-order stats (printed at exit), reload count, shadow counts and plausibility
  events by kind. `?reference` mids and `?toxicity` signals go to
  `Mm_core.Live.on_reference`/`on_toxicity` and, as `Strategy_input.Reference`/`Toxicity`
  with their time, to the shadow and the strategy log; `Live.on_strategy_event` feeds the
  order log.
- `Reference_source`: reference mids for mm-core's `Reference_guard`. `anchor` polls the
  simulator's anchor status (hl-sim `/status`, binance-sim and bybit-sim `/sim/anchor`)
  and passes the fresh `reference_price`; `VENUE:SYMBOL[@URL]` passes the mid of another
  venue's public best bid and offer (its mainnet by default, read-only).
- `Toxicity_source`: mm-core's `Toxicity_gate` signal from market-data's VPIN over the
  venue's public trades, per filled bucket (the `Toxicity_input` pattern of
  `mm-core-replay`): the percentile (default) or VPIN itself once the window is full.
  `reference_guard` and `toxicity_gate` are params-file fields (partial records merged
  with the defaults, reloaded on SIGHUP); either set without its source logs an error.
- `Params_file`: sexp overrides of `Mm_core.Params.t` fields. `-params FILE` is read
  again on SIGHUP; new parameters go to the running loop through
  `Mm_core.Live.update_params`, so quotes stay on the book. Invalid parameters or a
  symbol change are logged and the old parameters stay. The strategy log records the
  reload as an `Update_params` line and shadow strategies take it in place. The session
  attaches observers through `?on_venue` and a `Live.on_resync` hook starts the grace
  period on the shadow strategies and writes a `Resync` line the replay feeds back.
- `Shadow`: `-shadow-params` runs a second strategy on the same inputs and logs the
  plans that differ; they are never sent.
- `Strategy_input`, `Strategy_log`, `Replay`: `-strategy-log` writes every input and plan
  as sexp lines, and a replay through a fresh strategy compares every plan (an 8 s run:
  187 ticks, no mismatch).
- `Venue_script`: one order sequence between two accounts, behind
  `scripts/compare-venues.sh` (hl-sim against binance-sim, diffed).

| Venue | Adapter | Simulator port | Default symbol |
| --- | --- | --- | --- |
| `hyperliquid` | `Hl_mm.Hl_venue.Trading` | 3000 | `BTC` |
| `binance` | `Binance_client.Venue` | 3300 | `BTCUSDT` |
| `bybit` | `Bybit_client.Venue` | 3400 | `BTCUSDT` |

Credentials come from the environment (`BINANCE_API_KEY`/`SECRET`,
`BYBIT_API_KEY`/`SECRET`, `HL_PRIVATE_KEY`, `HL_ADDRESS`). With `HL_PRIVATE_KEY` set,
Hyperliquid requests are signed through `hl-client`'s trading handle (testnet domain
unless the REST root is `api.hyperliquid.xyz`) for `-address`, `HL_ADDRESS` or the key's
address; without it they are unsigned (`hl-sim`'s `X-Address`). A signed run against
mainnet is refused unless `-i-understand-mainnet` is passed. The venue minimum order value is read before
connecting and passed to `Params.for_instrument ~min_notional`.

- `Order_log`: `-order-log FILE` writes every place and cancel request, its reply, and
  every order update and fill as CSV with local and venue times, plus `guard`, `gate` and
  `toxicity` rows for the plausibility checks; `queries/fills_vs_trades.sql`
  joins fills to public trades in market-data's Parquet tables (trade id, else price, size,
  side and nearest time within 2 s).
- `Cycle_monitor`: Async cycles over 50 ms counted and over 20 ms warned, in the report,
  the status line and the `e2e-all.sh` table.
- `market-maker-status ORDER_LOG`: follows an order log in a bonsai_term view (resting
  orders, position, fees, ack latency, fills, the latest guard, gate and toxicity rows);
  `-once` prints text and is all that works
  where bonsai_term is absent. `nightly.yml` builds daily against upstream main and runs
  the e2e script weekly with the latency table in the job summary.

## Dependencies

- Depends on: `exchange-core`, `mm-core`, `mm-core-replay`, `market-data`, `hl-protocol`, `hl-client`, `hl-mm`,
  `binance-protocol`, `binance-client`, `bybit-protocol`, `bybit-client`; tests also on
  `hl-sim`.
- Used by: `infra` (service image and compose stack).

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`, `venue-net`,
`hl-client`, `mm-core`, `mm-core-replay` (the mm-core repository again), `hl-mm`,
`binance-protocol`, `binance-client`, `bybit-protocol`,
`bybit-client`, `order-book`, `exchange-core-engine`, `price-anchor`, `hl-sim`. `hl-sim`
(with its engine and `price-anchor`) is a test dependency of the signed Hyperliquid test;
the other simulators are not pinned, the scripts build them from a workspace.

## End to end

`scripts/e2e.sh <venue> [seconds] [flags]` starts a seeded simulator on a free port,
runs the binary and prints the report; `FAULT_AT=SECONDS` restarts the simulator mid-run
and fails unless the run reconnects, resyncs, places orders again and ends `Running`;
`SIGNED=1` (Hyperliquid) signs with a throwaway key and fails unless every order request
in hl-sim's journal is signed, for the key's account.
`scripts/e2e-all.sh` prints every sibling checkout's commit, runs all three venues, then
a fault run on Binance, and ends with a tick-to-order table (30 s per venue on an
M-series Mac: p50 43 to 62 us, p99 118 us to 1.8 ms). The fault run uses the
default action cap of 100: the requote burst after a simulator restart falls inside
`-action-rate-grace-ms` (5000), and `-action-rate-cooldown-ms` can clear a later halt.
`scripts/e2e-plausibility.sh` runs the maker on an hl-sim anchored live on a second
hl-sim with `-reference anchor` and a VPIN signal: pausing the reference (SIGSTOP 8 s)
must pull the quotes (`reference_missing`, 4 s after the pause) and resume them after the
thaw, and a burst of 100 IOC buys must widen the quotes (VPIN 0.67, 2 s in) before the
gate pulls them (0.87, 6 to 10 s in); checked from the order log, passed twice on
2026-10-16.
CI runs `shellcheck` on the scripts and prints the resolved pins. The README lists
venue differences found by `compare-venues.sh`.

## Known gaps

- No signed Hyperliquid order has been placed on testnet with a funded account; `hl-sim`
  does not check signatures, so the signed tests show the signer, not acceptance.
- The position is not flattened on stop.
- Runs are not bit-repeatable with a fixed seed: request timing changes matching order.
- The plausibility e2e's VPIN thresholds are tuned to hl-sim's mixed flow; the percentile
  signal relaxes under lasting one-sided flow, so a sustained toxic regime needs `vpin`.
- A `VENUE:SYMBOL` reference only updates on top-of-book changes; a quiet reference ages
  into `reference_missing`.
