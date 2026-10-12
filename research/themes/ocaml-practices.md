# OCaml and OxCaml practices

This theme collects what the Jane Street blog and podcast say about writing OCaml day to day:
versioned stable types, expect tests as the default way to test and review, `Or_error` and
validation, types that encode units and permissions, the Base/Core/Async and ppx conventions,
OxCaml's modes and layouts, and the review, release and documentation habits around them. It
matters to us more than to most readers of those sources because nearly all of our code is
written by agents on the `5.2.0+ox` switch, and the cheapest guardrails we have are the ones
the compiler, the expect-test diff and the skills in
[oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md) enforce without a human reading
every line.

## Stable types and versioned formats

Serializing shared OCaml types with sexplib or bin_prot makes small protocols easy to build,
and the hard part is changing them once writers and readers cannot be upgraded together. The
oldest answer is to keep each old version as its own module, write conversions between
adjacent versions or through one internal model, and pick the highest version both sides know
([lightweight versioning](../janestreet/blog/2008-12-lightweight-versioning-for-lightweight-protocols.md)).
The typed RPC design that later became `Rpc.Rpc.t` ties each query type to its response type
but left versioning open
([typing RPCs](../janestreet/blog/2008-03-typing-rpcs.md)). A shared log adds a twist:
there is no peer to negotiate with, so the reader must refuse a format digest it does not
recognize, message-format changes roll separately from logic changes, and the code that
interprets a log is itself an implicit version
([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md)).
The cautionary tale is a free-form string map added because the top-level bin_io type could
not change: it looked easy to evolve, but clients relied on its implicit structure anyway
([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md)).
Pinned shapes stop accidental edits; version-skew tests, where new readers face old writers,
catch the incompatibilities shapes cannot
([battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md)), and
derived Quickcheck generators make a bin_io round trip over every stable record a one-line
property ([Quickcheck for Core](../janestreet/blog/2015-10-quickcheck-for-core.md)). The rule
that old and new versions must coexist recurs even in ML-language design
([episode 25](../janestreet/podcast/25-why-ml-needs-a-new-programming-language.md)).

## Expect tests as the default style and the review medium

Expect tests started as cram-style shell transcripts and became `let%expect_test` with
`[%expect]` blocks that the build rewrites into a `.corrected` diff
([testing with expectations](../janestreet/blog/2015-12-testing-with-expectations.md)). The
argument for them is economic: choosing and typing each assertion discourages testing, while
printing state asserts everything at once, so a silently changed order size shows up as a diff
([joy of expect tests](../janestreet/blog/2023-01-the-joy-of-expect-tests.md)). The craft is
in concise printers that tell a story, written against the public interface or a
`For_testing` module. Their larger payoff is in review: almost every semantic change should
appear as a new or changed trace, a bug fix arrives as a test exhibiting the bug and then the
fix, and if the trace needed to show a change is missing, a preceding change adds it
([Iron development style](../janestreet/blog/2017-08-ironing-out-your-development-style.md)).
Random tests join the same discipline only when a shrunk counterexample is pinned as a fixed
example in the change that fixes it
([episode 23](../janestreet/podcast/23-building-tools-for-traders.md)). Limits of the
representation also belong in expect tests, such as the largest value a 63-bit tagged integer
holds at eight decimals
([63-bit integers](../janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md)).

## Errors as values with context

Core standardizes on `Or_error.t`, where `Error.t` is a lazily rendered message with
sexp-able context; each layer tags the error with what it knows instead of replacing it,
independent checks combine so that all failures are reported together, and destructuring a
record in full makes the compiler demand a check for every new field
([Or_error](../janestreet/blog/2014-04-how-to-fail-introducing-or-error-dot-t.md)). Float
inputs need the same care: NaN makes comparisons false in both directions, so a check written
the wrong way round lets it through, and `-0.0`, NaN and infinity silently change arithmetic
unless conversion into fixed point rejects them
([none is better than NaN](../janestreet/blog/2010-07-making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null.md),
[Z3 refutations](../janestreet/blog/2018-02-proofs-and-refutations-using-z3.md)). For
operations, an error that carries its source position (`[%here]`) lets the on-call reader jump
from an alert straight to the code that raised it
([episode 20](../janestreet/podcast/20-solving-puzzles-in-production.md)).

## Types that carry units, permissions and intent

The guest of [episode 7](../janestreet/podcast/07-language-design.md) feels uneasy whenever
two values of the same type are in scope, because those are the ones that get swapped;
distinct types for instants and spans rule out unit mistakes that raw integers allow
([Core gems: time](../janestreet/blog/2009-11-core-gems-time.md)). Phantom permission
parameters (read-only versus read-write handles) are easy to get subtly wrong, yet the need
they serve is real. With agents writing code, universal type-level guarantees become the
cheapest check there is, and escape hatches like `Obj.magic` undo them, so they should be
tracked and banned outside an allowlist
([formal methods](../janestreet/blog/2026-06-formal-methods-at-jane-street.md)); the
reviewable artifact moves from the implementation to a precise specification, the `.mli` plus
properties ([episode 16](../janestreet/podcast/16-future-of-programming.md)). Smaller tools
point the same way: named alerts flag risky functions at every call site without deprecating
them ([OCaml 4.08](../janestreet/blog/2019-07-a-look-at-ocaml-4-08.md)), and polymorphic
compare is avoided because it breaks abstraction, raises on functions and is slow unless
specialized ([polymorphic compare](../janestreet/blog/2008-08-the-perils-of-polymorphic-compare.md)).

## OxCaml: modes, locality, layouts and data-race freedom

OxCaml is both the production compiler and a laboratory, built on Flambda2, with
pay-as-you-go extensions and, importantly, no stability promise for them
([introducing OxCaml](../janestreet/blog/2025-06-introducing-oxcaml.md)). The 2023 series
lays out the mode axes. Locality lets values that cannot escape a region live on a separate
stack, with `exclave` returning into the caller's region and local parameters acting as a
callee's promise not to retain
([locality](../janestreet/blog/2023-05-oxidizing-ocaml-locality.md)). Uniqueness and
linearity allow in-place updates and use-once closures without lifetime variables
([ownership](../janestreet/blog/2023-06-oxidizing-ocaml-ownership.md)). A sharing axis and
capsules make data races a type error
([parallelism](../janestreet/blog/2023-09-oxidizing-ocaml-parallelism.md)). The shipped
vocabulary differs from those posts, which misleads agents writing from blog text. Worked
production examples are now public: Python reference counting where `@ local` arguments and
`@ unique` results skip increments and `borrow_` lends without consuming
([typesafe refcounting](../janestreet/blog/2026-06-oxcaml-typesafe-reference-counting-python.md),
[interns 2025](../janestreet/blog/2025-08-wrought-2025.md)). Modes also collide with monadic
style: a `let%map` closure is global, so it cannot capture a local value or return an unboxed
type ([algebraic effects](../janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md)).
Unboxed types aim to make layout decisions explicit rather than invisible, which is what
[episode 7](../janestreet/podcast/07-language-design.md) and
[episode 16](../janestreet/podcast/16-future-of-programming.md) name as OCaml's remaining gap
against C++ and Rust. The tracing GC still does not manage scarce resources: file descriptors
must be closed explicitly, finalizer-based release ties external memory to GC timing, and
caller-supplied buffers avoid churning large short-lived ones
([episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md),
[episode 13](../janestreet/podcast/13-memory-management.md)).

## Base, Core, Async and ppx conventions

The standard library collapsed to Base and Core, with Unix-dependent modules moved to
`Core_unix`, `Command_unix`, `Time_ns_unix` and similar libraries, so code and agents trained
on older text still reach for `Core.Unix` and `Command.run`
([goodbye Core_kernel](../janestreet/blog/2021-08-goodbye-core-kernel.md)). `ppx_let` is the
recommended form for monads and applicatives: variables first, parallel `let%map ... and`
for applicatives such as `Command.Param`, one monad per scope, and explicit conversion between
`Deferred` and `Deferred.Result`
([let syntax](../janestreet/blog/2016-06-let-syntax-and-why-you-should-use-it.md)). Library
I/O helpers hide behavior worth knowing, for example a write helper with a minimum length that
loops over short writes ([depot FUSE](../janestreet/blog/2026-10-linux-engineering-depot-fuse.md)),
and Async's futex and epoll noise is what a syscall viewer has to filter before socket
problems become visible
([strace-ui](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md)).

## Review, release and agent-written code

Iron's practice rests on small changes (tens to a few hundred lines), chains of dependent
features, a designated reviewer who pushes for smaller pieces and more tests, and review
before integration, which cut central merge requests by an order of magnitude
([development style](../janestreet/blog/2017-08-ironing-out-your-development-style.md),
[never break the build](../janestreet/blog/2014-07-making-never-break-the-build-scale.md),
[release process](../janestreet/blog/2014-06-ironing-out-your-release-process.md),
[code review talk](../janestreet/blog/2017-10-jane-street-tech-talk-how-jane-street-does-code-review.md)).
For agents the episodes add a workflow: change the type first and let compiler errors list
every call site ([episode 25](../janestreet/podcast/25-why-ml-needs-a-new-programming-language.md)),
write the signature before the implementation
([episode 7](../janestreet/podcast/07-language-design.md)), state a function's contract as a
checked property ([episode 16](../janestreet/podcast/16-future-of-programming.md)), and point
the model at a corpus of real examples in the niche language. Skills are teaching material for
agents, so they benefit from stated outcomes and small exercises to check a fresh session
against ([episode 30](../janestreet/podcast/30-learning-goals-and-the-goals-of-learning-teaching-in-the-age-of-ai.md)).

## Documentation the build checks

Testing pays its author directly, while documentation mostly pays others, so it decays unless
tools and culture back it ([episode 10](../janestreet/podcast/10-writing-technically.md)).
The tools: mdx, whose Markdown code blocks compile with the build; reviewers who read doc
comments and the change description before the code; and prose where types run out, such as
locking, complexity or reconnect semantics. Interfaces tend to be under-documented, and
`.mli` files are where the docs live, so building the docs with warnings as errors is a cheap
gate ([episode 16](../janestreet/podcast/16-future-of-programming.md)).

## Where we stand

- Stable types: [market-data](../../repos/market-data.md) has `Stable.V1` modules for every
  stored record and pins their `[%bin_digest]` in expect tests (`test_types`,
  `test_event_log`, `test_frame_log`). `Event_log` files carry no format header, there is no
  checked-in old file read by new code, and the stable records derive no `quickcheck`.
  `Funding.Stable.V1.exch_ts` is a required `Time_ns`, not an option.
- Expect tests are the default in every repository, and the `janestreet-ocaml-style` skill in
  [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md) says so. The skill (21 lines)
  has no bug-fix, counterexample, type-first or contract-property rule. The 63-bit limit is
  already pinned: [fixed-decimal](../../repos/fixed-decimal.md) tests show `of_string`
  accepting `46116860184.27387903` and rejecting the next unit.
- [fixed-decimal](../../repos/fixed-decimal.md) `of_float` uses `Float.iround_nearest_exn`,
  so it already raises on NaN and infinity, but the `.mli` says only that it rounds to the
  nearest unit and no test covers non-finite or `-0.0` input. There is no alert on it, no
  mdx stanza and no doc build in CI.
- [mm-core](../../repos/mm-core.md) `Params.validate` already reports all failures at once,
  but as bare strings without the offending values, reads fields as `t.x` instead of
  destructuring, and keeps `requote_interval_ms`, `order_ttl_ms` and `max_data_age_ms` as
  `int`.
- [market-recorder](../../repos/market-recorder.md) `Config.load` already tags errors with
  the file path, but not the venue entry index; no module logs `[%here]`. It builds
  read-only Binance clients with `~api_key:""`
  ([binance-client](../../repos/binance-client.md) has no key-less constructor).
- [venue-net](../../repos/venue-net.md) documents `Ws_client.messages` as buffered without
  pushback but says nothing about frames lost across a reconnect.
- No `Obj.magic` or `Obj.repr` appears in any repository's `lib`, `src` or `bin`, so a ban
  costs nothing today. Polymorphic compare is shadowed by `open! Core`; the only explicit
  `Poly` use is one `Poly.equal` on an HTTP method in [bybit-sim](../../repos/bybit-sim.md).
- OxCaml: the `oxcaml-modes` skill covers `local_`, `exclave_`, `global_` and `@ local`
  callbacks only; nothing on `unique`, `borrow_`, the data-race-freedom modes or `let%map`
  limits. `GOTCHAS.md` already has one data-race-freedom symptom (an exception deriving
  `sexp_of` is rejected when a field's converter is not portable). Per-repository CI adds the
  `ox` opam repository without a commit, while the [infra](../../repos/infra.md) base image
  pins one.

## Proposed actions

1. Add a rule and a reusable one-line CI grep that fails on `Obj.magic` or `Obj.repr` outside
   an allowlist, in [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md), then add it to
   each repository's workflow
   ([formal methods](../janestreet/blog/2026-06-formal-methods-at-jane-street.md)).
2. Write a header frame with the `bin_shape` digest of `Event.Stable.V1` at the start of
   every `Event_log` file and fail readers on a mismatch, in
   [market-data](../../repos/market-data.md)
   ([episode 14](../janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md),
   [lightweight versioning](../janestreet/blog/2008-12-lightweight-versioning-for-lightweight-protocols.md)).
3. Check in a small event log written by today's code and test that every later version
   still reads it, next to the digest pins, in [market-data](../../repos/market-data.md)
   ([battle-tested](../janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md)).
4. Pin the `ox` opam repository to the base image's commit in every CI workflow, starting
   with [fixed-decimal](../../repos/fixed-decimal.md), and record that commit plus the
   extensions we use in [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md)
   ([introducing OxCaml](../janestreet/blog/2025-06-introducing-oxcaml.md),
   [episode 4](../janestreet/podcast/04-compiler-optimization.md)).
5. Pin `of_float` on NaN, infinities and `-0.0` in an expect test, document the raise in the
   `.mli`, and add `[@@alert lossy]` with `[@alert "-lossy"]` at intended call sites, in
   [fixed-decimal](../../repos/fixed-decimal.md)
   ([NaN and null](../janestreet/blog/2010-07-making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null.md),
   [Z3](../janestreet/blog/2018-02-proofs-and-refutations-using-z3.md),
   [4.08](../janestreet/blog/2019-07-a-look-at-ocaml-4-08.md)).
6. Rewrite `Params.validate` to destructure `Params.t` with no wildcard and build errors with
   `Error.create_s` carrying each offending value, and make the `*_ms` fields
   `Time_ns.Span.t`, in [mm-core](../../repos/mm-core.md)
   ([Or_error](../janestreet/blog/2014-04-how-to-fail-introducing-or-error-dot-t.md),
   [time](../janestreet/blog/2009-11-core-gems-time.md)).
7. Add an agent workflow section to the `janestreet-ocaml-style` skill: signature and functor
   seam first for new venues, type-first refactors (edit `.mli`, build, fix in dependency
   order, rerun expect tests), and a Base_quickcheck contract property with every public
   `.mli` change, in [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md)
   ([episode 7](../janestreet/podcast/07-language-design.md),
   [episode 16](../janestreet/podcast/16-future-of-programming.md),
   [episode 25](../janestreet/podcast/25-why-ml-needs-a-new-programming-language.md)).
8. Add testing rules to the skills: a bug fix lands as an expect test showing the bug, then
   the fix; every shrunk Quickcheck counterexample goes into `~examples` with the fix, in
   [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md)
   ([development style](../janestreet/blog/2017-08-ironing-out-your-development-style.md),
   [episode 23](../janestreet/podcast/23-building-tools-for-traders.md)).
9. Extend the `oxcaml-modes` skill with compiling examples of `@ local` arguments,
   `@ unique` results and `borrow_`, the shipped data-race-freedom modes and `Capsule` versus
   the 2023 names, a modes-in-practice pointer, and the `let%map` local/unboxed restriction
   with its compiler error, logging rejections in `GOTCHAS.md`, in
   [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md)
   ([refcounting](../janestreet/blog/2026-06-oxcaml-typesafe-reference-counting-python.md),
   [parallelism](../janestreet/blog/2023-09-oxidizing-ocaml-parallelism.md),
   [interns 2025](../janestreet/blog/2025-08-wrought-2025.md),
   [effects](../janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md)).
10. Add a must-fail compile test (a dune rule expecting a type error) proving `Price.t` cannot
   be passed where `Size.t` is expected, in [fixed-decimal](../../repos/fixed-decimal.md)
   ([formal methods](../janestreet/blog/2026-06-formal-methods-at-jane-street.md)).
11. Add a key-less `Config.read_only` to [binance-client](../../repos/binance-client.md) and
   use it in [market-recorder](../../repos/market-recorder.md); when EIP-712 signing lands,
   give the [hl-client](../../repos/hl-client.md) handle a phantom `read_only`/`trading`
   parameter ([episode 7](../janestreet/podcast/07-language-design.md)).
12. Tag `check-config` errors with the venue entry index on top of the file path, and log
   `[%here]` positions in `Raw_writer` and `Uploader` errors and warnings, in
   [market-recorder](../../repos/market-recorder.md)
   ([Or_error](../janestreet/blog/2014-04-how-to-fail-introducing-or-error-dot-t.md),
   [episode 20](../janestreet/podcast/20-solving-puzzles-in-production.md)).
13. Document frame loss and the need to resync across reconnects in the `Ws_client.messages`
   doc comment, in [venue-net](../../repos/venue-net.md)
   ([episode 10](../janestreet/podcast/10-writing-technically.md)).
14. Add `(using mdx 0.4)` and an `(mdx)` stanza so the README example runs under
   `dune runtest`, then pilot `dune build @doc` with warnings as errors and doc comments on
   every export, in [fixed-decimal](../../repos/fixed-decimal.md)
   ([episode 10](../janestreet/podcast/10-writing-technically.md),
   [episode 16](../janestreet/podcast/16-future-of-programming.md)).
15. Derive `quickcheck` on the `Stable.V1` records and add a bin_io round-trip property, in
   [market-data](../../repos/market-data.md)
   ([Quickcheck for Core](../janestreet/blog/2015-10-quickcheck-for-core.md)).
16. Add a `Funding.Stable.V2` with an optional `exch_ts`, written as absent for Hyperliquid,
   with a V1 converter, in [market-data](../../repos/market-data.md) and
   [hl-client](../../repos/hl-client.md)
   ([episode 15](../janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md)).
17. Add a test that rolls 100 minute files and checks the open descriptor count stays
   constant in [market-recorder](../../repos/market-recorder.md), and list C-backed handles
   (zstd, files, SSL sockets) with explicit-close versus finalizer status on the
   market-recorder and [venue-net](../../repos/venue-net.md) pages
   ([episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md),
   [refcounting](../janestreet/blog/2026-06-oxcaml-typesafe-reference-counting-python.md)).
18. Add `GOTCHAS.md` entries for the `Core.X` to `X_unix` renames with dune library names,
   `Bigstring_unix.write ~min_len` looping, and a debugging-sockets-with-strace-ui tip, in
   [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md)
   ([Core_kernel](../janestreet/blog/2021-08-goodbye-core-kernel.md),
   [depot FUSE](../janestreet/blog/2026-10-linux-engineering-depot-fuse.md),
   [strace-ui](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md)).
19. Check whether the `Framed` reader allocates a buffer per frame, and if so add a variant
   decoding into a caller-supplied buffer, in [market-data](../../repos/market-data.md)
   ([episode 13](../janestreet/podcast/13-memory-management.md)).
20. Give each skill a reference-modules list of 3-5 files from our repositories, and open it
   with 3-5 concrete outcomes plus one exercise per outcome for checking a fresh session, in
   [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md)
   ([episode 25](../janestreet/podcast/25-why-ml-needs-a-new-programming-language.md),
   [episode 30](../janestreet/podcast/30-learning-goals-and-the-goals-of-learning-teaching-in-the-age-of-ai.md)).
