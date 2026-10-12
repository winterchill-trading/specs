# Build and deploy

This theme covers how code turns into running services: the build system and its caches,
how many repositories are held together by CI pins, gating changes so the build stays
green, release and image provenance, configuration kept as data, reproducible
environments, and the operational layer under a deployment (Linux hosts, networks,
clocks, metrics and procedures). It matters for us because the organization is two dozen
OxCaml repositories stitched together by hand-copied `opam pin` lines, deployed as
container images that are tagged `latest`, onto a planned AWS footprint whose recorders
are only as useful as their host clocks and their `/metrics` output.

## Pins are the build graph

A monorepo gets one hash for the whole system, atomic cross-cutting changes and no
version solving; that is the core argument in the
[release process post](../janestreet/blog/2014-06-ironing-out-your-release-process.md)
and in the [build systems episode](../janestreet/podcast/02-build-systems.md). We run a
hybrid: locally an untracked `dune-workspace` makes the checkout a monorepo, while each
repository's CI pins its siblings from GitHub `main` in an order typed out by hand. The
episode's warning about build logic copied into many places (migration as archaeology)
applies directly: the pin lines are duplicated per repository, and the infra service
image replays them, so one missing pin breaks both CI and the image. The fix is to derive
pin order from the `dune-project` dependency graph rather than maintain it by hand, and
to treat clearing that kind of recurring toil as delivery work, as the
[product management episode](../janestreet/podcast/17-a-poets-guide-to-product-management.md)
argues.

## Caching needs deterministic inputs

The headline speedups in Jane Street's migration from Jenga to dune came from builds that
are mostly cache hits
([dune history](../janestreet/blog/2025-01-how-we-accidentally-built-a-better-build-system-for-ocaml.md)),
and the [build systems episode](../janestreet/podcast/02-build-systems.md) explains why
that is safe: a constructive-trace rebuilder hashes a task and its inputs, so sharing is
only sound when inputs are deterministic. Our CI rebuilds every pinned sibling from
scratch on each push, and it resolves those siblings and the `ox` opam repository at
whatever their heads are at the time. Two runs of one commit can therefore build
different code. OxCaml makes this sharper: its extensions carry no stability promise
([introducing OxCaml](../janestreet/blog/2025-06-introducing-oxcaml.md)), and compiler
changes should arrive as a deliberate step, not as a side effect of a push
([compiler optimization](../janestreet/podcast/04-compiler-optimization.md)). The base
image already pins `ox` to a commit; CI does not. Pinning first, then turning on the
setup-ocaml dune cache and measuring, gets both reproducibility and speed.

## Gate before integration, and gate downstream too

The "not rocket science" rule (main only advances to states that built and passed) and
its scaling problems are the subject of
[never break the build](../janestreet/blog/2014-07-making-never-break-the-build-scale.md).
Our version of the problem is different: each repository's CI can be green on its own
while a downstream repository breaks after an upstream push, because nothing builds the
whole graph at upstream heads on a schedule. The
[compiler optimization episode](../janestreet/podcast/04-compiler-optimization.md) adds
that a miscompilation was caught only by a rarely run test, which then became routine;
our three-venue `scripts/e2e-all.sh` runs only by hand. Scripts themselves are part of
the gate: [when bash scripts bite](../janestreet/blog/2017-05-when-bash-scripts-bite.md)
shows `set -e` silently masked by `local`, `export` and `echo` around a failing command
substitution, which shellcheck flags. The infra CI runs shellcheck on `build.sh`; the
`scripts/*.sh` of the OCaml repositories are unchecked.

## A deployment is exactly one set of revisions

The [XARs post](../janestreet/blog/2023-04-building-reproducible-python-environments-with-xars.md)
moved Python environments to a model where each environment is one code revision, with
a rolling nightly tag plus immutable stable tags, at the cost of a rebuild per hotfix.
The [release process post](../janestreet/blog/2014-06-ironing-out-your-release-process.md)
makes the same point from the review side. The first item on the
[performance checklist](../janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md)
is to confirm which binary is actually running before anything else. For us, the service
image records the built repository's short commit in `/etc/service-revision` but not the
commits of the siblings it pinned, carries no `org.opencontainers.image.revision` label,
and the Helm chart deploys `tag: latest`. The running process does not report its build
either. Opt-in diagnostics fit the same model: tracing driven by an environment variable,
such as Memtrace's `MEMTRACE`, needs no rebuild of an immutable image
([memtrace](../janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md)).

## Configuration stays data, and the build checks it

The [configurator talk announcement](../janestreet/blog/2017-04-caveat-configurator-how-to-replace-configs-with-code-and-why-you-might-not-want-to.md)
describes config formats slowly growing into bad programming languages; the
[build systems episode](../janestreet/podcast/02-build-systems.md) describes the
counterweight, a deliberately restricted front language over a real implementation
language. The [Windows config orchestrator](../janestreet/blog/2026-10-config-management-orchestrator-for-windows.md)
shows the other half: decisions (applicability, phasing) move into a typed service, and
the hosts only execute. Our recorder sexp config with `check-config` and our Helm values
are still small records, so the risk is drift rather than complexity: shipped examples
such as `market-recorder/examples/sims.sexp` are not parsed by any test. The same idea
applies to prose, where mdx compiles README code blocks with the build so they break
when the API changes ([writing technically](../janestreet/podcast/10-writing-technically.md)).

## Hosts, networks and limits drift under you

Several posts are about the layer below the program changing silently. The
[network maintenance post](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md)
traces months of failed recoveries to six bugs, one of which only surfaced because a move
to systemd user services quietly lowered the file descriptor limit; per-second socket
history is what made the incident reconstructable. The
[performance checklist](../janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md)
lists drift in kernel, packages, BIOS and uptime between hosts that should be identical,
and VM detection, which matters on EC2. The
[kernel reporter](../janestreet/blog/2026-10-linux-engineering-kernel-reporter.md)
removes every hidden dependency (disk, DNS, TLS) from the path that reports failures,
including cached service discovery. Two posts give cheap diagnostic tools for when a
feed stalls: `ss` exposes per-socket RTT, congestion window and queues
([TCP state](../janestreet/blog/2014-07-inspecting-internal-tcp-state-on-linux.md)), and
dynamic probes found a bounded queue filling under a burst
([systemd and SystemTap](../janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md)).
The [strace-ui post](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md)
mentions proctopus for running multi-process local setups, a possible alternative to our
compose stack for the simulators, market makers and recorder.

## Clocks are infrastructure

The [clock synchronization episode](../janestreet/podcast/06-clock-synchronization.md)
treats time as a service with a computed error bound: chrony slews rather than steps,
the bound combines daemon dispersion, half the round trip and upstream error, and
compliance is shown by sampling each host's bound every ten seconds. The recorder stamps
every frame with `recv_ts`, and the planned replication merges two regions by earliest
`recv_ts`, so cross-host comparisons are only valid within an error we do not record.
The [information propagation post](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md)
makes the same request from the analysis side. `infra/docs/aws.md` already names chrony
with the Amazon Time Sync Service, but there is no bootstrap check and no metric.

## Observability and procedures that answer the first question

The [production engineering episode](../janestreet/podcast/20-solving-puzzles-in-production.md)
lists flickering alerts that open and close with nobody acting as the main noise signal,
and observes that applications exposing their internal state make support automation
easy; it also argues for blameless postmortems with a timeline and concrete actions. The
[data center episode](../janestreet/podcast/24-the-thermodynamics-of-trading.md) credits
the firm's own fine-grained sensors with noticing trouble before the provider did, and
blames maintenance incidents on improvising without a written procedure. Memory needs
its own gauges: container limits act on RSS, which heap figures from `Gc.stat` misstate
([allocator showdown](../janestreet/blog/2020-09-memory-allocator-showdown.md)), and the
GC's single space/time knob should be visible over time in a long-running service
([memory management](../janestreet/podcast/13-memory-management.md),
[lower latency GC](../janestreet/blog/2015-04-building-a-lower-latency-gc.md)). The
[config orchestrator](../janestreet/blog/2026-10-config-management-orchestrator-for-windows.md)
replaces probing each host with one "who has not checked in" query, which is what our
per-stream age gauge already provides.

## Where we stand

- CI pins: [hl-mm](../../repos/hl-mm.md) and [market-maker](../../repos/market-maker.md)
  now pin `parquet` and `market-data` in `ci.yml` (commits "pin parquet and market-data in
  CI for the client feeds"), but the [roadmap](../../roadmap.md), both repository pages
  and [infra](../../repos/infra.md) still list the gap as open.
- No repository workflow pins the `ox` opam repository to a commit, while the
  [infra](../../repos/infra.md) base image does (`OX_REPO_COMMIT`); no workflow sets
  `dune-cache`, and none runs on a schedule.
- Locally, dune's shared cache under `~/.cache/dune` does not share artifacts between
  per-agent `DUNE_BUILD_DIR` directories. Measured with dune 3.22: the default
  (`enabled-except-user-rules`) restored nothing after `rm -rf _build`, and with
  `DUNE_CACHE=enabled` a rebuild into the same build directory path is restored but a
  different `DUNE_BUILD_DIR` recompiles everything. The gotcha is recorded in
  [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md) `GOTCHAS.md` (commit
  `d95a47d`): budget one cold build per agent directory and reuse one `DUNE_BUILD_DIR`
  per repository across sessions.
- [infra](../../repos/infra.md) CI runs hadolint, shellcheck on `build.sh`, `helm lint`
  and a rendered-example check; [market-maker](../../repos/market-maker.md),
  [hl-mm](../../repos/hl-mm.md) and [market-recorder](../../repos/market-recorder.md) run
  no shellcheck on their `scripts/`.
- The service image writes the built repository's short commit to
  `/etc/service-revision` and labels only `source` and `title`; sibling commits are not
  recorded, and the Helm chart's default values use `tag: latest`.
- [market-recorder](../../repos/market-recorder.md) `/metrics` exports per-stream frames,
  bytes, events and `market_recorder_last_frame_age_seconds`, plus upload totals,
  failures and pending; there is no build info, RSS, GC, FD, pipe length, clock error or
  exchange-to-receive latency, and no `/status` endpoint. No test parses
  `examples/sims.sexp`.
- `infra/docs/aws.md` names chrony with Amazon Time Sync and describes `helm upgrade`
  with `Recreate`, but has no bootstrap check, upgrade runbook or troubleshooting section;
  [design/deployment.md](../../design/deployment.md) has no host checks list.
- [fixed-decimal](../../repos/fixed-decimal.md) has no mdx stanza; `specs` has no
  postmortem template.

## Proposed actions

1. Pin the `ox` opam repository URL to the base image's `OX_REPO_COMMIT` in every CI
   workflow, starting with [fixed-decimal](../../repos/fixed-decimal.md), and record the
   commit in [infra](../../repos/infra.md)
   ([OxCaml](../janestreet/blog/2025-06-introducing-oxcaml.md),
   [compiler optimization](../janestreet/podcast/04-compiler-optimization.md)).
2. Add a scheduled workflow in [market-maker](../../repos/market-maker.md) that builds and
   tests with every upstream pinned at `main` nightly, and runs `scripts/e2e-all.sh`
   weekly ([never break the build](../janestreet/blog/2014-07-making-never-break-the-build-scale.md),
   [compiler optimization](../janestreet/podcast/04-compiler-optimization.md)).
3. Add a script in [infra](../../repos/infra.md) that derives each repository's pin order
   from the `dune-project` files and fails when a `ci.yml` misses or misorders a pin
   ([build systems](../janestreet/podcast/02-build-systems.md)).
4. Close the pin item: update the [roadmap](../../roadmap.md), [hl-mm](../../repos/hl-mm.md),
   [market-maker](../../repos/market-maker.md) and [infra](../../repos/infra.md) pages,
   which still report `parquet` and `market-data` as unpinned
   ([never break the build](../janestreet/blog/2014-07-making-never-break-the-build-scale.md),
   [product management](../janestreet/podcast/17-a-poets-guide-to-product-management.md)).
5. Make the infra service build write the built commit and every pinned sibling's
   resolved commit into an `org.opencontainers.image.revision` label, per-sibling labels
   and a file in the image, shown by `make ps`, in [infra](../../repos/infra.md)
   ([release process](../janestreet/blog/2014-06-ironing-out-your-release-process.md),
   [XARs](../janestreet/blog/2023-04-building-reproducible-python-environments-with-xars.md)).
6. Tag service images by commit and make the Helm chart's default values reference an
   explicit tag instead of `latest`, in [infra](../../repos/infra.md)
   ([XARs](../janestreet/blog/2023-04-building-reproducible-python-environments-with-xars.md)).
7. Record the system under test: a CI step printing `opam pin list` with resolved
   hashes, and `scripts/e2e-all.sh` printing every sibling's `git rev-parse HEAD`, in
   [market-maker](../../repos/market-maker.md)
   ([build systems](../janestreet/podcast/02-build-systems.md),
   [release process](../janestreet/blog/2014-06-ironing-out-your-release-process.md)).
8. Set `dune-cache: true` on `ocaml/setup-ocaml@v3` in [hl-sim](../../repos/hl-sim.md)
   and [order-book](../../repos/order-book.md), compare job times, then roll out
   ([build systems](../janestreet/podcast/02-build-systems.md),
   [dune history](../janestreet/blog/2025-01-how-we-accidentally-built-a-better-build-system-for-ocaml.md)).
9. Add a `market_recorder_build_info` gauge (version, executable hash) to
   `Metrics.render` with an expect test, in [market-recorder](../../repos/market-recorder.md)
   ([performance checklist](../janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md)).
10. Add process gauges to recorder `/metrics`: RSS from `/proc/self/statm`,
    `Gc.quick_stat` heap words and collection counts, open FD count, and log soft and hard
    `RLIMIT_NOFILE` at startup, in [market-recorder](../../repos/market-recorder.md)
    ([allocator showdown](../janestreet/blog/2020-09-memory-allocator-showdown.md),
    [memory management](../janestreet/podcast/13-memory-management.md),
    [network maintenance](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md)).
11. Add a clock error gauge sampled every 10 s from `chronyc -c tracking` to recorder
    `/metrics`, and a `chronyc tracking` check in the node bootstrap of `docs/aws.md`, in
    [market-recorder](../../repos/market-recorder.md) and [infra](../../repos/infra.md)
    ([clock synchronization](../janestreet/podcast/06-clock-synchronization.md),
    [information propagation](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md)).
12. Add an expect test parsing `examples/sims.sexp` (declared as a test dependency) and
    printing the config, in [market-recorder](../../repos/market-recorder.md)
    ([configurator](../janestreet/blog/2017-04-caveat-configurator-how-to-replace-configs-with-code-and-why-you-might-not-want-to.md)).
13. Add shellcheck to the CI of [market-maker](../../repos/market-maker.md),
    [hl-mm](../../repos/hl-mm.md) and [market-recorder](../../repos/market-recorder.md)
    for `scripts/*.sh`, mirroring [infra](../../repos/infra.md)
    ([bash scripts](../janestreet/blog/2017-05-when-bash-scripts-bite.md)).
14. Export the length of each `Recorder` pipe into `Norm_writer` as a `/metrics` gauge, in
    [market-recorder](../../repos/market-recorder.md)
    ([systemd and SystemTap](../janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md)).
15. Expose a per-stream gauge of the latest `recv_ts - exch_ts` on `/metrics`, in
    [market-recorder](../../repos/market-recorder.md)
    ([data centers](../janestreet/podcast/24-the-thermodynamics-of-trading.md)).
16. Count `/healthz` transitions between 200 and 503 per stream as `healthz_flaps_total`,
    in [market-recorder](../../repos/market-recorder.md)
    ([production engineering](../janestreet/podcast/20-solving-puzzles-in-production.md)).
17. Add a `GET /status` sexp endpoint listing open minute files and the uploader's pending
    queue, in [market-recorder](../../repos/market-recorder.md)
    ([production engineering](../janestreet/podcast/20-solving-puzzles-in-production.md)).
18. Write a step-by-step runbook for upgrading the recorder Helm release (drain, wait for
    the minute roll, upgrade, verify `/healthz` and uploads), in
    [infra](../../repos/infra.md)
    ([data centers](../janestreet/podcast/24-the-thermodynamics-of-trading.md)).
19. Add a "host checks" list (instance type, kernel, chrony status, uptime) to the AWS
    target section of [design/deployment.md](../../design/deployment.md)
    ([performance checklist](../janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md)).
20. Add a troubleshooting section to the [infra](../../repos/infra.md) deployment notes:
    `ss -tipn` against venue endpoints from the recorder container, and whether the upload
    command depends on DNS and what happens to `upload-pending.sexp` during a DNS outage
    ([TCP state](../janestreet/blog/2014-07-inspecting-internal-tcp-state-on-linux.md),
    [kernel reporter](../janestreet/blog/2026-10-linux-engineering-kernel-reporter.md)).
21. Add node-exporter (or another socket and FD collector) to the compose stack and Helm
    notes, in [infra](../../repos/infra.md)
    ([network maintenance](../janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md)).
22. Add an mdx stanza to [fixed-decimal](../../repos/fixed-decimal.md) so README examples
    run under `dune runtest`, then copy it to other repositories
    ([writing technically](../janestreet/podcast/10-writing-technically.md)).
23. Add a postmortem template (timeline, impact, causes, actions) under `postmortems/` in
    `specs` ([production engineering](../janestreet/podcast/20-solving-puzzles-in-production.md)).
24. Document that dune's shared cache does not let per-agent build directories reuse
    artifacts (a different `DUNE_BUILD_DIR` recompiles everything, measured), and to reuse
    one build directory per repository, in
    [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md)
    ([dune history](../janestreet/blog/2025-01-how-we-accidentally-built-a-better-build-system-for-ocaml.md)).
    Done in `GOTCHAS.md`.
25. Once Memtrace is confirmed to work under OxCaml, add a commented `MEMTRACE` env entry
    and a writable trace path to the recorder Helm values, in [infra](../../repos/infra.md)
    ([memtrace](../janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md)).
26. Try proctopus for the local stack of three simulators, market makers and recorder, and
    note the result next to the compose stack in [infra](../../repos/infra.md)
    ([strace-ui](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md)).
