# hl-mm

The Hyperliquid side of the market maker: `Hl_venue` implements `Mm_core.Venue.S` over
`hl-client`, and the `hl-mm` executable runs `Mm_core.Live.Make (Hl_venue)` against
`hl-sim` or any Hyperliquid-compatible API that accepts unsigned requests.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-mm` |
| opam package | `hl-mm` |
| Library | `hl-mm` (module `Hl_mm`) |
| Binary | `hl-mm` (`-base-url`, `-address`, `-coin`, `-levels`, `-size`, `-half-spread-bps`, `-skew-bps`, `-max-position`, `-requote-ms`, `-run-for`, `-summary-secs`, `-log-level`) |
| Status | done |

## Key modules

- `Hl_mm.Hl_venue` (`lib/hl_venue.mli`): `Mm_core.Venue.S` with
  `config = Hl_client.Config.t`; `tick_of_mid` (5 significant figures, at most
  `6 - szDecimals` decimals); pure `Convert` functions (reject wording, order update
  statuses, order requests).

## Dependencies

- Depends on: `exchange-core`, `mm-core`, `hl-client`, `hl-protocol`, `fixed-decimal`.
- Test-only: `hl-sim`.
- Used by: `market-maker`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`, `venue-net`,
`hl-client`, `mm-core`, then `order-book`, `exchange-core-engine`, `hl-sim` for the
integration test. CI is green with these pins.

## Known gaps

- Orders are unsigned (the simulator's `X-Address` convention), so only `hl-sim`
  accepts them; market orders and non-128-bit client ids are rejected locally.
- Clearinghouse snapshots whose `liquidationPx` exceeds the `fixed-decimal` range are
  logged and skipped.
- `scripts/e2e.sh` assumes the shared dune workspace.
- The README's opam pin list omits `venue-net`, `parquet` and `market-data`.
