# hl-copy-api

The HTTP API of the [copy-trading platform](../design/copytrading.md): wallet login,
agent key generation and approval, builder fee approval, follow management, and
proxies for leaders and follower status. Submits approvals to `hl-sim` or testnet only:
the server refuses any exchange URL under `hyperliquid.xyz` and builds approvals for
`hyperliquidChain: "Testnet"` only.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-api` |
| opam package | `hl-copy-api` |
| Library | `hl-copy-api` (module `Hl_copy_api`) |
| Binary | `hl-copy-api -port P -exchange-url URL [-leaderboard-url URL] [-engine-url URL] [-database-url URL] [-memory-store] [-state-dir DIR] [-config-dir DIR] [-allow-origin O] [-builder ADDR -builder-fee N]`; master key from `HL_COPY_MASTER_KEY` |
| Status | in progress: end to end on `hl-sim` (`scripts/e2e-stack.sh`, CI job `e2e-stack`); nothing sent to testnet yet |
| Tool | `tools/dev_wallet.exe` (not installed): `address`, `personal-sign`, `sign-typed-data` with a throwaway key from `HL_COPY_WALLET_KEY`; refuses Mainnet typed data |

## Endpoints

| Route | Behaviour |
| --- | --- |
| `POST /auth/challenge`, `POST /auth/verify` | Sign-In with Ethereum style message with a single-use five-minute nonce (in memory); EIP-191 recovery; stateless session token `<address>.<issued_ms>.<expires_ms>.<HMAC-SHA256>` |
| `POST /agent/new`, `POST /agent/approved`, `POST /agent/revoke` | Fresh secp256k1 key per offer, in memory until approved, then sealed into the `agents` table (revoke deletes the row and its key file); `approveAgent` for the named agent `hl-copy valid_until <ms>` (179 days) with its EIP-712 typed data; the signed action must match the pending offer (only `signatureChainId` may change) and recover to the session's wallet before it is posted |
| `POST /builder-fee` | The wallet's `approveBuilderFee` for the configured builder |
| `POST /follows`, `GET`/`PATCH`/`DELETE /follows/:id`, `POST /follows/:id/pause`, `/resume`, `/stop` | Follow records in the `follows` table plus `Follower_config` files the engine watches; needs an approved agent. `algo` (execution-algos' short form, validated by execution-algos, column `algo` from migration 0002) goes into the config; follows return `algo` and the engine's cost report as `execution`, both left out when absent |
| `GET /leaders`, `GET /leaders/:address` | `hl-leaderboard serve` over HTTP, reshaped into `Api_types`, cached 10 s; each leader carries the [leader-scoring](leader-scoring.md) summary, and the list follows the composite score when every leader has one; the detail carries the leader-scoring report, with persistence, selection statistics and integrity flags; the list carries the universe checks as `universe` |
| `GET /me`, `GET /ws?token=` | Account value from `clearinghouseState`, per-follow pnl and positions from the engine's `/status` (decoded leniently); the websocket pushes `Api_types.Ws_push` frames: `me`, `follow` changes and the account's fills (`Hl_client.User_feed`) |
| `GET /healthz`, `GET /metrics` | Health and Prometheus metrics (requests by route pattern, method and status) |

Every reply carries CORS headers for the configured origins (`OPTIONS` answers
preflights); requests are rate limited per client IP with token buckets (600 per minute,
30 on `/auth/*`) and logged one line each.

## Storage

PostgreSQL through [pg-async](pg-async.md), database `hl_copy`. `Store.S` is in domain types,
with `Store_pg` and `Store_memory` and one conformance suite over both. SQL lives only in
`store_pg.ml` and `migrations/` (embedded in the binary, applied at startup under an advisory
lock). Tables: `follows`, `agents` (the sealed key entry as `bytea`, times as nanoseconds) and
`builder_fee_approvals`. Writes are keyed and idempotent.

The engine is unchanged and reads only files. The API writes the database first, then the
follower config and key files, and rebuilds the files from the database at startup. Old sexp
state is imported once (`.imported-to-store` marker). Flags: `-database-url` (else
`DATABASE_URL` or `PG*`; TLS unless `sslmode=disable`), `-memory-store`; `-state-dir` holds
only the engine's key files.

Not persisted: session tokens (stateless HMAC), login challenges and pending agent offers.
Store failures answer 503. CI pins pg-async, installs libpq-dev and runs `postgres:18-alpine`
in both jobs; `scripts/e2e-stack.sh` takes `DATABASE_URL` or starts a throwaway cluster.

Verified on the live compose stack: migration applied, one follow and one key imported, engine
files byte-identical, the curl flow passes, and a second restart imports nothing.

## Key modules

| Module | Purpose |
| --- | --- |
| `Wallet_signature` | `personal_sign` digest, 65-byte signature parsing, recovery; `eth_signTypedData_v4` digest and signing of the approval typed data (scripts and tests) |
| `Session`, `Challenge` | Login tokens and challenges |
| `Venue`, `Approvals`, `Agents` | Mainnet guard, approval offers and signer checks, submission, rotation |
| `Follows` | `follows` table records and `<configs>/<follower>-<leader>.sexp` engine configs written from it (removed on stop) |
| `Leaders`, `Engine_status` | Leaderboard proxy and engine status reader |
| `Rate_limiter`, `Metrics`, `Server` | Serving |

## End to end

`scripts/e2e-stack.sh` starts `hl-sim` (3 leaders, 40 noise traders, strict signatures),
`hl-leaderboard` (collect, rank, serve against the simulator), the API and
`hl-copy-engine` (key store signer), walks login, agent and builder fee approval and an
`Equity_ratio` follow with a throwaway wallet, then checks `/me` positions against the
leader (one lot plus the $10 minimum order), `/ws` follow and fill pushes, pause (no
orders), stop (config removed), hl-copy-web's `smoke/live.js` against the API, and the
journal replay. The CI job `e2e-stack` checks out hl-copy-api, hl-copy-engine, hl-sim,
hl-leaderboard and hl-copy-web into one dune workspace and runs it.

## Dependencies

- Depends on: `hl-copy-core`, `execution-algos`, `hl-client`, `hl-protocol`,
  `hl-copy-api-types` (from the
  `hl-copy-web` repository), `market-data`, `pg-async`; `cryptokit`, `cohttp-async`,
  `async_websocket`.
- Test-only: `hl-sim`, `hl-leaderboard`, `exchange-core-engine`, `venue-net`.
- Used by: `infra` (planned). The engine reads only files the API writes: agent key
  files and follower configs, rebuilt from the database at startup.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`, `hl-protocol`,
`parquet`, `pg-async`, `market-data`, `backtest-stats`, `price-anchor`, `execution-algos`,
`venue-net`, `hl-client`, `binance-protocol`,
`mm-core`, `binance-client`, `hl-sim`, `hl-copy-core`, `leader-scoring`,
`leader-scoring-hl`, `hl-leaderboard`,
`hl-copy-api-types` (the `hl-copy-web` repository, that package only).

See [design/copytrading.md](../design/copytrading.md) for the platform design.
