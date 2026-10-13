# ADR 0008: Bonsai web frontend in OCaml instead of TypeScript

Status: accepted

## Context

The copy-trading platform needs a browser frontend: wallet login, a leader table and
detail pages, the follow form that has the user sign `approveAgent`, and a dashboard
([design/copytrading.md](../design/copytrading.md)). Every other repository in the
organization is OxCaml on the Jane Street libraries
([ADR 0001](0001-oxcaml-and-janestreet-stack.md)), and the frontend talks to
`hl-copy-api` in JSON whose shapes must stay in step with the server.

The usual choice is TypeScript with a framework, with the API types written twice (or
generated) and a second toolchain (node, a bundler, a linter) in CI. The Jane Street
stack has its own answer: Bonsai, an incremental UI library for OCaml compiled to
JavaScript with js_of_ocaml, built on `virtual_dom`.

## Decision

`hl-copy-web` is a Bonsai app (`bonsai_web`) compiled with js_of_ocaml. It owns the
`Api_types` module (sexp and JSON derivations) that `hl-copy-api` depends on, so a
request or response shape is one OCaml type checked on both sides. The browser wallet
(`window.ethereum`: `eth_requestAccounts`, `personal_sign`, `eth_signTypedData_v4`) is
reached through a small hand-written binding. Mock JSON fixtures let every page render
without a backend.

## Consequences

- One language, one build (dune), one CI action for the whole platform; an API change
  that breaks the frontend fails to compile.
- `bonsai_web` and js_of_ocaml become opam dependencies of one repository; they must
  install on the shared `5.2.0+ox` switch without moving `core`, which constrains the
  versions available.
- Fewer people know Bonsai than React, and its ecosystem has few ready-made
  components: charts are drawn as SVG through `virtual_dom`, and wallet support is
  limited to what the binding covers (no WalletConnect library).
- The JavaScript bundle is larger than a hand-written TypeScript app; acceptable for a
  dashboard.
