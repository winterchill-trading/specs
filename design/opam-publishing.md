# Opam publishing

Kind: explanation.

Status: in progress (2026-10-14). Our opam repository exists,
[opam-repository](../repos/opam-repository.md), with `0.1.0` entries for `pg-async`,
`fixed-decimal`, `money`, `money-cli`, `ledger`, `venue-net` and `parquet`, each pinned to
a commit (no tags, no GitHub releases). Every other step below that would publish anything
waits for an explicit decision. The findings this plan rests on, with sources, are in
[research/opam-readiness](../research/opam-readiness/README.md).

## Decision in short

- Publish through our own opam repository, `winterchill-trading/opam-repository`, layered
  on top of the OxCaml repository. Not upstream opam-repository (its CI has no OxCaml and
  our Core dependency does not exist there) and not the OxCaml repository (it carries the
  compiler, the Core and Async family and patched third-party packages, with no process for
  outside libraries).
- Keep every opam file valid for upstream (lint clean, no `pin-depends`, real checksums,
  exact bounds), so moving a package upstream later is a metadata change, not a rework.
- Offer an upstream OCaml build only where a library is small and the payoff is real
  (`fixed-decimal` first), with dune `select` shims; never remove an OxCaml performance
  feature to get it.
- MIT license, descriptive names without an org prefix, `0.x` semver with OCaml-specific
  breaking-change rules, docs on GitHub Pages.
- Tier 1: `pg-async` first, because it already builds on upstream OCaml, then `fixed-decimal`
  and `money`. Tier 2: `ledger`, `order-book` (with
  `exchange-core`), `venue-net`, `parquet`. Tier 3: the provider-neutral banking libraries.

## Why not upstream opam-repository, today

The contribution guide accepts packages through `dune-release`, `opam publish` or a manual
pull request, and every pull request runs on the opam-repository CI. That CI's platform
list has upstream compilers only (4.11, 4.14 and 5.2 to 5.5 with flambda, afl and
no-flat-float-array variants). A package that needs OxCaml fails every build there.

Two mechanisms make an OxCaml dependency expressible upstream, and neither makes it
buildable:

- `depends: "oxcaml"` resolves upstream to `oxcaml.action-required`, which fails on
  purpose and prints how to add the OxCaml repository. This is the intended signal and the
  best user experience: a user without the overlay gets an instruction, not a solver error.
- `available:` filters or `x-ci-accept-failures` could silence CI, but the archiving policy
  keeps a version only while it installs on a supported platform with an upstream
  compiler, so such a package is first in line for removal.

The pull request that added the virtual package left open whether OxCaml-dependent
packages belong upstream, and none has been released there yet. The second blocker is ours:
we build on Core `v0.18~preview.*`, which only the OxCaml repository has, and at least one
syntax-clean library (`kyc-core`) already uses v0.18-only Core API. Revisit when either
upstream CI gains an OxCaml platform or Core v0.18 is released upstream.

## Our opam repository

The repository is [opam-repository](../repos/opam-repository.md). Two things differ from
the layout below while the libraries are untagged: each `url` is a git URL with the
exact audited commit instead of a tarball with checksums, and CI installs on push to
`main` rather than per pull request.

### Layout

```text
opam-repository/
  repo                                  opam-version: "2.0"
  packages/
    fixed-decimal/fixed-decimal.0.1.0/opam
    money/money.0.1.0/opam
  .github/workflows/ci.yml              lint, install and test every changed package
  README.md                             how to add the repository
```

Each `opam` file is the one dune generates, with `name`, `version` and `pin-depends`
removed and a `url` section added: the release tarball and both a `sha256` and a `sha512`
checksum. Tarballs come from `dune-release distrib` (reproducible, from the tag).

### What users run

```sh
opam switch create 5.2.0+ox \
  --repos wc=git+https://github.com/winterchill-trading/opam-repository.git,ox=git+https://github.com/oxcaml/opam-repository.git,default
opam install fixed-decimal
```

or, on an existing OxCaml switch,
`opam repo add wc git+https://github.com/winterchill-trading/opam-repository.git`. No
`opam pin` is needed: dependencies resolve from the three repositories by version.

### Name clashes across repositories

opam merges the versions of a package name from every repository in the switch; only an
identical `name.version` is taken from the higher-priority repository (verified: on our
switch `yojson` lists upstream `3.0.0` next to the OxCaml repository's `2.2.2+ox`). If
another project later published one of our names upstream, its versions would mix with
ours under one name and the solver could pick theirs. Hence: our repository carries only
our own packages, never a fork or patch of somebody else's (patched third-party packages
are the OxCaml repository's job), and our names must not be generic nouns another project
is likely to want (see [Naming](#naming)).

### Compiler and dependency constraints

Every package states the OxCaml dependency the way the OxCaml repository's own packages
do, so the same file is meaningful upstream:

```text
depends: [
  "oxcaml"                          # upstream: action-required, prints how to add the overlay
  "ocaml" {>= "5.2.0" & < "5.3~"}  # the OxCaml line we test on
  "dune" {>= "3.17"}
  "core" {>= "v0.18~preview.130.106+341" & < "v0.19~"}
  ...
]
x-maintenance-intent: ["(latest)"]
```

Notes on the choice:

- `"oxcaml"` replaces today's `"ocaml-variants" {>= "5.2.0+ox" & < "5.2.1~"}` in our
  generated files. Both pin the compiler, but only `oxcaml` gives a helpful message when the
  overlay is missing.
- The Core lower bound is the preview we test on, not `v0.18~preview` (which admits
  earlier previews we never built). Core itself carries a `conflicts` range on
  `oxcaml-compiler`, so pinning Core transitively pins a compatible compiler build.
- `~` sorts before everything in opam version order, so `< "v0.19~"` admits every v0.18
  preview and release and excludes v0.19 previews.
- The OxCaml repository already has `ocaml-variants.5.4.0+ox`; widening `ocaml` happens
  per release after a CI run on that line, never speculatively.

### CI for the repository

On every pull request to the repository, for each changed `packages/*/*.<version>`:

1. `opam lint` on the file and the opam-ci-check lint (the same rules upstream applies).
2. In a container with the cached `5.2.0+ox` switch (the infra `ox-setup` action), add the
   pull request's tree as a repository and `opam install --with-test --with-doc` the
   package, then its reverse dependencies in our repository.
3. `opam admin check --installability` over the whole tree, so no version becomes
   uninstallable silently.

amd64 Linux is required; arm64 macOS runs nightly. The repository's `main` branch is the
published state: merging is publishing, so merging needs the same explicit approval as a
tag.

## Dual build: an upstream OCaml path

Worth it only where an outside user on upstream OCaml is plausible and the shim is small.
The mechanism, verified on both switches:

```text
(library
 (name fixed_decimal)
 (libraries core
  (select parse_impl.ml from
   (stdlib_upstream_compatible -> parse_impl.ox.ml)
   (-> parse_impl.upstream.ml))))
```

`stdlib_upstream_compatible` ships with the OxCaml compiler and does not exist upstream,
so dune picks the OxCaml file on OxCaml and the fallback elsewhere. Rules:

- Shared files keep `[@zero_alloc]` attributes; upstream ignores them.
- Prefer one shared file where an upstream spelling exists: `type t [@@immediate]` instead
  of `type t : immediate`; a non-escaping local `ref` instead of `let mutable` (it still
  passes the zero-alloc check).
- Split into `.ox.ml` and `.upstream.ml` only for `or_null`, `exclave_`, `@ local`,
  `float#` and unboxed products. The `.mli` stays shared and must be expressible upstream,
  so layout-polymorphic signatures (`('a : immediate). ...`) need a second interface or a
  different API.
- Core is the larger cost: the upstream path must build on Core v0.17. That is a port per
  library, tested in a second CI job on an upstream switch.
- The upstream path is a second opam package only if it ever goes upstream; in our
  repository one package with the shim is enough.

Candidates: `pg-async` needs no shim, since it already builds upstream. `fixed-decimal`
(17 `let mutable`, two `: immediate`, no Core-v0.18-only API known yet) is the cheapest
shim; `money` needs its layout-polymorphic `to_fixed_decimal`
reshaped; `order-book` and `parquet` are deep in OxCaml features and stay OxCaml-only.

## Common blockers

These block more than one package and are listed once here; each audit page names the
ones that apply to it under its top blockers
([research/opam-readiness](../research/opam-readiness/README.md#audits)).

- **No upstream venue.** Upstream opam CI has no OxCaml platform. Our own opam
  repository ([opam-repository](../repos/opam-repository.md)) now exists, and merging
  into it is publishing.
- **`odoc` is not installed on the switch.** `dune build @doc` has never run on any
  audited package, so none can be released `--with-doc` yet. The OxCaml dry run plans
  `odoc.3.2.0+ox2` and touches neither the compiler nor Core; installing it waits for the
  owner's approval (see [Documentation](#documentation)).
- **Tests need external servers or binaries.** `pg-async`'s cluster tests need PostgreSQL
  (`initdb`, `pg_ctl`), and `parquet`'s tests need the DuckDB CLI. Neither is an opam
  package, so `opam install --with-test` fails on a clean machine until the tests skip
  without them or a depext supplies them.
- **Circular dependency between `order-book` and `exchange-core`.** The `order-book`
  library depends on `exchange-core`, and `exchange-core-engine` (in the `exchange-core`
  repository) depends on `order-book`: a cycle between packages. `order-book` cannot be
  released until `exchange-core` is, or until the primitives it uses move into a package
  of their own.

## Licensing

Every repository already ships MIT, which is also the license of Core, Async and most of
their family, so a user's dependency cone stays uniform. ISC (common in the OCaml tool
ecosystem, used by `dune-release` itself) is equivalent in effect and offers no reason to
relicense. Apache-2.0 adds an explicit patent grant and a NOTICE requirement; the grant
matters for algorithms with patent exposure, which none of the tier 1 or 2 libraries
has. Keep MIT; state `(license MIT)` in `dune-project` and keep the copyright line in
`LICENSE` on the organization.

## Naming

- No org prefix. opam names are descriptive (`pgx_async`, `postgresql`, `decimal`), and a
  prefix adds nothing a `homepage` does not.
- No bare common nouns. `money`, `ledger` and `parquet` are free today, but they are the
  names a future upstream package would take, and its versions would then mix with ours.
  Proposed: `money` keeps its library name and ships as package `exact-money`; `ledger` as
  `double-entry`; `parquet` (a writer only) as `parquet-writer`. All three were free on
  opam.ocaml.org and in the OxCaml repository on 2026-10-14. The findlib library name may
  stay as it is; the opam package name is what users type.
- Dashes, not underscores, matching our existing names; upstream lint treats them as equal
  anyway.
- `pg-async` keeps its name. It sits next to `postgres_async` in the OxCaml repository, a
  wire-protocol client from the Async family; the README must say in its first paragraph
  why to choose a libpq-based client (TLS through the system OpenSSL, SCRAM, `.pgpass`,
  the full libpq feature set).
- `order-book`, `venue-net`, `fixed-decimal` and the `*-core` libraries keep their names.

## Versioning

- Start at `0.1.0`. While below `1.0.0`, a minor bump may break, a patch bump never does.
- OCaml-specific breaking changes, beyond removals and type changes: adding a value or type
  to a module type (every implementation must now provide it), adding a constructor to an
  exposed variant (exhaustive matches break), changing a `Stable.V<n>` serialization,
  tightening a dependency bound, and dropping a compiler line. Adding a value to a
  module, not a module type, is a minor change even though it can shadow a name for users
  who `open` the module.
- `1.0.0` when the API has had one release without breaking changes and an outside user.
- Version strings carry no `v` in opam (`0.1.0`); tags are `v0.1.0`, matching what
  `dune-release` derives.

## CHANGES.md and deprecation

- Keep a Changelog sections (`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`) under
  `## Unreleased`. At release, the `Unreleased` entries move under `## 0.2.0 (YYYY-MM-DD)`
  and a fresh empty `## Unreleased` goes on top, after the tag is cut; `dune-release tag`
  reads the version from the first heading, so we pass it explicitly
  (`dune-release tag v0.2.0`).
- Deprecate before removing: the old name stays for at least one minor release with
  `[@@deprecated "use [Foo.bar] instead; removed in 0.4.0"]`, the replacement is in the
  same release, and `Deprecated` in CHANGES.md names both. Renamed packages keep the old
  name as an empty package depending on the new one for one release.

## Documentation

ocaml.org builds package docs only from upstream opam-repository, so we host our own:

- `dune build @doc` produces `_build/default/_doc/_html`; a workflow on `main` uploads it
  to GitHub Pages (`actions/upload-pages-artifact` and `actions/deploy-pages`), one site
  per repository at `https://winterchill-trading.github.io/<repo>/`.
- The opam `doc` field points there; today it points at the README.
- `odoc` is not on our switch. Installing it plans `odoc.3.2.0+ox2` from the OxCaml
  repository and touches neither the compiler nor Core; it is installed into the CI image,
  not the shared development switch, until the owner approves.
- Every library's top-level module doc carries a worked example that also lives under
  `examples/` and builds in CI, so the docs cannot rot.

## Release checklist

For one package version. Steps after the line need explicit approval and are not taken
by this plan.

1. `dune build @all @runtest @doc` green on the `5.2.0+ox` switch, and on the upstream
   switch for dual-build packages.
2. `CHANGES.md`: `Unreleased` moved under the new version and date.
3. `dune-project` version bounds checked against what CI installs; `dune build` regenerates
   the opam file; `opam lint *.opam` clean.
4. README "Releasing" section matches what is about to happen.
5. Every dependency of the package is already in our repository, the OxCaml repository or
   upstream at the bounded versions (`order-book` waits for `exchange-core`).
6. `dune-release distrib --dry-run` passes its lint.
7. `opam publish --output-patch FILE --repo winterchill-trading/opam-repository` writes the
   repository patch without uploading anything, and the patch is reviewed.

Requires approval:

1. `dune-release tag vX.Y.Z` and `dune-release distrib`.
2. `dune-release publish distrib` (GitHub release with the tarball).
3. `dune-release opam pkg` and `dune-release opam submit --opam-repo
   winterchill-trading/opam-repository` (pull request to our repository).
4. Our repository's CI green, then merge.
5. Docs site deployed from the tag.

## Tier list

| Tier | Package | Library deps | OxCaml-only constructs | Why this tier |
| --- | --- | --- | --- | --- |
| 1 | `pg-async` | async, core_unix, postgresql, uri, yojson | none (builds on upstream OCaml 5.2 with Core v0.17, checked by hand) | Upstream-buildable today; fills a real gap; libpq via `postgresql` from upstream |
| 1 | `fixed-decimal` | core, ppx_jane, yojson | `[@zero_alloc]`, `let mutable`, `: immediate` | No org deps; unique; the cheapest dual build |
| 1 | `exact-money` (`money`) | core, fixed-decimal, zarith, yojson | `: immediate` layouts | Only needs `fixed-decimal`; general-purpose currency maths |
| 2 | `double-entry` (`ledger`) | core, core_unix, async_kernel, cryptokit, money | none | Owns an on-disk journal format; freeze it with versioned stable types first |
| 2 | `order-book` | core, exchange-core, fixed-decimal | `or_null`, `exclave_`, `@ local`, `[@zero_alloc]` | Needs `exchange-core` published or the dependency cut |
| 2 | `venue-net` | async, async_ssl, async_websocket, cohttp, conduit-async, uri | none (Async v0.18 only) | Useful plumbing, but its API was shaped by our venues |
| 2 | `parquet-writer` (`parquet`) | core, zstd | `float#` | Writer only (required columns, PLAIN, zstd); scope must be stated |
| 3 | `payments-core`, `kyc-core`, `card-core`, `risk-rules`, `banking-provider` | money, ledger, cryptokit, zarith | none | Encode our product decisions; no outside demand yet |

Reasons in more detail:

- **Tier 1** libraries are small, depend only on packages that already exist in the OxCaml
  or upstream repositories (or on each other), have no on-disk formats beyond their
  `Stable` sexps, and solve problems other OxCaml users have: exact decimals, money, and
  PostgreSQL from Async. `pg-async` goes first: it is the only library audited so far with
  no OxCaml construct, and it builds and passes its tests on plain OCaml 5.2.0 with Jane
  Street v0.17, so it is the first candidate for an upstream release. The other two need
  the OxCaml overlay until a Core v0.17 port exists; `fixed-decimal` goes before `money`
  because `money` depends on it.
- **`ledger` is tier 2, not tier 1.** It is general (balanced postings, holds, reversals,
  idempotency keys), but it writes an append-only checksummed Bin_prot journal, and a
  public release turns that format into a compatibility promise. Release it once the
  journal header carries a format version and a reader for every old version, and once
  `exact-money` has had a release.
- **`order-book`** is the best showcase of OxCaml features but cannot ship before
  `exchange-core`, which is large and simulator-shaped; either publish the primitives it
  uses as their own small package or move them into `order-book`.
- **`venue-net`** and **`parquet`** are general in principle and narrow in practice; each
  needs its README to state scope honestly before an outsider can judge it.
- **Tier 3** libraries are provider-neutral by design, but their state machines, rules
  and identity model are this organization's product choices, and they depend on the whole
  tier 1 and 2 chain. Keep them in our repository's scope list for later; publish only on
  outside demand. `kyc-core` holds personal-data types and needs a privacy review of its
  sexp and log output before anyone else builds on it.

## Open questions

- Does the owner want a public opam repository at all, or only "pin from GitHub"
  instructions for now? The repository is cheap but merging into it is publishing.
- `exact-money` or keep `money`: rename before the first release or never.
- Should `fixed-decimal`'s upstream build be a goal for 0.1.0 or a later release? It needs
  a Core v0.17 CI job.
- Who reviews pull requests to our repository: a second agent with a checklist, or the
  owner each time?
- When OxCaml's 5.4 line becomes the default in the OxCaml repository, do we follow at
  once (one release widening `ocaml`) or wait for Core v0.18 final?
