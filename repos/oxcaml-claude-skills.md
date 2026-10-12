# oxcaml-claude-skills

Claude Code skills and a running gotchas log collected while building the organization's
repositories with OxCaml and the Jane Street library stack. Installable as a Claude Code
plugin (`.claude-plugin/plugin.json`).

| | |
| --- | --- |
| Repository | `winterchill-trading/oxcaml-claude-skills` |
| opam package | none (Markdown only) |
| Status | done (living log) |

## Contents

| Path | Covers |
| --- | --- |
| `skills/oxcaml-setup` | Creating and maintaining the `5.2.0+ox` opam switch, CI, depexts |
| `skills/oxcaml-modes` | Verified `local_`/`exclave_`/`global_`/`@ local` patterns with compiler error texts |
| `skills/async-http-websocket` | cohttp-async and async_websocket servers and clients, same-port upgrades |
| `skills/janestreet-ocaml-style` | Base/Core/Async style, ppx_jane, expect tests |
| `GOTCHAS.md` | Dated, append-only log; stable entries are promoted into skills |
| `README.md` | Install instructions and the ecosystem map |

## Dependencies

None. Every repository's agents read `GOTCHAS.md` and the skills before starting work.

## CI

None.

## Known gaps

- The README's ecosystem map lists 16 repositories and omits `parquet`, `market-data`,
  `market-recorder`, `infra` and `specs`; [overview.md](../overview.md) is the complete
  map.
