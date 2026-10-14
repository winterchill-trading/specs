# pg-async: opam readiness

Kind: reference.

Audit of `pg-async` against the checklist in [README.md](README.md), done on 2026-10-14 at
commit `65fda87` of `winterchill-trading/pg-async`.

## Purpose

A PostgreSQL client for Async that drives libpq's asynchronous API from the scheduler, with a
pool, typed codecs and row decoders, prepared statements with binary results, transactions,
migrations, LISTEN/NOTIFY and COPY.

## Readiness

| # | Item | Status | Notes |
| --- | --- | --- | --- |
| 1 | Purpose and wording | done | The README no longer says the library is "meant for" internal services; `neobank-api` and `hl-copy-api` appear once under "Used by". No internal name in the mli files or the opam text. |
| 2 | opam metadata | done | Generated from `dune-project`: MIT, authors, maintainers, source, homepage, bug reports, documentation (README), tags, synopsis, description, `x-maintenance-intent` from a template. Bounds: `ocaml >= 5.2.0`, Core `>= v0.17.2 < v0.19~`, Async and `ppx_jane` `>= v0.17.0 < v0.19~`, `core_unix >= v0.17.1`, `postgresql >= 5.4.0 < 6.0`, `uri >= 4.4.0`, `yojson >= 2.2.0 < 4.0`, `odoc :with-doc`. `opam lint` passes. |
| 3 | Versioning | done | `CHANGES.md` with `Unreleased` (this round's additions and the one source-incompatible change) and `0.1.0`; README "Releasing" describes the dune-release flow. No tags. |
| 4 | API surface | done | `.mli` for every module, odoc on every public value (warning 50 clean), a new top-level `Pg_async` module with an overview and an example that `examples/find_user.ml` builds; `examples/quick_start.ml` is the README quick start. Errors are `(_, Pg_error.t) Result.t` throughout. `Connection.Private` is documented as unstable. |
| 5 | Portability | done | No OxCaml-only construct. Builds and passes every test on upstream OCaml 5.2.0 with Core v0.17.2, Async v0.17.0, `yojson` 3.0.0 and `postgresql` 5.4.0 (checked by hand); CI covers only the OxCaml switch. |
| 6 | Docs build | open | `odoc` is on neither switch. The OxCaml dry run plans `odoc.3.2.0+ox2`, `crunch`, `ptime` and removes the `oxcaml-odoc` guard; the upstream dry run recompiles 19 packages. Not installed. |
| 7 | Tests and CI | done | `dune test` green on both switches; dependents (`neobank-api`, `hl-copy-api`) build and pass their tests with the statement cache on by default. CI gained one step that builds `examples/`. |
| 8 | Known gaps | done | Fixed with tests: binary results and a prepared-statement cache, interval/time/inet/cidr/range/`infinity` codecs, `Listen` reconnection, `Pool` minimum size and lifetime, multi-host URLs, reaping of clusters left by killed test runs. Left open with reasons in the README: simple protocol for parameterless strings, multi-dimensional arrays, text parameters, the `Time_ns` range, cancel permissions. |

## OxCaml-only constructs

None. No `[@zero_alloc]`, `or_null`, unboxed types, `local_`, `exclave_`, modes,
`let mutable` or `Stdlib_upstream_compatible`. The only version-sensitive surface is
Core/Async, and the code uses nothing that differs between v0.17 and v0.18.

## Dependencies

| Package | Kind | Repository |
| --- | --- | --- |
| `ocaml` >= 5.2.0 | build | upstream, or OxCaml (`ocaml-variants.5.2.0+ox`) |
| `dune` >= 3.17 | build | upstream (OxCaml ships `3.22.2+ox`) |
| `core`, `core_unix`, `async`, `ppx_jane` | build | upstream v0.17, or OxCaml `v0.18~preview` |
| `postgresql` 5.4.0 (and `conf-libpq`) | build | upstream |
| `uri` >= 4.4.0 | build | upstream |
| `yojson` >= 2.2.0 | build | upstream (OxCaml ships `2.2.2+ox`) |
| `odoc` | doc | upstream or OxCaml (`3.2.0+ox2`) |
| PostgreSQL server binaries (`initdb`, `pg_ctl`) | test (system) | none: `conf-postgresql` only brings `libpq-dev` |

## Package name

`pg-async` (library `pg-async`, module `Pg_async`; sub-library `pg-async.testing`,
module `Pg_test`; binary `pg-async`). The name is free upstream and in the OxCaml
repository. Neighbours: `postgresql` (the bindings it uses), `pgx`/`pgx_async` (pure
OCaml, upstream, pinned to `ocaml < 5.0`) and Jane Street's `postgres_async` (pure OCaml,
OxCaml repository); the README should say how it differs from `postgres_async` before a
release.

## Open questions

- Upstream first? The library is the one audited so far that needs no OxCaml at all, so it
  could go to opam-repository directly instead of waiting for our own repository.
- The test suite needs PostgreSQL server binaries. On opam CI (`-t`) they are absent and
  every test that starts a cluster fails; options are skipping such tests when `initdb` is
  missing (with a flag CI sets to require them) or a `conf-postgresql-server`-style depext.
- Should `pg-async.testing` become its own package so that users who only want the client
  do not install test helpers? It costs nothing at runtime today (same package, no extra
  dependency).
- Should an upstream OCaml 5.2/Core v0.17 job be added to CI, now that the build works there?
- The statement cache is on by default (256 per connection). Behind PgBouncer before 1.21 in
  transaction mode users must set `statement_cache_size=0`; is on-by-default the right
  choice for a public release?

## Top blockers to publishing

1. Tests need a running PostgreSQL toolchain (`initdb`, `pg_ctl`), which opam CI does not
   provide, so `opam install -t pg-async` fails there until the cluster tests can skip or a
   depext supplies the server.
2. `odoc` is not installed on any of our switches, so `dune build @doc` has never run.
3. No CI job proves the upstream (OCaml 5.2, Core v0.17) build; it was verified by hand once,
   and an upstream submission would be the first package from the organization, with the
   release venue question (upstream or our own repository) still open.
