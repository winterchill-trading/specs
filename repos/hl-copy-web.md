# hl-copy-web

The browser frontend of the [copy-trading platform](../design/copytrading.md), a Bonsai
app compiled with js_of_ocaml ([ADR 0008](../adr/0008-bonsai-web-frontend.md)).

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-copy-web` |
| opam package | `hl-copy-web` |
| Library | `hl-copy-web` (`Api_types`, shared with `hl-copy-api`) |
| Binary | JavaScript app built with js_of_ocaml (planned) |
| Status | in progress |

## Pages (planned)

| Page | Content |
| --- | --- |
| Login | Connect the wallet (`eth_requestAccounts`), sign the challenge (`personal_sign`) |
| Leaders | Ranked table from `/leaders` with the score breakdown, sort and filter |
| Leader detail | Equity curve drawn as SVG, fills table |
| Follow | Scale mode, caps, allowlist; signs the `approveAgent` typed data (`eth_signTypedData_v4`) |
| Dashboard | Follows, positions, pnl, pause and stop |

Mock JSON fixtures under `dev/` render every page without a backend.

## Dependencies

- Depends on (planned): `hl-protocol`; opam `bonsai_web`, `js_of_ocaml`.
- Used by (planned): `hl-copy-api` (`Api_types`).

## CI pin order

Planned: `fixed-decimal`, `exchange-core`, `hl-protocol`, plus `bonsai_web` from opam.

See [design/copytrading.md](../design/copytrading.md) for the platform design.
