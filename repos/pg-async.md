# pg-async

Non-blocking PostgreSQL access for Async on OxCaml, over libpq: connections, a bounded pool,
parameterized queries with typed codecs, transactions with retries, ordered migrations,
LISTEN/NOTIFY, COPY and Prometheus metrics. It is generic (no application types) and is the
application-state store planned for `neobank-api` and `hl-copy-api`
([ADR 0009](../adr/0009-postgres-replaceable-store.md)).

| | |
| --- | --- |
| Repository | `winterchill-trading/pg-async` |
| opam package | `pg-async` |
| Library | `pg_async` (modules `Connection`, `Pool`, `Query`, `Param`, `Row`, `Type`, `Tx`, `Migrate`, `Listen`, `Copy`, `Metrics`, `Pg_error`, `Config`) |
| Testing library | `pg_async.testing` (`Pg_test`: throwaway clusters) |
| Binaries | `pg-async` (`check`, `migrate`, `status`, `query`); `bench/pg_async_bench.exe` |
| Status | done: library, CLI and tests are in place; CI green |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | `of_env` (`DATABASE_URL`, else `PG*`) and `of_url`; TLS `Verify_full` by default; statement and query timeouts; the password never prints |
| `Connection` | One session driven by libpq's non-blocking API from Async's scheduler; calls on one connection are ordered; cancel through a second session |
| `Pool` | Bounded, with a wait limit, a health check, replacement of dead backends, and rollback of a transaction left open at release |
| `Query`, `Param`, `Row`, `Type` | Parameters only, never spliced into SQL; codecs for int, int32, int64, string, bool, float, `Time_ns`, `Date`, bytea, jsonb, uuid, numeric, nullable, arrays and custom types; applicative row decoders whose errors name the row and column |
| `Tx` | Isolation levels; `with_transaction` retries serialization failures (40001) and deadlocks (40P01) with backoff; a silent-rollback COMMIT is reported as 25P02 |
| `Migrate` | Ordered SQL files applied in one transaction under an advisory lock; checksums; refuses changed, missing or out-of-order files |
| `Listen` | LISTEN/NOTIFY delivered into an Async pipe |
| `Copy` | `COPY ... FROM STDIN` from a pipe of rows |
| `Metrics` | Per-label query counts, errors and latency histograms, with Prometheus output |
| `Pg_error` | Server SQLSTATE, detail, constraint and table, with `is_unique_violation` and `is_retryable_transaction_failure` |

Every call returns `('a, Pg_error.t) Result.t Deferred.t`.

## Why libpq and not pgx

`pgx`, the pure-OCaml protocol implementation, pins `ocaml < 5.0` and `core < v0.16` and does
not build on the OxCaml switch. The `postgresql` bindings (5.4.0) install on it and expose
the whole of libpq: TLS through the system OpenSSL, SCRAM, `.pgpass`, service files,
multi-host failover and the non-blocking API. The cost is a C dependency (`libpq-dev`, or
Homebrew `postgresql@18`) and the text protocol.

## How it stays non-blocking

- Connect: the host name is resolved on Async's thread pool and the address is passed as
  `hostaddr` (TLS still checks the name); `PQconnectPoll` is driven by `Fd` readiness.
- Queries: `PQsendQueryParams`, then `PQflush` and `PQconsumeInput` as the socket becomes
  ready.
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
ordering; COPY of 5000 awkward rows and a failed load; TLS modes against a test CA (right and
wrong CA and host name).

## Bench

Apple M3 Max, dev profile, `fsync=off`: sequential `Connection` select about 30 000 ops/s, about
1 us more per statement than blocking libpq; `Pool(8)` with 64 callers 82 575 selects/s and
79 002 inserts/s; COPY 1.16 million rows/s.

## CI pin order

No org dependencies, so CI pins nothing. CI apt-installs `libpq-dev` and `postgresql` before
the OxCaml setup action, then runs `dune build` and `dune test`.

## Dependencies

- Depends on: none in the organization. External: `core`, `core_unix`, `async`,
  `postgresql`, `yojson`, `uri`, `ppx_jane`; system `libpq` and PostgreSQL server binaries for
  tests.
- Used by: none yet; planned for `neobank-api` and `hl-copy-api`.

## Known gaps

- Text format only; no binary results and no prepared-statement cache.
- A query with no parameters goes through the simple protocol, so such a string may hold
  several statements. Use parameters for any value.
- No codecs for interval, time, inet or range types (use `Type.custom`).
- `Listen` does not reconnect; the caller creates a new listener when the pipe closes.
- `Pool` has no minimum size and no maximum connection lifetime.
- `Config.of_url` takes one host; multi-host lists go through `PGHOST` or extra parameters.
- Cancelling needs the same role as the session (or `pg_signal_backend`).
- A test run killed midway leaves its cluster under `/tmp/pg_async_*`.
