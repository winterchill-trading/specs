# Build Systems

- Source: <https://signalsandthreads.com/build-systems/>
- Published: 2020-09-16
- Kind: Signals and Threads episode 2

## Summary

- The guest worked on Hadrian, the Shake-based replacement for GHC's Make build, co-wrote
  papers analysing build systems, and now works on Jane Street's build systems team.
- A build system automates the developer's repetitive tasks (compile, test, document) in the
  right order; before Make (1976) this was done with scripts, and Make is still the most common
  build tool in open source.
- Make's model of rules with inputs, outputs and a command provides three services:
  incrementality, correct ordering of dependent steps, and parallelism.
- Make decides what to rebuild from file timestamps, which is too conservative (no early
  cutoff when a rebuilt output is unchanged, as after editing a comment) and unsafe (backup
  tools that touch timestamps break it), so users fall back to a clean build.
- Make does not scale across people: every developer rebuilds the same files, whereas modern
  systems share results through a remote cache.
- Make does not scale in complexity: one global namespace of mutable string variables, macros
  that generate macros, and no way to add rules discovered during the build (multi-stage code
  generation).
- GHC (about a million lines) had 20 to 30 large Makefiles; migrating them to Hadrian took
  more than five years because old build logic encodes undocumented knowledge, so migration is
  archaeology and GHC still maintained two build systems.
- The *Build Systems à la Carte* paper reduces each system to a scheduler (task order) and a
  rebuilder (whether a task must rerun), with four schedulers and three rebuilders to combine.
- Combining Shake's suspending scheduler, which supports dynamic dependencies, with Bazel's
  constructive-trace rebuilder, which hashes a task and its inputs to look results up in a
  shared cache, gave Cloud Shake.
- Build systems fragment by language community because each wants to write rules in its own
  language; generating Ninja or Make files from a higher-level description lacks feedback for
  rules that depend on build outputs.
- A language-agnostic engine accepting rules, returning results and accepting more rules until
  a fixed point is suggested as a missing piece; even parsing build descriptions can need
  incrementality at large scale (BuildXL, AnyBuild).
- Jane Street's main repository is 15 to 20 million lines and takes about an hour to build from
  scratch on a large machine, so full rebuilds are not an option.
- Jenga is Jane Street's internal build system, tailored to a monorepo with an unversioned rule
  language; monorepos avoid version constraint solving.
- Most serious build systems have two layers: a restricted user language for describing
  libraries and flags, over a full implementation language (OCaml for Jenga, Java under
  Bazel's Starlark).
- The restricted layer is deliberately limited (no randomness, usually no recursion) so builds
  stay deterministic, analysable and fast; users keep asking for more power.
- Determinism is what makes sharing artifacts between machines safe.
- Jenga supports dynamic dependencies with a suspending scheduler and was gaining cloud builds.
- Dune began as a simple from-scratch tool for building Jane Street's open-source releases,
  became popular because it was 5 to 10 times faster, gained incrementality, portability, a
  versioned language and early cloud caching, and is replacing Jenga internally.
- The migration avoids doing features twice by splitting Dune into an engine and a rule front
  end so that parts can be swapped one at a time; tens of thousands of lines of rules encode
  how the firm builds software.
- Build systems now integrate with editors (errors on save), CI, documentation and code search;
  IDE completion needs build configuration for partially compiled files.
- Facebook's Hack type checker tracks dependencies per function and finishes about 10 ms after
  a rebase touching thousands of files; build systems may become a standard compiler component,
  which would push further toward per-language systems.
- Fine-grained incrementality needs long-lived build servers or shared memory, because
  per-task process start and deserialization costs dominate tiny tasks.
- Excel is also an incremental engine (financial spreadsheets used as live monitors), and it
  allows cycles iterated to a fixed point, which build systems do not.
- The Incremental library and scientific pipelines sit on the same spectrum; pipelines differ
  by data locality, multi-machine scale and runs of weeks, so configuration errors must be
  caught up front.

## Relevance to us

- Our setup is a hybrid of the two models discussed: each repository versions its own
  `dune-project` and CI pins siblings from GitHub, while locally an untracked `dune-workspace`
  makes the checkout a monorepo.
- **Build and deploy:** A shared cache keyed by a hash of each task and its inputs removes
  repeated work, and our CI rebuilds every pinned sibling from scratch on each push.
  **Action:** set `dune-cache: true` on `ocaml/setup-ocaml@v3`, compare job times, and roll
  out if they drop, starting in [hl-sim](../../../repos/hl-sim.md).
- **Build and deploy:** Sharing and caching are only safe with deterministic inputs, but CI
  pins sibling repositories at branch heads, so two runs of one commit can build different
  code. **Action:** add a CI step that prints `opam pin list` with resolved commit hashes,
  starting in [market-maker](../../../repos/market-maker.md).
- **Build and deploy:** Build logic duplicated in many places drifts (the archaeology problem);
  our CI pin lines are hand-copied per repo, and the roadmap already records missing
  `parquet` and `market-data` pins. **Action:** add a script that derives each repository's
  pin order from the `dune-project` files and fails when a `ci.yml` misses a pin, in
  [infra](../../../repos/infra.md).
- **Data platform:** Early cutoff (skip work when inputs did not change) applies to batch
  rebuilds too. **Action:** have `day-close` write a manifest of input file sizes and hashes
  and skip a day whose `norm/` inputs match it, in [market-data](../../../repos/market-data.md).
- Our `market-recorder` sexp config with `check-config` already follows the restricted
  front-language pattern; keep new options declarative rather than adding logic to the config.

Tags: `build`, `ocaml-practice`, `deployment`, `data-platform`
