# Ironing out your development style

- Source: <https://blog.janestreet.com/ironing-out-your-development-style/>
- Published: 2017-08-24
- Kind: blog post

## Summary

- The author distrusts named methodologies and manifestos and prefers concrete stories of
  what was tried; this is one: the "Iron style" that had spread at Jane Street, named after
  its review and release tool.
- Three ingredients: pervasive expect tests, small changes, and fast review that takes
  priority over writing new code. Mundane on paper; the details and their interplay were
  the surprise.
- Expect tests interleave test code with captured output; the runner proposes a corrected
  file, and later output changes appear as diffs to accept or reject.
- Typical uses: print a parser's output on sample data, or drive a state machine through a
  sequence of transactions and dump state summaries along the way.
- Their main value is for reviewers: trace diffs show how a change alters behavior, so
  almost every semantic change should appear as a new test or a changed one.
- Changes are usually ten to a few hundred lines; big work becomes chains of dependent
  features, each coherent enough to read, test and often release alone. Reviewers help
  split monolithic changes.
- If the trace needed to show a change is missing, a parent feature adds it first; bug
  fixes come as a feature with a test exhibiting the bug followed by the fix.
- A designated "seconder" reviews the whole feature, often as a collaborator, and pushes
  authors toward smaller pieces and more tests, which costs the author but saves the many
  reviewers and gives authors more autonomy.
- Small, fast features conflict less, and their conflicts are easier to resolve.
- Why only recently: tools changed the constants. Iron had to make feature operations fast
  (cached pre-populated checkouts, prefetching reviews, releasing a whole chain at once, a
  next-step dashboard).
- Inline tests need almost no ceremony: adding `let%expect_test` registers the test in CI,
  and editor bindings rerun, diff and accept tests.
- The Jenga build system's speed makes switching features and running many tests cheap.
- Conclusion: investing in tools keeps individuals effective as an organization grows and
  can open new ways of working.

## Relevance to us

- Matches how we already work: small frequent commits and ppx_expect traces in every repo,
  such as engine state dumps in [exchange-core](../../../repos/exchange-core.md) and loop
  traces in [mm-core](../../../repos/mm-core.md).
- **Testing and simulation:** a bug fix is most convincing as a test exhibiting the bug
  followed by the fix, and our agent rules do not ask for this. **Action:** add a rule to
  the testing skill in [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md): a
  bug fix lands as two commits, first an expect test whose output shows the bug, then the
  fix whose diff updates that output.

Tags: `expect-tests`, `testing`, `culture`, `build`
