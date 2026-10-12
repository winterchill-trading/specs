# hl-mm

The Hyperliquid side of the market maker: `Hl_venue` implements `Mm_core.Venue.S` over
`hl-client`, and the `hl-mm` executable runs `Mm_core.Live.Make (Hl_venue.Trading)`
against `hl-sim` (unsigned requests) or Hyperliquid testnet (requests signed with
`HL_PRIVATE_KEY`). It refuses mainnet.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-mm` |
| opam package | `hl-mm` |
| Library | `hl-mm` (module `Hl_mm`) |
| Binary | `hl-mm` (`-base-url`, `-testnet`, `-address`, `-coin`, `-levels`, `-size`, `-half-spread-bps`, `-skew-bps`, `-max-position`, `-max-actions-per-sec`, `-soft-max-position`, `-params FILE`, `-requote-ms`, `-run-for`, `-summary-secs`, `-log-level`) |
| Status | done |

## Key modules

- `Hl_mm.Hl_venue` (`lib/hl_venue.mli`): `Mm_core.Venue.S` with
  `config = Hl_client.Config.t`; `tick_of_mid` (5 significant figures, at most
  `6 - szDecimals` decimals); pure `Convert` functions (reject wording, order update
  statuses, order requests). `Hl_venue` takes a bare `Hl_client.Config.t` and sends
  unsigned requests (the `market-maker` binary uses it); `Hl_venue.Trading` is the same
  venue over an `hl-client` `trading` handle, signing every order and cancel when the
  handle holds a key. A `read_only` handle does not type-check as its config (a
  must-fail test pins this).
- `Params_file`: a sexp of `Mm_core.Params.t` field overrides, applied after the flags
  and checked by `Params.validate`.

The exit report ends with the loop's tick-to-order latency (count, p50, p99, max).
`scripts/e2e.sh` takes `RESPONSE_DELAY_MS` (hl-sim's `-response-delay-ms`) and reports
the most resting quotes per side, which would exceed `-levels` on a double placement;
a live-loop test runs against hl-sim with 500 ms acks, and a seeded `Bugged_venue`
injects rejects and place timeouts. CI runs `shellcheck scripts/*.sh`.

## Dependencies

- Depends on: `exchange-core`, `mm-core`, `hl-client`, `hl-protocol`, `fixed-decimal`.
- Test-only: `hl-sim`.
- Used by: `market-maker`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`, `venue-net`,
`hl-client`, `mm-core`, then `order-book`, `exchange-core-engine`, `hl-sim` for the
integration test. CI is green with these pins.

## Known gaps

- Testnet signing is checked only against an unfunded key (the exchange named the key's
  address and placed nothing); market orders and non-128-bit client ids are rejected
  locally.
- `scripts/e2e.sh` assumes the shared dune workspace.
- The README still says clearinghouse snapshots with an 11-digit `liquidationPx` are
  skipped; since `hl-protocol` decodes out-of-range values as `None` they decode.
