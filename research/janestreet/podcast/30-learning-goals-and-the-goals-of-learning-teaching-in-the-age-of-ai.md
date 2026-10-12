# Learning Goals and the Goals of Learning: Teaching in the Age of AI

- Source: <https://signalsandthreads.com/learning-goals-and-the-goals-of-learning-teaching-in-the-age-of-ai/>
- Published: 2026-09-23
- Kind: Signals and Threads episode 30

## Summary

- The guest is one of Jane Street's developer educators: half software engineering, half teaching.
  His path ran through a summer science program (computing an asteroid orbit in Python), a PhD on
  how Foldit players solved protein puzzles alongside automated tools, and teaching at a small
  liberal-arts college through the pandemic.
- Remote teaching lessons: text-only courses suited some students and failed others; flipped
  classrooms (lectures recorded beforehand, class time for exercises) and small breakout groups
  helped. Afterwards he kept recording lectures so students could catch up and he could link to a
  timestamp.
- The host defends live lectures as a compelling performance. Both favour active learning breaks
  (pose a question, talk to a neighbour), note-taking for retention, and keeping screens out of the
  room because they split attention.
- On paper, learners have to reason about what code does; at a keyboard they tend to perturb code
  until it runs. The host taught his children with obfuscated Scheme puzzles on paper.
- Fast feedback beats a graded assignment returned weeks later. He used auto-graded weekly quizzes
  with unlimited attempts (best score counts, questions and answers shuffled so brute force is
  slower than learning), a light form of mastery learning, with fixed deadlines to prevent
  procrastination.
- LLMs can give instant feedback on structured work such as code style, but their false positives
  mislead learners, so they need careful framing.
- The developer-educator role was created because Jane Street's trading and tech stack are unusual.
  Educators must be credible practitioners and should also help others teach. Hiring is hard because
  good teachers mostly prefer academia. Open roles cover OxCaml, machine learning and general
  education, and the model may resemble designers embedded across teams.
- The host worries about engineers splitting into OCaml people and Python people and wants everyone
  able to pick the right tool.
- His engineering work is on the Editors team (VS Code, Emacs, Neovim, the code index and the OCaml
  language server). Earlier he extended Iron, Jane Street's feature and code-review system, to split
  a large change into a chain of separately reviewed features (stacked PRs in outside terms).
- The editor is the engineer's home base: review comments are structured comments in the code,
  reviewers often just edit the feature, and keeping everything in the editor preserves that
  collaborative review culture.
- Scale problems: VS Code's diff algorithm hangs on huge diffs and then blocks the diff queue, Iron
  integration breaks VS Code's assumptions about buffers and URIs, and extra compiler metadata
  pushed the monorepo index past available RAM.
- Python notebooks are the hardest surface. Several notebook tools coexist because each replacement
  lacked something, and notebook code is hard to move into shared libraries. Jane Street is building
  its own notebook on its OCaml web stack.
- Build versus upstream: the team is replacing decades of custom Emacs code with standard packages,
  because upstream code is maintained, debugged by others and plays well with other packages. The
  Elisp and OCaml (ecaml) boundary is awkward for asynchronous code and can deadlock.
- Editor telemetry contradicted a guess: jump-to-definition use per user went up rather than down as
  agents wrote more code, suggesting engineers read and verify more. Telemetry now guides which
  features to speed up.
- Agents make a plausible change nearly free while verification costs as much as ever. LLM output
  looks smooth and lacks the usual warning signs, so reading code needs better support: classic
  tools (go to definition, types, test results) plus custom visualizations or pre-computed chunked
  explanations shipped with a feature for review.
- Claude Code's learning output style leaves gaps for the human to fill. The guest found that it
  improved both the experience and his understanding. He compares accepting finished agent output to
  reviewing someone else's diff without having built a mental model of it.
- Teaching with LLMs: the testing teach-in still has learners write property-based tests and
  synthetic-time tests themselves at least once, because that is what lets them judge later
  agent-written versions. Exercises small enough to learn from are now often small enough for an
  agent to finish in one shot.
- Onboarding: OCaml Bootcamp (a cumulative client-server exercise with mentor code review), then a
  production bootcamp on deployment, configuration and monitoring, together about two weeks. Then
  teach-ins chosen from a catalogue (testing, performance, systems debugging, advanced functional
  programming, Bonsai, market data), usable for self-study.
- Concepts land better when a concrete need motivates a tool than when a tool goes looking for a
  problem. Teach-ins have shifted from conceptual lessons toward practical tools that carry the
  concepts with them.
- Learning goals: write what students will be able to do afterwards with concrete action verbs (for
  example, write a property-based test whose input is a nested record), not vague ones such as
  understanding a topic. Exercises, background material and the evaluation of the course itself
  follow from the goals, as does what to leave out.
- Cognitive load: the old bootcamp taught OCaml, a new editor and a new version-control system at
  once. Now each is introduced alone (OCaml in a REPL and in-browser snippets first) before they are
  combined.
- The intern curriculum was rebuilt because the old four-week starter project took one prompt. The
  new one is more open-ended, with design and requirements work: pods of four, full-timers
  role-playing stakeholders, critiques of good and bad design docs, a testing-first start on a
  database-backed app, and three days of code-review training with answer keys before interns review
  real features.
- Lessons from the first run: tasks were too big for interns to own and polish what agents produced,
  and code-review exercises held too many problems. Starting with multitasking and vibe coding set
  the wrong tone, so the testing work now comes first. Agent behaviour also varies from person to
  person, which makes exercises less predictable.

## Relevance to us

- Weak relevance: this is about teaching people, and none of our repos are about that.
- The finding that reading and verification become the bottleneck matches how we work: agents write
  most changes, and the coordinating agent reviews them.
- **OCaml practice:** Learning goals written as concrete action verbs give a way to check whether
  teaching material works, and agent skills are teaching material for agents. **Action:** open each
  skill in [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md) with 3-5 concrete outcomes
  (for example, the agent can add a ppx_expect test that runs an Async function with a synthetic
  time source) and add one small exercise per outcome to check a fresh agent session against.

Tags: `education`, `ai-tools`, `culture`, `testing`
