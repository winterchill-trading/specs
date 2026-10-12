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
| `skills/oxcaml-modes` | Verified `local_`/`exclave_`/`global_`/`@ local`, `@ unique` and `borrow_` patterns with compiler error texts; `examples/` is a dune project whose tests pin zero heap words and the rejected programs' errors |
| `skills/async-http-websocket` | cohttp-async and async_websocket servers and clients, same-port upgrades |
| `skills/janestreet-ocaml-style` | Base/Core/Async style, ppx_jane, expect tests; an agent workflow section (plan review, signatures and types first, failing test before a fix) and the `Obj` ban |
| `scripts/check-obj-magic.sh` | Fails on `Obj.magic`, `Obj.repr` or `Obj.obj` outside `.obj-magic-allowlist`; every org repository passes with no allowlist |
| `GOTCHAS.md` | Dated, append-only log; stable entries are promoted into skills |
| `README.md` | Install instructions and the ecosystem map |

Each skill opens with outcomes, 3-5 reference modules from the org repositories and
short exercises for checking a fresh session against it. `GOTCHAS.md` records, among
others, that dune's cache does not share artifacts across different `DUNE_BUILD_DIR`s,
the `X_unix` renames, `Bigstring_unix.write ?min_len`, and that perf, bpftrace and
magic-trace do not run on macOS.

## Dependencies

None. Every repository's agents read `GOTCHAS.md` and the skills before starting work.

## CI

`ci.yml`: shellcheck on `scripts/*.sh`, `scripts/test-check-obj-magic.sh`, the
`Obj` check on the repository itself, and a build and test of the `oxcaml-modes`
examples on the `5.2.0+ox` switch with the `ox` opam repository pinned to a commit.

## Known gaps

- The README's ecosystem map lists the repositories in one table but has no dependency
  graph; [overview.md](../overview.md) is the complete map.
- No other repository runs `check-obj-magic.sh` in its CI yet.
