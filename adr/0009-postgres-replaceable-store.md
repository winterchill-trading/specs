# ADR 0009: PostgreSQL for application state, behind a replaceable store

Status: accepted

## Context

The neobank demo ([design/neobank.md](../design/neobank.md)) and the copy-trading API
([design/copytrading.md](../design/copytrading.md)) keep application state: users, sessions,
provider ids, transfers and card states, idempotency records, outboxes and inboxes. The bank
side also writes an append-only ledger journal, which is a file of its own
([ledger](../repos/ledger.md)) and is not part of this decision.

hl-copy-api keeps its state as files in a state directory: sealed agent keys, follower
config files and the engine's journals ([design/copytrading.md](../design/copytrading.md)).
Files do not give the transactions the transfer and webhook paths need: a webhook must mark
its event as seen and update a transfer in one atomic step, and two requests must not both
spend the same idempotency key. hl-copy-api is moving its application state to PostgreSQL;
the journals stay as they are.

The options considered for the application store were:

- **PostgreSQL through `pg-async`**, a non-blocking libpq client written for this organization
  (see [pg-async](../repos/pg-async.md)). Transactions, serializable isolation, unique
  constraints and migrations are built in.
- **pgx**, the pure-OCaml PostgreSQL protocol implementation. Its pins (`ocaml < 5.0`,
  `core < v0.16`) do not build on the OxCaml switch, so it cannot be used at all.
- **Cassandra** (or another wide-column store). It has no multi-row transactions, so
  consistency across a transfer, its ledger entry and its idempotency key would move into
  application code, where each service would have to get it right. There is no OCaml driver to
  build on either.
- **An embedded store** (SQLite, or a key-value store on disk). Works for one process, but the
  demo runs `neobank-api` and its workers as separate services under compose and Kubernetes,
  and a shared store is what they need.

## Decision

1. **PostgreSQL holds all application state**, reached only through `pg-async`.
2. **Every service is replaceable behind its own store interface.** Each service that keeps
   state defines a `Store.S` module type over its own domain types, with two implementations:
   `Store_memory` (in memory, used by tests, the offline demo and the fake provider) and
   `Store_pg` (PostgreSQL). The rest of the service sees only `Store.S`.
3. **SQL lives in two places only:** `store_pg.ml` and the service's migrations. No other
   module builds a query string.
4. **One schema per service.** Each service owns a PostgreSQL schema (or a database) and its
   migrations. A service never reads another service's tables.
5. **No cross-service joins.** A service that needs another's data calls its API or
   consumes its events.
6. **Idempotency keys on every write that money or a provider depends on.** A retried request
   or a redelivered webhook returns the stored answer and books nothing twice.
7. **The ledger journal stays outside the database.** Bookings are appended to the
   checksummed Bin_prot journal of [ledger](../repos/ledger.md); the database holds state
   derived from it and the idempotency keys that point at it. The journal is the record of
   money, and it can be replayed without the database.
8. **One conformance suite runs against both stores.** A functor in each `Store.S` library
   runs the same scenarios (insert and conflict, idempotent replay, concurrent updates,
   ordering of reads after writes) against `Store_memory` and `Store_pg`; CI runs `Store_pg`
   against a throwaway cluster from `pg-async`'s testing library.

## Consequences

- A service can be moved to another store, or run against the in-memory store in tests, by
  changing one module. The cost is that a feature which needs a PostgreSQL-only behaviour
  (a specific isolation level, a `LISTEN` channel) must be expressed in `Store.S` or stay
  inside `store_pg.ml` with a test that says so.
- Migrations and SQL review are concentrated in two places per service, which makes a schema
  change reviewable.
- The journal and the database can disagree after a crash between the append and the
  database write. Replay of the journal repairs the derived state, and idempotency keys make
  the retry safe; the rule is part of each store's conformance suite.
- Running PostgreSQL becomes a dependency of every deployment that keeps state. The compose
  and Helm deployments get a PostgreSQL service with the first store (planned; see
  [design/deployment.md](../design/deployment.md)). CI needs `libpq-dev` and a server.
- The C dependency (libpq) is accepted in exchange for a driver that builds on OxCaml and
  covers TLS, SCRAM and failover.
- Cassandra and pgx are not reconsidered unless the OxCaml switch starts building pgx, or a
  workload needs horizontal write scaling that a single PostgreSQL primary cannot provide.
