# hl-leaderboard

Leader discovery for the [copy-trading platform](../design/copytrading.md): pulls the
Hyperliquid leaderboard and each candidate's fills, account state and portfolio curves
(read only, no keys), scores them with `Hl_copy_core.Score`, and serves the ranked list
as JSON.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-leaderboard` |
| opam package | `hl-leaderboard` |
| Library | `hl-leaderboard` (module `Hl_leaderboard`) |
| Binary | `hl-leaderboard collect`, `rank`, `serve` |
| Status | done |

## Commands

| Command | Behaviour |
| --- | --- |
| `collect -out DIR [-network mainnet\|testnet\|local] [-base-url URL] [-top N] [-windows W,..] [-min-account-value USD] [-include-roles R,..] [-lookback-days D] [-max-pages P] [-weight-per-minute W]` | Fetches the stats-host leaderboard (hl-sim: `POST /info {"type":"leaderboard"}`), picks the top N by pnl per window among accounts whose `userRole` is accepted (default `user`: vaults, sub-accounts and agents are skipped and the next row takes their place), then per candidate walks `userFillsByTime` forward (2000 per page, de-duplicated by `(tid, oid)`), takes one `clearinghouseState`, one `portfolio` and the new `userFunding` pages (both optional), then the `l2Book` of the 25 coins the candidates trade most and `metaAndAssetCtxs` (optional); appends every response as a `<recv_ts> <body>` line; rebuilds `leaders.parquet` and `fills.parquet`. Resumable through `_manifest/progress.sexp` |
| `rank -in DIR -out FILE [-min-trades N] [-no-scoring]` | Scores every collected leader and writes the ranked list with the role, the component breakdown, `curve_source` and `truncated`; leaders under `-min-trades` round trips (default 5, `Rank.default_min_trades`) are listed unranked. Also writes a [leader-scoring](leader-scoring.md) report per leader to `reports/<address>.json` (first) and a `scoring` summary into each entry |
| `serve -port P -dir DIR [-leaders FILE]` | `GET /leaders[?limit=N]`, `GET /leaders/<address>` (entry, fills newest first, equity curve, positions, leader-scoring `report`), `GET /scoring/metrics` (the metric catalogue), `GET /health`; CORS `*` |

## Key modules

| Module | Purpose |
| --- | --- |
| `Board` | Candidate selection over `Hl_protocol.Leaderboard` rows |
| `Roles` | `userRole` filter over the candidate walk; an address whose role request fails after retries is excluded on every network |
| `Api` | Read-only client returning raw bodies, through one `Rate_limit` bucket, retrying 429/5xx with backoff |
| `Rate_limit` | Token bucket (1200 weight per minute) and the documented request weights |
| `Fill_pages` | Forward `userFillsByTime` walk |
| `Portfolio` | `portfolio` decoding (not in hl-protocol) and the deposit-free equity curve of a window |
| `Equity_curve` | Fallback curve walked back from the account value through fills |
| `Raw_log`, `Layout`, `Progress`, `Dataset` | Raw logs, directory layout, resumable manifest, loading a directory back |
| `Parquet_out` | `leaders.parquet`, `fills.parquet` (via `parquet`) |
| `Rank` | Score input (perp fills, synthetic opens for positions held at the start of the history, `month` portfolio curve), ordering, JSON |
| `Scoring` | [leader-scoring](leader-scoring.md) reports from the raw logs, ranked across the collected leaders; summaries for the ranking file |
| `Server` | The JSON API |

## Directory layout

```text
raw/leaderboard/<YYYY-MM-DD>T<HH>-<MM>.ndjson
raw/fills/<address>.ndjson
raw/state/<address>.ndjson
raw/portfolio/<address>.ndjson
raw/role/<address>.ndjson
raw/funding/<address>.ndjson
raw/books/<coin>.ndjson
raw/market/meta_and_asset_ctxs.ndjson
reports/<address>.json
_manifest/progress.sexp, _manifest/candidates.json
leaders.parquet, fills.parquet
```

## Tests

Expect tests on mainnet fixtures (leaderboard rows, fills, `clearinghouseState`,
`portfolio`), the rate limiter on a synthetic clock, fill paging across millisecond
boundaries, and `collect`/`rank`/`serve` end to end against an in-process stand-in for the
stats host and `/info` (429 retry, failed address, resume, restart, a vault and a
sub-account skipped).
`scripts/sim-e2e.sh` runs the flow against a real hl-sim with noise traders.

## Dependencies

- Depends on: `hl-client`, `hl-protocol`, `market-data`, `parquet`, `venue-net`,
  `hl-copy-core`, [leader-scoring](leader-scoring.md) (`leader-scoring`,
  `leader-scoring-hl`).
- Used by: `hl-copy-backtest` (in [hl-copy-core](hl-copy-core.md)), which reads
  collection directories through `Dataset` and `Rank`; planned: `hl-copy-api`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`, `venue-net`,
`hl-client`, `hl-copy-core`, `leader-scoring`, `leader-scoring-hl` (same repository).
hl-sim is used only by `scripts/sim-e2e.sh`, outside CI.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
