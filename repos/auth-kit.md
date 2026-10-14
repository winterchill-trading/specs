# auth-kit

OCaml account-security rules for consumer finance services: passcode strength rules, Argon2id
hashing in self-describing PHC strings, progressive lockout, a reset hook for out-of-band codes,
device records, an append-only security log with stable event kinds, idle auto-lock settings and
the account side of step-up confirmation. Everything is a pure value or function; the service
stores the records the library hands back and passes them in again. It does not persist, read the
clock, speak HTTP or issue sessions and grant tokens; those belong to the service layer.

| | |
| --- | --- |
| Repository | `winterchill-trading/auth-kit` |
| opam package | `auth-kit` |
| Library | `auth-kit` (module `Auth_kit`), and `auth-kit.hash` (module `Auth_kit_hash`) |
| Binary | `auth-kit` (`hash`, `verify`, `inspect`, `bench`, `check-passcode`) |
| Status | done: library, hashing sub-library, CLI and tests are in place (CHANGES: Unreleased) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Passcode_policy` | Length, digits only, no repeated digit, no straight run, deny list; `core` only, so a client can share it |
| `Phc` | PHC string format with canonical unpadded base64 |
| `Password_hash` | Scheme-tagged Argon2id or PBKDF2-SHA256 hashes, constant-time verify, `Match_rehash` for outdated costs, limits on stored costs |
| `Lockout` | Attempts 1-4 free, the 5th locks for 1 minute, each further one doubles the lock up to 1 hour |
| `Passcode` | Per-account record (`Not_set` or hash, set time, lockout); `set`, `verify`, `change`, `remove`, `reset` return the record, the result and the events |
| `Device` | One record per signed-in session with address prefix, throttled last-active, expiry; sign out one or all others |
| `Security_log` | Stable event kinds with wire names and a detail map; append-only sequence, recent entries, notices |
| `Auto_lock` | Idle lock after 1, 5, 15 or 30 minutes, only while a passcode is set |
| `Step_up_policy` | Whether an action needs step-up, and earning one with the passcode or a factor verified elsewhere |
| `Auth_kit_hash` | Argon2id over libargon2 (runtime lock released), PBKDF2-HMAC-SHA256 over cryptokit, the default hasher |

Rules enforced by the library:

- A failed attempt still returns an updated record, so the lockout counts wrong attempts.
- Locked attempts are not checked or counted.
- Stored hashes are untrusted: costs above `Limits.default` are refused when a hash is read.
- Security-log wire names are append-only; a test lists them.
- Operations take `~now`; nothing reads the clock.

## Tests

- `dune test`: expect tests per module, Quickcheck properties, RFC 9106 and reference Argon2id
  vectors, and a cram test for the CLI.
- `Stable.V1` modules for `Lockout`, `Passcode`, `Password_hash`, `Device`, `Security_log` and
  `Auto_lock` have bin_io digests pinned in the tests.
- `test_step_up_policy.ml` runs a step-up end to end against service-kit's grants.
- Tests use tiny Argon2id costs; the default costs are not lowered.

## Dependencies

- Depends on: no org package at build time. External: `core`, `ppx_jane`, `cryptokit`,
  `dune-configurator`, `conf-pkg-config` and the system library libargon2. Test only: `async`
  and service-kit (step-up grants).
- Used by: none yet.

## CI pin order

`service-kit` only (test dependency), through the shared `ox-setup` action. CI installs
`libargon2-dev`, then runs `dune build`, builds and runs the example, runs `dune test`, builds
the API docs with warnings as errors, and calls the shared `obj-magic` workflow.

## Known gaps

- Binding a grant on first use to one request (operation plus idempotency key, or a card) is a
  grant-store concern and is not here; step-up grants are currently consumed once.
- The default hasher has no server-side secret ("pepper"); `Argon2id.derive` takes one, but
  stored hashes do not record a key id yet.
- One-time codes for resets are produced and checked elsewhere; `Passcode.Reset_proof` only
  records that one was accepted, and when.
