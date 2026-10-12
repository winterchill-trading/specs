# strace-ui, Bonsai_term, and the TUI renaissance

- Source: <https://blog.janestreet.com/strace-ui-bonsai-term-and-the-tui-renaissance/>
- Published: 2026-05-26
- Kind: blog post

## Summary

- strace output is hard to explore: hard to follow subprocesses and threads, and
  filtering needs a rerun with flags. strace-ui (open source) makes it an interactive
  terminal UI.
- Features: short labels for PIDs and threads, formatted structs, hexdumps for buffers;
  hide any syscall after the fact (handy for noisy Async processes full of futex and epoll
  calls); jump to or filter by file descriptor, with best-effort tracking of FD reuse across
  forks; man pages on a key; hostnames instead of IPs in decoded socket descriptors.
- A developer had wanted such a tool since 2017; with Bonsai_term and an agent a working
  prototype took under ten minutes.
- Bonsai is the firm's Elm-inspired UI library: components are pure, composable state
  machines, and incremental computation avoids recomputing any value (not only the view)
  until needed. State and incrementality primitives compose a la carte, and frontend and
  backend share OCaml types.
- Bonsai's core is UI-agnostic. Bonsai_web targets browsers via js_of_ocaml, and
  Bonsai_term targets terminals, replacing older curses-based apps.
- Bonsai_term started in 2024 as a hobby project (a manga reader using the kitty graphics
  protocol), was productionized from April 2025, and took off with agentic coding. The
  firm's own vendor-neutral agent harness (AIDE) is a Bonsai_term app and both showcase and
  source of a component library.
- Terminal apps won over IDEs for agents through speed, simplicity and ubiquity, and
  models proved surprisingly good at Bonsai_term despite OxCaml-only features.
- Its test framework renders the app as text in expect tests, so walking through the app
  and printing "screenshots" makes behavior changes visible as diffs; agents can run these
  tests and read the output, closing the loop.
- Agents struggled with what tests do not show (scroll, filter and render performance)
  and with FD tracking, where most remaining development time went.
- A handful of new TUIs appear daily: a time-travel debugger for a trading system, Linux
  admin automation, CI monitoring, agent session and eval managers, deployment tools, log
  explorers, terminal charting. Two are public: proctopus (multi-process apps) and dissect
  (binary bloat).
- Unlike Bonsai_web, which needs JavaScript-compatible dependencies, a TUI is a normal
  native program that can link any library.

## Relevance to us

- **Testing and simulation:** text-rendered "screenshot" expect tests let agents verify
  UI work themselves. **Action:** in [market-maker](../../../repos/market-maker.md),
  prototype a read-only Bonsai_term status screen (per-venue BBO, own quotes, inventory,
  reconnect count) fed by a scripted state stream, with one expect test printing the
  rendered screen.
- **Research tooling:** a TUI over recorded data is a cheap first viewer. **Action:** add a
  `market-data` subcommand prototype that pages through one `Event_log` file in a
  Bonsai_term view, filtering by stream, in [market-data](../../../repos/market-data.md).
- **Build and deploy:** proctopus manages multi-process local setups. **Action:** try it
  for the local stack of three simulators plus `market-maker` and `market-recorder`, and
  note the result next to the compose stack in [infra](../../../repos/infra.md).
- **OCaml practice:** strace-ui hides Async's futex and epoll noise and follows FDs.
  **Action:** add a "debugging sockets with strace-ui" tip to
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).

Tags: `ui`, `expect-tests`, `ai-tools`, `observability`
