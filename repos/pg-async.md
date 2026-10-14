# pg-async

Non-blocking PostgreSQL access for Async, over libpq: connections, a bounded pool,
parameterized queries with typed codecs, a per-connection prepared-statement cache with
binary results, transactions with retries, ordered migrations, LISTEN/NOTIFY, COPY and
Prometheus metrics. It is generic (no application types) and is the application-state store
of `neobank-api` and `hl-copy-api` ([ADR 0009](../adr/0009-postgres-replaceable-store.md)).
Opam readiness: [research/opam-readiness/pg-async.md](../research/opam-readiness/pg-async.md).

| | |
| --- | --- |
| Repository | `winterchill-trading/pg-async` |
| opam package | `pg-async` |
| Library | `pg-async` (modules `Connection`, `Pool`, `Query`, `Param`, `Row`, `Type`, `Tx`, `Migrate`, `Listen`, `Copy`, `Metrics`, `Pg_error`, `Config`) |
| Testing library | `pg-async.testing` (`Pg_test`: throwaway clusters) |
| Binaries | `pg-async` (`check`, `migrate`, `status`, `query`); `bench/pg_async_bench.exe` |
| Status | done: library, CLI and tests are in place; CI green |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | `of_env` (`DATABASE_URL`, else `PG*`) and `of_url` (several hosts allowed); TLS `Verify_full` by default; statement and query timeouts; `statement_cache_size`; the password never prints |
| `Connection` | One session driven by libpq's non-blocking API from Async's scheduler; calls on one connection are ordered; statements with parameters are prepared once and cached (LRU, re-prepared after DDL or `DEALLOCATE`); cancel through a second session |
| `Pool` | Bounded, with a wait limit, a health check, replacement of dead backends, rollback of a transaction left open at release, an optional minimum size and maximum connection lifetime |
| `Query`, `Param`, `Row`, `Type` | Parameters only, never spliced into SQL; codecs for int, int32, int64, string, bool, float, `Time_ns`, `Date`, bytea, jsonb, uuid, numeric, interval, time, inet, cidr, ranges, `infinity`, nullable, arrays and custom types, with binary decoders for all but numeric and custom; applicative row decoders whose errors name the row and column; results of cached statements come back in binary when every decoded column supports it |
| `Tx` | Isolation levels; `with_transaction` retries serialization failures (40001) and deadlocks (40P01) with backoff; a silent-rollback COMMIT is reported as 25P02 |
| `Migrate` | Ordered SQL files applied in one transaction under an advisory lock; checksums; refuses changed, missing or out-of-order files |
| `Listen` | LISTEN/NOTIFY delivered into an Async pipe; optionally reconnects and listens again, with an `on_reconnect` hook |
| `Copy` | `COPY ... FROM STDIN` from a pipe of rows |
| `Metrics` | Per-label query counts, errors and latency histograms, with Prometheus output |
| `Pg_error` | Server SQLSTATE, detail, constraint and table, with `is_unique_violation` and `is_retryable_transaction_failure` |

Every call returns `('a, Pg_error.t) Result.t Deferred.t`.

## Why libpq and not pgx

`pgx`, the pure-OCaml protocol implementation, pins `ocaml < 5.0` and `core < v0.16` and does
not build on the OxCaml switch. The `postgresql` bindings (5.4.0) install on it and expose
the whole of libpq: TLS through the system OpenSSL, SCRAM, `.pgpass`, service files,
multi-host failover and the non-blocking API. The cost is a C dependency (`libpq-dev`, or
Homebrew `postgresql@18`). Jane Street's own `postgres_async` (pure OCaml, in the OxCaml
opam repository) is the closest alternative.

## How it stays non-blocking

- Connect: the host name is resolved on Async's thread pool and the address is passed as
  `hostaddr` (TLS still checks the name); `PQconnectPoll` is driven by `Fd` readiness.
- Queries: `PQsendPrepare` on first use, then `PQsendQueryPrepared` (or `PQsendQuery`
  without parameters), then `PQflush` and `PQconsumeInput` as the socket becomes ready.
- Async watches a `dup` of libpq's socket, never libpq's own descriptor, because libpq
  closes its socket itself when the server hangs up.
- Timeouts cancel with `pg_cancel_backend` from a short-lived second session.
- Server notices are dropped inside libpq, since a callback would run inside the bindings'
  blocking sections.

Only DNS runs in a thread; nothing else in the library blocks the scheduler.

## Tests

Tests run against throwaway clusters (`Pg_test.shared`: one per test process, a fresh database
per test) started with `initdb` and `pg_ctl`, `fsync=off`. Coverage: queries, typed
parameters and decode errors; client and server timeouts; codec round trips in memory and
through the server; transactions with a real serialization conflict between two sessions;
pool limits and replacement; migrations, including two concurrent migrators; LISTEN/NOTIFY
ordering and reconnection; prepared statements (binary from the second run, eviction,
re-prepare after DDL, `DEALLOCATE` and `DISCARD ALL`) and every codec compared between text
and binary; pool minimum size and lifetime; COPY of 5000 awkward rows and a failed load; TLS
modes against a test CA (right and wrong CA and host name); multi-host failover. Clusters left
by a killed test process are reaped by the next `Pg_test.start` (owner pid file).

## Bench

Apple M3 Max, dev profile, `fsync=off`: sequential `Connection` select 36 246 ops/s with the
statement cache (29 720 without, 31 065 for blocking unprepared libpq); `Pool(8)` with 64
callers about 80 000 selects/s and 78 629 inserts/s; a 1000-row select decodes 2.23 million
rows/s in binary against 1.75 million in text; COPY about 0.94 to 1.16 million rows/s.

## CI pin order

No org dependencies, so CI pins nothing. CI apt-installs `libpq-dev` and `postgresql` before
the OxCaml setup action, then runs `dune build` and `dune test`.

## Dependencies

- Depends on: none in the organization. External: `core`, `core_unix`, `async`,
  `postgresql`, `yojson`, `uri`, `ppx_jane`; system `libpq` and PostgreSQL server binaries for
  tests.
- Used by: `neobank-api` and `hl-copy-api` (store implementations and their tests).

## Known gaps

Fixed on 2026-10-14: binary results and a prepared-statement cache; interval, time, inet,
cidr, range and `infinity` codecs; `Listen` reconnection; `Pool` minimum size and maximum
lifetime; multi-host URLs; clusters left by killed test runs. Still open, each needing a
design decision or an outside change:

- A query with no parameters goes through the simple protocol (not prepared, text results),
  so such a string may hold several statements; changing it would break callers that rely
  on that.
- Arrays are one-dimensional with default bounds; multi-dimensional arrays need an OCaml
  representation that has not been chosen.
- Parameters are sent as text; only results use the binary format.
- `Time_ns` covers roughly 1823 to 2116.
- Cancelling needs the same role as the session (or `pg_signal_backend`): `PQcancel` would
  need a change in the `postgresql` bindings.
