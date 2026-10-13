# hl-leaderboard

Leader discovery for the [copy-trading platform](../design/copytrading.md): pulls the
Hyperliquid leaderboard and each candidate's fills and account state (read only, no
keys), scores them with `Hl_copy_core.Score`, and serves the ranked list as JSON.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-leaderboard` |
| opam package | `hl-leaderboard` |
| Library | `hl-leaderboard` (module `Hl_leaderboard`) |
| Binary | `hl-leaderboard collect`, `rank`, `serve` (planned) |
| Status | in progress |

## Commands (planned)

| Command | Behaviour |
| --- | --- |
| `collect -out DIR [-network mainnet\|testnet\|local] [-base-url URL]` | Fetches `stats-data.hyperliquid.xyz/<Network>/leaderboard`, then `userFillsByTime` (paged) and `clearinghouseState` for the top N per window; writes raw `<recv_ts> <body>` lines, `leaders.parquet` and `fills.parquet`; paced under the 1200 weight per minute limit, resumable |
| `rank -in DIR -out leaders.json` | Scores every collected leader and writes the ranked list with the component breakdown |
| `serve -port P` | `/leaders` and `/leaders/<address>` (fills, equity curve) for `hl-copy-api` and `hl-copy-web` |

## Dependencies

- Depends on (planned): `hl-client`, `hl-protocol`, `market-data`, `parquet`, `hl-copy-core`.
- Test-only (planned): `hl-sim` (its `leaderboard` info request).
- Used by (planned): `hl-copy-api`.

## CI pin order

Planned: `fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`,
`venue-net`, `hl-client`, `hl-copy-core`, then `order-book`, `exchange-core-engine`,
`hl-sim` for tests.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
