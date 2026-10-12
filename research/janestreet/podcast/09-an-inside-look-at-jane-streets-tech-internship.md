# An inside look at Jane Street's tech internship

- Source: <https://signalsandthreads.com/an-inside-look-at-jane-streets-tech-internship/>
- Published: 2020-11-06
- Kind: Signals and Threads episode 9

## Summary

- Three former interns, now full-time on Risk, Trading Systems and RFQ teams, describe the
  program. Most incoming interns have no functional programming background, and candidates
  should interview in the language they are strongest in rather than OCaml.
- Structure: a cohort-wide OCaml bootcamp in the first week or two, then two projects on two
  teams in different parts of the firm, plus classes on internal tools, libraries and
  finance. In 2020 COVID moved the program remote with one team for the whole summer.
- The bootcamp material started as training for traders and grew into a broader education
  program for interns and new full-timers.
- Learning the many internal tools and unwritten institutional knowledge was the hardest
  part early on; the finance domain was the second hurdle.
- Project one: a fast path for raising system-level risk limits in the manual order entry
  system during busy sessions. Soft limits can be bumped a configured number of times, while
  hard limits change only through a code-review-like process (limits config used to be
  changed by mailing patches to support staff).
- Project two: making manual price requests from sales traders flow through the same
  automated risk checks as electronic RFQs, so the manual path no longer bypassed them.
- Trading is far more manual than outsiders assume: phone trades, manual orders and small
  manual adjustments, with human judgment kept in the loop. RFQs that fail validation are
  frozen until a trader approves them.
- Project three: merging a simple and an advanced interface of the Incr_dom web framework
  into one design, adding a ppx for a common idiom (keeping source locations right was the
  hard part), then migrating every user across the monorepo.
- Intensive code review, where the reviewer is close to a co-author, is what makes it safe
  for newcomers to touch risk systems and is a major teaching channel.
- Good intern projects need a favourable "surface area to volume" ratio: wanted, not yet
  done, and not requiring deep context, which often makes them more speculative.
- A full-time project, Zeroprot, is a message format inspired by Cap'n Proto that lets apps
  on different protocol versions interoperate efficiently; because it is about backward
  compatibility, its API must be right the first time.
- Other themes: starting from blank files is common because the code is modular; teams
  balance user features, technical debt and large architectural changes; trader support
  interrupts focus; imposter syndrome is common; new staff need regular explicit feedback.

## Relevance to us

- Mostly a hiring and culture episode, so relevance to our code is limited.
- **Market making and trading systems:** Soft limits that can be bumped a fixed number of
  times keep a strategy running in busy markets while hard limits stay sticky. **Action:**
  add an optional `soft_max_position` with a bump budget to `Params` and `Risk` in
  [mm-core](../../../repos/mm-core.md) that pulls only the quotes that would grow the position
  instead of halting, with an expect test showing the bump count.
- **Market making and trading systems:** Every order path, including manual ones, should go
  through the same risk checks. **Action:** extend the existing expect tests with a
  Base_quickcheck property in [mm-core](../../../repos/mm-core.md) that, over random
  positions, mids and open orders, `Risk.flatten` only ever places reduce-only orders.

Tags: `hiring`, `culture`, `risk`, `education`
