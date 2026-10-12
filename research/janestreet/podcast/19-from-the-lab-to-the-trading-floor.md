# From the Lab to the Trading Floor: Designing for Expert Users

- Source: <https://signalsandthreads.com/from-the-lab-to-the-trading-floor/>
- Published: 2024-07-12
- Kind: Signals and Threads episode 19

## Summary

- The guest is Jane Street's only UX designer at the time of recording and previously
  worked at NASA JPL, which brought in human-centered design for spacecraft operations
  tools; an earlier university project covered Boeing cockpit design.
- First JPL project: one portal for Earth-observation data (for example atmospheric CO2)
  that previously lived on scattered sites or was passed around by email and USB. The UI
  showed each dataset's processing level and provenance (which satellite or ground
  station produced it).
- Designing for experts in an unfamiliar domain starts with asking basic questions
  without fear; the guest sat in on a science conference, then interviewed attendees.
- Hand-drawn storyboards (comic-strip panels of a workflow, such as a scientist's request
  passing to a rover planner) gave engineers a person-level view on top of their large
  system diagrams.
- Drawing is a sense-making tool, not art: it makes a possible future concrete enough to
  test, and messy sketches invite correction. The guest drafts workflows linearly first,
  then adds branches.
- Jane Street hired UX design because the firm grew from about 35 to about 2,600 people:
  tools built by one engineer for themselves no longer scale, and a simpler interface
  pays off across many users and teams.
- First project at Jane Street was the meeting-room tool built around an in-house
  low-latency audio stack. Shadowing people starting meetings revealed a flat hierarchy
  of equally weighted entry points. The host notes later polish such as wall codes that a
  phone scans to know which room it is in.
- Engineers were receptive; the main shift was asking whether users need a feature
  (evidence from help channels, current usage) before prioritizing it.
- Research became lighter and more ad hoc to fit the culture: a Slack channel posts each
  login to a tool, with the user's rough distance from the reader (around the corner, two
  floors up), so the team can walk over and ask about their experience. The host links
  this to dense trading-floor seating and periodic desk reshuffles that change who talks.
- Current internal projects: Blueprint (provisioning applications), Appd (running apps
  and scheduled jobs, being moved from a CLI to the web) and observability tooling across
  distributed systems.
- Expert users want dense screens: small fonts, no idle white space, every state field
  visible, and panes that still work when shrunk onto one of four to six monitors.
- Keyboard-only operation is required. When a CLI moves to the web, critical actions
  (such as changing a job's status) must keep their exact keyboard behaviour, or users
  stay on the old tool. One easy route is an embedded command line in the page.
- The host argues terminals constrain design in a useful way for teams that are weak at
  visual design, while web UIs add tooltips, links and visualizations (the firm once had
  millions of lines of code but no easy way to draw a line chart).
- Composability is the open problem for GUIs: Unix pipes compose tools that were never
  designed together. Patterns that partly work: one tool publishes the security in
  focus and other independent tools follow it, dashboards that convert to an editable
  text definition, and filter UIs that build a SQL-like query you can edit directly.
- Shared design-system components (buttons, states, colours) are the guest's route to
  reuse across Appd, Blueprint and future apps.
- Beauty, in the guest's view, means clarity and usefulness grounded in the domain; being
  asked to "make it pretty" at the end undervalues the design work.
- Hiring: the firm wants designers who have shipped products and partnered with experts
  outside their own field (fintech, aerospace, robotics).

## Relevance to us

- We have no GUI. Our human-facing surfaces are command-line binaries
  ([market-maker](../../../repos/market-maker.md),
  [market-recorder](../../../repos/market-recorder.md)), `market-data query` and the
  recorder's `/healthz` and `/metrics` endpoints.
- The focus-publishing pattern and text-convertible dashboards are the right shape for a
  future operator dashboard, but nothing on the [roadmap](../../../roadmap.md) needs one.
- **Research tooling:** experts want all state on one dense, keyboard-driven screen, and
  our only live view of the recorder is Prometheus text meant for machines. **Action:**
  add a `market-recorder status -url` subcommand that fetches `/metrics` and prints one
  dense table per venue, stream and symbol (messages, last receive age, health), in
  [market-recorder](../../../repos/market-recorder.md).

Tags: `ui`, `culture`, `hiring`, `observability`
