# hl-copy-web

The browser frontend of the [copy-trading platform](../design/copytrading.md), a Bonsai
app compiled with js_of_ocaml ([ADR 0008](../adr/0008-bonsai-web-frontend.md)), and the
owner of `Api_types`, the wire types of the HTTP API that
[hl-copy-api](hl-copy-api.md) serves.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-web` |
| opam packages | `hl-copy-api-types` (library only), `hl-copy-web` (the app) |
| Library | `hl-copy-api-types` (module `Api_types`) |
| Binary | `bin/main.bc.js`, installed as `share/hl-copy-web/{index.html,main.js}` |
| Status | in progress: every page runs on mock data and against a fake API in tests; not yet run against `hl-copy-api` |

## Api_types

`api/api_types.mli` is the contract between the two repositories. The package depends
only on `core`, `ppx_jane`, `ppx_yojson_conv` and `yojson`, so the server links it
without the web stack.

| Request | Body | Reply |
| --- | --- | --- |
| `GET /leaders` | | `Leaders_response` (`Leader` rows with `Score_breakdown` and `Window_pnl`) |
| `GET /leaders/<address>` | | `Leader_detail` (equity curve, fills, positions) |
| `POST /auth/challenge` | `Auth.Challenge_request` | `Auth.Challenge` |
| `POST /auth/verify` | `Auth.Verify_request` (`address`, `nonce`, `signature`) | `Auth.Session` |
| `GET /me` | | `Me` (account, `Agent_status`, follows) |
| `POST /agent/new` | `{}` | `Agent_offer` (`Approve_agent`, optional `Approve_builder_fee`) |
| `POST /agent/approved` | `Agent_approval` (the action as signed, signature) | `Agent_status` |
| `POST /builder-fee` | `Builder_fee_approval` | `Agent_status` |
| `POST /follows` | `Follow_request` (`leader`, `Scale_mode`, `Caps`) | `Follow` |
| `PATCH /follows/<id>` | `Follow_update` (`running` or `paused`) | `Follow` |
| `DELETE /follows/<id>` | | `Follow` (stopped) |

Errors carry `Api_error` (`{"error": "..."}`); everything after login sends
`Authorization: Bearer <token>`. Conventions: timestamps and nonces are `Time_ms.t`, a
`float` of milliseconds encoded as a JSON integer, because js_of_ocaml's `int` is 32
bits; money is USD `float`; `Address.t` is validated and lowercased; records accept
unknown fields and optional fields accept `null`. `Approve_agent.typed_data` and
`Approve_builder_fee.typed_data` build the EIP-712 JSON for `eth_signTypedData_v4`
(domain `HyperliquidSignTransaction`, the field lists of the Python SDK).

## Pages

| Route | Content |
| --- | --- |
| `#/leaders` | Ranked table with every score component, sort by any column, filter by text, minimum score, maximum drawdown, minimum trades |
| `#/leader/<address>` | Headline figures, window pnl, SVG equity curve, positions, recent fills |
| `#/follow/<address>` | Scale mode, caps and allowlist with validation; when the agent is missing or expired, the `approveAgent` (and optional `approveBuilderFee`) typed data shown in full before the wallet signs |
| `#/dashboard` | Account, agent status, one card per follow with pnl, positions, pause, resume, stop |
| `#/login` | `eth_requestAccounts`, then `personal_sign` of the challenge |

The wallet binding is gen_js_api over EIP-1193 (`ethereum/eip1193.mli`). The page
replaces the offer's `signature_chain_id` with the wallet's `eth_chainId` before signing,
because wallets refuse typed data for another chain.

## Modules

| Directory | Library | Purpose |
| --- | --- | --- |
| `api/` | `hl-copy-api-types` | `Api_types` |
| `model/` | `copy_web_model` (private) | `Route`, `Format`, `Leader_table`, `Chart`, `Follow_form`, `Agent_check`, `Mock_state`; pure, tested natively |
| `ethereum/` | `ethereum` (private) | `Eip1193` (generated binding), `Ethereum` (deferred calls) |
| `ui/` | `copy_web_ui` (private) | `Backend` (live HTTP with any method, or mock fixtures), `Wallet`, `Remote`, `Nav`, the pages, `App` |

## Tests

Expect tests cover `Api_types` (JSON shapes, typed data, every `dev/` fixture) and the
model. Two node smoke tests run the compiled app with a minimal fake DOM: `smoke/run.js`
walks every page on mock data with a fake wallet (12 steps), and `smoke/live.js` runs it
with `?api=` against an in-memory fake of `hl-copy-api` and checks the method, path,
bearer token and body of each request above.

## Dependencies

- Depends on: opam `bonsai_web`, `virtual_dom`, `js_of_ocaml`, `gen_js_api`, `ojs`; no
  org package (the web app does not use `hl-protocol`).
- Used by (planned): `hl-copy-api` (`hl-copy-api-types`).

## CI pin order

No sibling pins. `bonsai_web` is an opam dependency, installed and cached by `ox-setup`;
node comes from `actions/setup-node` for the smoke tests. The opam file keeps `dune`
below 3.23, because `bonsai_web` does not build under upstream dune 3.24 (its CSS inliner
gets `./`-prefixed paths) and a fresh switch would otherwise pick it. Cold CI run: 24 min
50 s, of which 23 min 44 s is `ox-setup`.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
