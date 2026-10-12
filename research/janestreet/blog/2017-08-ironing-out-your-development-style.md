# Ironing out your development style

- Source: <https://blog.janestreet.com/ironing-out-your-development-style/>
- Published: 2017-08-24
- Kind: blog post

## Summary

- The author prefers concrete stories to methodology manifestos and describes the "Iron
  style" of development that had spread at Jane Street, named after its review tool.
- Three ingredients: pervasive expect tests, small changes (tens to a few hundred lines,
  with large work split into chains of dependent features), and review prioritized over
  writing new code.
- Expect tests print parser output or periodic state-machine summaries; their diffs show
  reviewers how a change alters behavior, so almost every semantic change should show up
  as a new or changed trace.
- Bug fixes come as two features: one adds a test exhibiting the bug, the next fixes it
  and the reviewer sees the trace change.
- A designated "seconder" reviews the whole feature and pushes authors to split work and
  add tests.
- The style only became viable once tools made it cheap: Iron caches pre-populated
  checkouts and prefetches reviews, releases whole chains in one step; registering a test
  is one `let%expect_test`; the Jenga build system is fast and parallel.
- Takeaway: tool improvements change the constants of daily work enough to enable new
  workflows.

## Relevance to us

- Matches how we already work: small frequent commits and ppx_expect traces in every repo,
  for example state dumps in [exchange-core](../../../repos/exchange-core.md) and
  [mm-core](../../../repos/mm-core.md).
- The "test first exhibiting the bug, then the fix" split is not written down in our agent
  rules in [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).
- **Action:** add a rule to the `oxcaml-claude-skills` testing skill: a bug fix lands as
  two commits, first an expect test whose output shows the bug, then the fix whose diff
  updates that output.

Tags: `expect-tests`, `testing`, `culture`, `build`
