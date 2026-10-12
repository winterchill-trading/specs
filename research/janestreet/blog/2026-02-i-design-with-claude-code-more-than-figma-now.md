# I design with Claude more than Figma now

- Source: <https://blog.janestreet.com/i-design-with-claude-code-more-than-figma-now-index/>
- Published: 2026-02-05
- Kind: blog post

## Summary

- A product designer on an options desk, once skeptical of LLMs because they did worse
  than him at tasks he was already good at, found them indispensable after joining the firm
  for unfamiliar things (OCaml, Bonsai) and then for design itself.
- New workflow: write a problem statement and proposal, use it as the prompt to Claude in
  the real codebase, get basic functionality working to prove feasibility, iterate freely,
  push to a development environment for user feedback, and submit a feature (the firm's
  pull request) that behaves exactly as intended.
- Example: adding LLM prompting to the input box of JSQL, the firm's internal SQL dialect
  for user-facing tools. Days of living with a working prototype refined the submit button,
  keyboard shortcuts, copy, the prompt and generated confirmation messages, changes that
  previously took weeks of design and engineering back-and-forth or never happened.
- At first only small UX fixes worked with AI; within about two months bigger prototypes
  did too, including user-facing, data model and library changes with 2,000+ line diffs,
  interactive prototypes of new apps, and some apps designed without Figma at all.
- Working prototypes let a designer prove feasibility and user value without asking
  engineers to spend time on uncertain ideas.
- The downside: reviewers receive a fully built feature and may feel reduced to code
  review. The team's convention is to label prototypes as living proposal documents with
  disposable code; reviewers give design and UX feedback, then write the production
  version in a separate feature.
- The author worries that iterating with an agent keeps him in an incremental mindset and
  may miss bolder ideas for new products, echoing the old "should designers code" debate.

## Relevance to us

- **Research tooling:** a natural-language prompt that produces SQL inside an existing
  query tool is a small, high-value feature. **Action:** add a `specs` page of example
  DuckDB queries over the [market-data](../../../repos/market-data.md) views (with column
  notes such as the `DECIMAL` widening rule), so an agent asked for a query in plain
  language has ground truth to start from.
- **Build and deploy:** agent-built prototypes work best when labelled as disposable
  proposals and re-implemented for production. Context for our process; no repo change.

Tags: `ai-tools`, `ui`, `culture`
