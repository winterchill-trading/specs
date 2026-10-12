# Building a functional email server

- Source: <https://signalsandthreads.com/building-a-functional-email-server/>
- Published: 2020-10-28
- Kind: Signals and Threads episode 8

## Summary

- SMTP is a simple hand-off protocol: a sender connects, names sender and recipients and
  passes a body, and the receiver accepts, refuses or relays. Email's early openness has
  stuck for decades, which makes it both durable and hard to secure.
- Jane Street's mail setup was conventional (external gateways, internal servers doing
  filtering, list expansion and delivery) plus regulatory archiving with different rules per
  jurisdiction, including where copies must be stored.
- The old open-source server needed 400 to 500 lines of a bespoke INI-like config language
  with multi-phase macros and implicit rules for which router applies. Compliance-archiving
  near-misses were hard to diagnose, the team became afraid to change it, and only
  specialists understood it.
- They wrote Mailcore, an SMTP server written and configured in OCaml. The key reframing: a
  mail server is a function from one message to zero or more output messages, so routing
  logic becomes composable, side-effect-free OCaml functions.
- Generating the old config from OCaml was rejected because its primitives were already
  complex and some behavior needed runtime dynamism. The guest admits config generation was
  also simply less common internally at the time.
- Black-box end-to-end tests of the old system were rejected because its config units were
  not composable, so a failing test would not localize the cause. Newer mail servers
  configured in Python or Lua were rejected as immature and as a second language.
- The SMTP core was quick to build; reproducing years of config intent took longer and
  revealed nondeterministic or wrong behavior in the old system.
- Migration used a shadow instance: every inbound message was copied to both systems and a
  streaming diff of outputs (messages, transformations, destinations) ran for months. It
  found 5 to 10 classes of divergence, mostly old-system bugs. Users were then moved one
  at a time, starting with the team's own mail.
- The total effort was about a year. Core code came in near estimate; config and building
  confidence ran over, and that work would have been needed for any migration.
- Benefits: unit tests on config, reusable config pieces across server instances, the same
  diff harness for Mailcore upgrades, a reusable SMTP client/server library, and a much
  larger set of people willing to make changes.
- Security staff could add scanners for malicious attachments directly. "Relay lists"
  forward mail to a host and port, so any team can run a small mail-driven automation
  without touching the core server.
- Treating operations as software brings tooling (editor integration, build, tests, jump to
  definition) and also culture: code gets reviewed, tested, described and refactored, while
  config gets copy-pasted. Keeping config in the same repository and release bundle as the
  code helps.
- Compiler warnings as errors for unused values catch a common config mistake (defining
  something and never wiring it in), and exhaustive pattern matching removes another bug
  class.
- Costs: every SMTP extension must be implemented in-house. Security worries proved smaller
  than expected thanks to memory safety (no C buffer overflows) and an uncommon codebase.
- Email authentication (SPF, DKIM) needs both sender and receiver to participate, which
  limits its value. Internally the larger problem is too much mail, so the team surfaces
  list sizes when sending and generates shared team filters in OCaml under code review,
  since a bad shared filter can silently black-hole a support team's mail.

## Relevance to us

- [market-recorder](../../../repos/market-recorder.md) already keeps its config as a typed
  sexp with a `check-config` command, which is the episode's config-as-code lesson in
  small form.
- **Testing and simulation:** Run old and new versions on identical input and diff outputs
  before switching. **Action:** add `scripts/diff-day-close.sh` to
  [market-data](../../../repos/market-data.md) that runs `day-close` from two git revisions
  over one recorded day of `norm/` logs and diffs every Parquet table with DuckDB `EXCEPT`
  queries.
- **Data platform:** The planned raw-to-norm tool is a second implementation of the live
  normalizers, so it can be validated the same way. **Action:** make the acceptance test
  for the raw-to-norm tool (see [roadmap](../../../roadmap.md)) rebuild one recorded day and
  diff it event by event against the `norm/` logs the recorder wrote live.
- **Market making and trading systems:** A shadow strategy can be compared on live data
  without sending orders. **Action:** add a `-shadow-params FILE` option to
  [market-maker](../../../repos/market-maker.md) that runs a second `Strategy` on the same
  feed, logs its plans without executing them, and counts divergences from the live plan.
- **Testing and simulation:** Example configs rot unless the build checks them.
  **Action:** add an expect test in [market-recorder](../../../repos/market-recorder.md)
  that parses every file in `examples/` with `Config.of_sexp` and prints the venues.

Tags: `testing`, `ops`, `data-platform`, `replay`
