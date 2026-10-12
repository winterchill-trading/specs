# market-maker

One `market-maker` binary that runs the `mm-core` strategy on Hyperliquid, Binance or
Bybit, or on their local simulators, by wrapping each venue adapter in
`Mm_core.Live.Make`.

| | |
| --- | --- |
| Repository | `winterchill-trading/market-maker` |
| opam package | `market-maker` |
| Library | `market-maker` (module `Market_maker`) |
| Binary | `market-maker` (`-venue hyperliquid\|binance\|bybit`, `-network local\|testnet\|mainnet`, `-base-url`, `-address`, `-symbol`, strategy flags, `-run-for`) |
| Status | done |

## Key modules

- `Market_maker.Venues` (`lib/venues.mli`): `Venue_choice.t`, `Network.t`,
  `module type RUNNER` (`venue`, `endpoint`, `min_notional`, `connect_and_run`) and
  `runner ?base_url ?address ?getenv choice ~network`.

| Venue | Adapter | Simulator port | Default symbol |
| --- | --- | --- | --- |
| `hyperliquid` | `Hl_mm.Hl_venue` | 3000 | `BTC` |
| `binance` | `Binance_client.Venue` | 3300 | `BTCUSDT` |
| `bybit` | `Bybit_client.Venue` | 3400 | `BTCUSDT` |

Credentials come from the environment (`BINANCE_API_KEY`/`SECRET`,
`BYBIT_API_KEY`/`SECRET`, `HL_ADDRESS`). The venue minimum order value is read before
connecting and passed to `Params.for_instrument ~min_notional`.

## Dependencies

- Depends on: `exchange-core`, `mm-core`, `hl-protocol`, `hl-client`, `hl-mm`,
  `binance-protocol`, `binance-client`, `bybit-protocol`, `bybit-client`.
- Used by: `infra` (service image and compose stack).

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`, `order-book`,
`exchange-core-engine`, `venue-net`, `hl-client`, `hl-sim`, `mm-core`, `hl-mm`,
`binance-protocol`, `binance-sim`, `binance-client`, `bybit-protocol`, `bybit-sim`,
`bybit-client`. CI is green with these pins.

## End to end

`scripts/e2e.sh <venue> [seconds] [flags]` starts a seeded simulator on a free port,
runs the binary and prints the report; `scripts/e2e-all.sh` runs all three venues.

## Known gaps

- Hyperliquid orders are unsigned, so only `hl-sim` accepts them on that venue.
- The position is not flattened on stop.
- The README's build loop does not pin `parquet` and `market-data`, which the CI
  workflow does.
- Runs are not bit-repeatable with a fixed seed: request timing changes matching order.
