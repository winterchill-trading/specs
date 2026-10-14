# Opam readiness: venue-net

Kind: reference.

Audit of `winterchill-trading/venue-net` against the checklist in
[README.md](README.md), on 2026-10-14. Nothing is published, tagged or released.

## Purpose

Reconnecting websocket and one-shot HTTP/1.1 clients for Async, with certificate and
host-name checks on every TLS connection, for programs that talk to JSON and text APIs.

## Readiness

| # | Item | State | Notes |
| --- | --- | --- | --- |
| 1 | Purpose and wording | done | README, odoc and opam text describe a general Async HTTP and websocket client; keepalive docs no longer name exchanges; the macOS OpenSSL recipe is inlined instead of linking to a venue client; internal users appear once under "Used by". The package name, the `Venue_net` module, the `VENUE_NET_HTTP_RECORD` variable and the default `log_name` (`"venue-net ws"`) are still venue-flavoured; see [Package name](#package-name). |
| 2 | opam metadata | done | Generated from `dune-project`: MIT, authors `WinterChill AI`, maintainer `hello@winterchill.xyz`, source, homepage, bug reports, documentation (README anchor: no hosted odoc yet), synopsis, description, `x-maintenance-intent` through `venue-net.opam.template`. Lower bounds are the versions on our switch: Jane Street packages `>= v0.18~preview`, `cohttp >= 6.2.1`, `conduit-async >= 8.0.0`, `ipaddr >= 5.6.0`, `uri >= 4.4.0`, `yojson >= 2.2.0`; `cohttp-async` is now `{with-test}` only; `odoc {with-doc}`. `opam lint` passes. No upper bounds yet. |
| 3 | Versioning | done | `CHANGES.md` with `## Unreleased` and a `0.1.0` entry; "Releasing" in the README describes the `dune-release` flow. No tags. |
| 4 | API surface | done | `.mli` for all four modules; odoc on every public value, `@raise` on `Record.entry_of_json`, `@param timeout` on `Http.request`; top-level module doc with a worked example; `examples/http_get.ml` and `examples/ws_tail.ml` are built by `dune build` (and so by CI) and were run by hand against public endpoints. Errors are `Or_error` throughout. Naming is consistent (`connect`, `send`, `close`, `of_*`/`to_*` in `Record`). No stable types: nothing is serialized except the record-mode JSON. Interfaces open only Core and Async. |
| 5 | Portability | done (documented) | No OxCaml-only construct; blocked on package versions, see below. |
| 6 | Docs build | open | `odoc` is not on the switch, and the switch lock was held by another job during this audit, so the dry run could not be repeated; the `order-book` audit's dry run plans `odoc.3.2.0+ox2`, `crunch`, `ptime` and leaves the compiler and Core alone. `dune build @doc` is unverified. |
| 7 | Tests and CI | done | `dune build @all @runtest` green locally and in CI (run 38513593457, includes the badssl TLS test on Linux through the new `Http` path). CI workflow unchanged: `dune build` already builds `examples/`. The direct dependents (three venue clients, five feeds, `hl-leaderboard`) build unchanged, and the three venue clients' tests pass. Allocation pins (13 and 0 words per frame) and benches unchanged. |
| 8 | Known gaps | done | Three fixed (below); the rest need a decision or an external system and are explained in the README. |

Fixed in this audit:

- `Http` calls could not be cancelled: cohttp-async keeps the socket to itself and its
  `Connection.close` waits for the running request. `Http` now opens the conduit-async
  connection itself (same `Tls.config`, same IPv4 resolution as cohttp-async) and uses
  `Cohttp.Request.Private.Make` and `Cohttp.Response.Private.Make` over a small buffered
  reader to write and parse. Every call takes `?timeout`; on expiry the socket is closed.
  Tests: a stalled server sees the close and the descriptor count returns to its start;
  chunked, empty and `HEAD` responses.
- `messages` had no bound: `?max_buffered_messages` closes the connection when more
  frames than that wait unread, keeps what is buffered, and reconnects only once the
  reader has caught up (`overflows` counts it). async_websocket reads its socket without
  pushback, so closing is the only way to bound memory. The delivery hop's allocation
  pins are unchanged.
- `send` dropped frames silently while disconnected: `send_or_error` returns an `Error`.

Left open, with reasons in the README: no HTTP connection pool (needs idle-timeout and
per-host policy), no delivery guarantee for sent frames (needs application acks),
`async_ssl` needs OpenSSL 3 (external). There is no rate limiter in the library, though
earlier descriptions implied one; callers pace their own requests.

## OxCaml-only constructs

None. The sources use no modes (`local_`, `@ local`, `exclave_`), no `[@zero_alloc]`, no
unboxed types or `or_null`, no `let mutable` and no `Stdlib_upstream_compatible`.

A plain OCaml 5.2 build was tried on a stock switch (Jane Street v0.17, cohttp 5.3.1) and
fails on two package-version differences, not on language features:

| Difference | Where | Shim |
| --- | --- | --- |
| `Websocket.t` takes a type parameter only from async_websocket v0.18 | `Ws_client.Connection` | none needed once v0.18 is on the default repository; for v0.17, drop the parameter |
| `Cohttp.Request.Private` / `Cohttp.Response.Private` exist from cohttp 6 | `Http` | none: require `cohttp >= 6.2.1`, which is on the default repository |

So the library needs the Jane Street v0.18 packages, which today exist only on the
OxCaml repository.

## Dependencies

| Dependency | Use | Version on our switch | opam repository |
| --- | --- | --- | --- |
| `ocaml` | compiler | `5.2.0` via `ocaml-variants.5.2.0+ox` | OxCaml (any 5.2 works for the code) |
| `dune` | build | `3.22.2+ox` | OxCaml (upstream also has dune) |
| `core` | library | `v0.18~preview.130.106+341` | OxCaml only |
| `core_unix` | CA file lookup (`access`) | `v0.18~preview.130.106+341` | OxCaml only |
| `async` | concurrency | `v0.18~preview.130.106+341` | OxCaml only |
| `async_ssl` | TLS (OpenSSL 3) | `v0.18~preview.130.106+341` | OxCaml only |
| `async_websocket` | websocket framing | `v0.18~preview.130.106+341` | OxCaml only |
| `ppx_jane` | preprocessing | `v0.18~preview.130.106+341` | OxCaml only |
| `cohttp` | HTTP encoding and parsing | `6.2.1` | upstream |
| `conduit-async` | TCP and TLS connect | `8.0.0` | upstream |
| `ipaddr` | resolved addresses (`ipaddr.unix`) | `5.6.2` | upstream |
| `uri` | URLs | `4.4.0` | upstream |
| `yojson` | JSON helpers, record mode | `2.2.2+ox` | OxCaml variant; upstream `2.2.x` works |
| `cohttp-async` | tests (echo server) | `6.2.1` | upstream |
| `odoc` | docs | not installed (`3.2.0+ox2` planned) | OxCaml |

## Package name

The name and module come from the first users (exchange API clients); nothing in the
library is exchange-specific. Proposed neutral name: `async-net-client` (library
`async-net-client`, module `Async_net_client`), free on opam.ocaml.org and in the OxCaml
repository on 2026-10-14. It says what the package is (client side, Async, HTTP and
websocket) without claiming the `async_` underscore prefix Jane Street uses for its own
packages. Not renamed: [design/opam-publishing.md](../../design/opam-publishing.md) keeps
`venue-net`, and a rename touches ten dependent repositories. A rename would add the new
library with `Venue_net` kept as a deprecated alias module, accept both
`ASYNC_NET_CLIENT_HTTP_RECORD` and `VENUE_NET_HTTP_RECORD`, and change the default
`log_name`.

## Open questions

- Rename to `async-net-client` before 0.1.0 (cheap now, ten internal repositories to
  update), or keep `venue-net` as the plan says?
- `Http` now depends on `Cohttp.*.Private.Make`, which cohttp documents as the backend
  functor but names private. Pin `cohttp < 7`, or replace the response parser with our
  own (status line, headers, content-length and chunked bodies)?
- Split the packages: `Http` (cohttp, conduit-async) and `Ws_client` (async_websocket)
  share only `Tls`; a websocket-only user pulls cohttp today.
- Should `Http` reuse connections? Every call pays a TCP and TLS handshake; a pool needs
  idle and per-host policy.
- `Ping.t` and `response` are polymorphic variants and a tuple; switch to records or
  ordinary variants before 0.1.0, while breaking costs nothing outside the organization?

## Top blockers

1. The Jane Street `v0.18~preview` packages (`core`, `async`, `async_ssl`,
   `async_websocket`, `ppx_jane`) exist only on the OxCaml repository, and the code needs
   v0.18's polymorphic `Websocket.t`; there is no upstream target until v0.18 is released
   there, and our own repository is not created yet.
2. The name: `venue-net` describes our first users, not the library. Deciding on
   `async-net-client` (or keeping the name) has to happen before the first release,
   since a later rename means a deprecation cycle for every user.
3. Unverified docs and a soft dependency: `dune build @doc` has never run (no `odoc` on
   the switch), and `Http` relies on cohttp's `Private.Make` functors, which need an
   upper bound or a replacement before an outside release.
