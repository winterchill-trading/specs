# hl-copy-engine

The mirroring service of the [copy-trading platform](../design/copytrading.md): one
`Follower` per follow subscribes to its leader, keeps `Hl_copy_core.Mirror` state,
and sends IOC orders signed by the follower's agent key; an `Engine` supervises the
followers from a watched config directory. Refuses mainnet exchange URLs.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-engine` |
| opam package | `hl-copy-engine` |
| Library | `hl-copy-engine` (module `Hl_copy_engine`) |
| Binary | `hl-copy-engine` (planned) |
| Status | in progress |

## Key modules (planned)

| Module | Purpose |
| --- | --- |
| `Follower` | Leader `userFills` feed, periodic `clearinghouseState` resync of both accounts (default 30 s), plan execution through `hl-client`'s agent trading handle, reject handling, pause, resume and stop with cancel-all; every input journaled in Bin_prot for deterministic replay |
| `Engine` | Supervises N followers from a directory of `Follower_config` files with hot reload; `/metrics` (orders, fills, rejects, leader-to-follower lag, slippage, pnl) and `/status` |

`scripts/e2e-sim.sh` (planned) runs `hl-sim -leaders N`, the engine and one follower
for 60 s.

## Dependencies

- Depends on (planned): `hl-copy-core`, `hl-client`, `hl-protocol`, `market-data`, `venue-net`.
- Test-only (planned): `hl-sim`.
- Used by (planned): `hl-copy-api` (reads `/status`), `infra`.

## CI pin order

Planned: `fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`,
`venue-net`, `hl-client`, `hl-copy-core`, then `order-book`, `exchange-core-engine`,
`hl-sim` for tests.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
