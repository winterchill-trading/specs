# A Poet's Guide to Product Management

- Source: <https://signalsandthreads.com/a-poets-guide-to-product-management/>
- Published: 2023-08-15
- Kind: Signals and Threads episode 17

## Summary

- The guest studied theater, English and poetry, worked for nonprofits and edited a
  literary magazine. A research lab that hired creative generalists into non-coding
  technical roles brought him into tech, so engineers could stay focused on their core work.
- Outsiders bring a useful outside view; a project and a poem share constraints, an
  audience and a shape. The guest tries to keep some distance even after learning the
  domain.
- Jane Street grew from about 30 to over 2,000 people without PMs. Cross-team work (a
  language feature that also needs editor, library and refactoring-tool changes; data center
  builds) kept dropping pieces and landing late, so the firm made coordination a first-class
  role.
- The guest started remotely in 2020 on networking: two data center builds and moving a
  research compute cluster between them, while also setting up a repeatable way to run such
  projects.
- The first fix on a new team is usually one place where all project information is
  tracked, instead of spreadsheets, chat and email.
- Trust takes time. A good PM acts like an anthropologist, learning how the team already
  works before changing it. They borrow small ideas, such as shipping a minimal version to
  get feedback, rather than imposing agile ceremony such as sprints and story points.
- Working remotely with about 25 contacts hid the culture. Chance encounters in the
  office matter a lot for relationship-driven work.
- A pandemic project bridged a low-latency audio tool from gaming with corporate video,
  then brought it back into the office as a mobile app with desk hardware. A hard return
  date and 10 to 50 proxy users from different areas drove a minimal, performance-first
  release, improved for a year and a half after.
- The firm switches between careful, reliable building and startup-style emergencies
  (pandemic, flood, new opportunity), and decides by consensus yet can rally quickly.
- PMs are now part of mixed teams with engineers and designers, not a wall between
  developers and users, and any process they add should survive if they leave.
- Saying yes to every request dilutes focus. Three people on one project beat three people
  on six each, because nothing pays off until it ships. Being nice is not a plan.
- Hiring looks for listening and empathy first, plus the ability to break down and track
  work, assess risk and think about the whole product. Interviews test how candidates take
  in new information; writing is valued as a way to think. Non-technical PMs can take the
  OCaml bootcamp.
- Technical debt: two-week toil reduction sprints every six months, focused on a few
  recurring themes, produced tools now used across the firm. Less toil means more delivered,
  not just happier engineers.
- The GPU build-out for deep learning: PMs pushed to be in the room when decisions were
  made, asked requesters to explain goals rather than exact purchases (some items had
  98-week lead times), and ran small experiments first, such as existing storage before a
  dedicated cluster. They optimized for learning rate and said openly that teams were
  placing bets that could fail.

## Relevance to us

- Weak relevance: this is about organizing human teams at a 2,000-person firm. `specs` and
  its [roadmap](../../../roadmap.md) already act as the single source of project status
  the guest recommends.
- **Build and deploy:** time set aside for recurring toil pays back in delivery speed.
  **Action:** clear the known CI toil item from the roadmap by pinning `parquet` and
  `market-data` in the CI of [hl-mm](../../../repos/hl-mm.md) and
  [market-maker](../../../repos/market-maker.md).

Tags: `culture`, `hiring`
