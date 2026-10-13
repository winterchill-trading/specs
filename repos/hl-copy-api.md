# hl-copy-api

The HTTP API of the [copy-trading platform](../design/copytrading.md): wallet login,
agent key generation and approval, builder fee approval, follow management, and
proxies for leaders and follower status. Submits approvals to `hl-sim` or testnet only.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-api` |
| opam package | `hl-copy-api` |
| Library | `hl-copy-api` (module `Hl_copy_api`) |
| Binary | `hl-copy-api` (planned) |
| Status | in progress |

## Endpoints (planned)

| Route | Behaviour |
| --- | --- |
| `POST /auth/challenge`, `POST /auth/verify` | EIP-191 challenge and signature check; HMAC-signed, expiring session token |
| `POST /agent/new`, `POST /agent/approved` | Generate and encrypt an agent key (master key from `HL_COPY_MASTER_KEY`), return the `approveAgent` typed data, submit the user's signature |
| `POST /builder-fee` | Submit the user's `approveBuilderFee` signature |
| `POST /follows`, `GET`/`PATCH`/`DELETE /follows/:id` | Follower configs the engine watches; pause and resume |
| `GET /leaders`, `GET /leaders/:address` | From `hl-leaderboard serve` |
| `GET /me`, `/ws` | Positions, pnl and follow status from the engine; pushed updates |
| `GET /healthz`, `GET /metrics` | Health and Prometheus metrics |

## Dependencies

- Depends on (planned): `hl-copy-core`, `hl-client`, `hl-protocol`, `hl-copy-web`
  (`Api_types`), `hl-leaderboard`, `venue-net`, `market-data`.
- Test-only (planned): `hl-sim`.

## CI pin order

Planned: `fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `hl-protocol`,
`venue-net`, `hl-client`, `hl-copy-core`, `hl-copy-web`, `hl-leaderboard`, then
`order-book`, `exchange-core-engine`, `hl-sim` for tests.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
