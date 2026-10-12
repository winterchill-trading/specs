# Writing, Technically

- Source: <https://signalsandthreads.com/writing-technically/>
- Published: 2021-09-01
- Kind: Signals and Threads episode 10

## Summary

- The guest is a writer-in-residence who spends about 75% of the time coding (documentation
  tooling) and the rest helping colleagues write and edit. Being a regular developer in the
  local ecosystem (language, in-house standard library, build, deploy and test tools) is
  what lets them empathize with readers.
- Without someone focused on it, documentation becomes a neglected backwater. Authors write
  docs right after building something, when they are most immersed in implementation
  details; the editor's job is to stay a perpetual outsider.
- The culture strongly ties code to owners (review tooling records who owns each file), so
  answers are often a phone call away. That works, but leaves no searchable trail for new
  people; writing is how knowledge persists and scales.
- The host compares this with the firm's earlier shift on testing: once a small, well-known
  codebase relying on types, it built a strong testing culture alongside better test tools,
  and documentation has not yet had the same transformation.
- Testing is "single player" (it pays its author directly) while documentation is
  "multiplayer" (it mostly pays others), so the organization has to value it deliberately.
- Tooling built in response: mdx, Markdown whose OCaml code blocks compile with the build so
  examples break when APIs change; a docs site with readership counts, likes and comments
  as social feedback; and an internal search across wikis, literate docs, API docs, blogs,
  mailing lists and review comments, because good documents often go unfound.
- A build failure in docs is mainly a prompt to reread and rethink them, and seeing that
  people read a page is a strong incentive to improve it (seeing that nobody does saves
  effort next time).
- In code review the host reads doc comments, the change description and identifier names
  before the code, and writing documentation during review often exposes real conceptual
  bugs.
- A commit message that keeps explaining away a design choice is a sign the change is a
  first draft. In both prose and code, quality comes from tolerance for revision.
- "Self-documenting code" has limits. Types should carry as much as possible (a validated
  domain type instead of string-to-string functions), but complexity bounds, subtle locking
  semantics and choices between implementations need prose; a lock flag documented by a
  five-paragraph comment is the example.
- Language matters less than culture and architecture: big rewrites change people,
  practices and architecture at the same time as the language.
- OCaml documentation tends to be terse and formal (a formal grammar as the README of a
  jq-like query tool). Concise docs serve experts and examples serve newcomers, so write
  several documents and say which reader each one is for.
- The tutorial, how-to, reference and explanation split gives technical docs a genre
  readers can navigate, like the inverted pyramid in news; the host adds evangelism as a
  fifth kind, which a careful, hedging culture finds hard.
- Literate programming works in a master's hands but rarely scales to team-maintained
  software, where the move from a single author's program to many maintainers is the hard
  part.
- Writing practice: customised editors for notes and quotes; never send a first draft;
  trim pasted context such as long stack traces; much technical writing is email, where
  extra care multiplies across readers; good technical writing makes the important things
  salient, as an illustration does compared with a photograph.

## Relevance to us

- Our repositories document themselves through READMEs, `.mli` comments and `specs`, and
  none of their code samples is compiled today.
- **Build and deploy:** Code blocks in docs should be built so they cannot drift.
  **Action:** in [fixed-decimal](../../../repos/fixed-decimal.md), add `(using mdx 0.4)`
  and an `(mdx)` stanza so the README's OCaml example is checked under `dune runtest`, then
  copy the pattern to other repositories once it works in CI.
- **OCaml practice:** Comments are needed where types cannot express behavior, such as
  backpressure and reconnect semantics. **Action:** expand the `.mli` doc comment of
  `Ws_client.messages` in [venue-net](../../../repos/venue-net.md) to say what happens to
  frames during a reconnect and that callers must resync, which today is only in `specs`.
- **Research tooling:** Documents need a declared genre. **Action:** add a one-line
  "Kind: tutorial / how-to / reference / explanation" header convention to the CLAUDE.md
  of `specs` and apply it to the pages under `design/`.

Tags: `education`, `testing`, `build`, `culture`
