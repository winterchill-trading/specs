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
| Binary | `hl-copy-api -port P -exchange-url URL [-leaderboard-url URL] [-engine-url URL] [-state-dir DIR] [-config-dir DIR] [-allow-origin O] [-builder ADDR -builder-fee N]`; master key from `HL_COPY_MASTER_KEY` |
| Status | in progress: every route below works against `hl-sim`; nothing sent to testnet yet |

## Endpoints

| Route | Behaviour |
| --- | --- |
| `POST /auth/challenge`, `POST /auth/verify` | Sign-In with Ethereum style message with a single-use five-minute nonce (in memory); EIP-191 recovery; stateless session token `<address>.<issued_ms>.<expires_ms>.<HMAC-SHA256>` |
| `POST /agent/new`, `POST /agent/approved`, `POST /agent/revoke` | Fresh secp256k1 key per offer, in memory until approved, then sealed into `Hl_copy_core.Key_store` (revoke deletes it); `approveAgent` for the named agent `hl-copy valid_until <ms>` (179 days) with its EIP-712 typed data; the signed action must match the pending offer (only `signatureChainId` may change) and recover to the session's wallet before it is posted |
| `POST /builder-fee` | The wallet's `approveBuilderFee` for the configured builder |
| `POST /follows`, `GET`/`PATCH`/`DELETE /follows/:id`, `POST /follows/:id/pause`, `/resume`, `/stop` | Follow records plus `Follower_config` files the engine watches; needs an approved agent |
| `GET /leaders`, `GET /leaders/:address` | `hl-leaderboard serve` over HTTP, reshaped into `Api_types`, cached 10 s |
| `GET /me`, `GET /ws?token=` | Account value from `clearinghouseState`, per-follow pnl and positions from the engine's `/status` (decoded leniently); the websocket pushes `me`, `follow` changes and the account's fills (`Hl_client.User_feed`) |
| `GET /healthz`, `GET /metrics` | Health and Prometheus metrics (requests by route pattern, method and status) |

Every reply carries CORS headers for the configured origins (`OPTIONS` answers
preflights); requests are rate limited per client IP with token buckets (600 per minute,
30 on `/auth/*`) and logged one line each.

## Key modules

| Module | Purpose |
| --- | --- |
| `Wallet_signature` | `personal_sign` digest, 65-byte signature parsing, recovery |
| `Session`, `Challenge` | Login tokens and challenges |
| `Venue`, `Approvals`, `Agents` | Mainnet guard, approval offers and signer checks, submission, rotation |
| `Follows` | `<state>/follows/<id>.sexp` records and `<configs>/<follower>-<leader>.sexp` engine configs (removed on stop) |
| `Leaders`, `Engine_status` | Leaderboard proxy and engine status reader |
| `Rate_limiter`, `Metrics`, `Ws_push`, `Server` | Serving |

## Dependencies

- Depends on: `hl-copy-core`, `hl-client`, `hl-protocol`, `hl-copy-api-types` (from the
  `hl-copy-web` repository), `market-data`; `cryptokit`, `cohttp-async`,
  `async_websocket`.
- Test-only: `hl-sim`, `hl-leaderboard`, `exchange-core-engine`, `venue-net`.
- Used by: `infra` (planned). The engine shares only files with it: agent keys
  through `Hl_copy_core.Key_store` and follower configs.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`, `hl-protocol`,
`parquet`, `market-data`, `price-anchor`, `venue-net`, `hl-client`, `binance-protocol`,
`mm-core`, `binance-client`, `hl-sim`, `hl-copy-core`, `hl-leaderboard`,
`hl-copy-api-types` (the `hl-copy-web` repository, that package only).

See [design/copytrading.md](../design/copytrading.md) for the platform design.
