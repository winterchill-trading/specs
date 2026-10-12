# Research tooling

This theme covers how people (and agents) explore data and turn findings into something
repeatable: notebooks and the Python/OCaml boundary, expect tests as rerunnable notebooks,
tools and UIs for expert users, the infrastructure behind ML research, the hygiene that keeps
signal research honest (bias, gaps, look-ahead), visualization, and AI coding tools. It
matters to us because our research surface is young: [market-data](../../repos/market-data.md)
gives DuckDB SQL over Parquet and nothing else, we have no UI at all, and almost all of our
code is written by agents. The sources show which cheap additions make that surface
trustworthy before it grows.

## Files are our interop layer, not bindings

Jane Street researchers live in Python notebooks while production is OCaml, so the firm built
bindings in both directions: OCaml values converted to Python by a deriver, OCaml functions
exposed as Python modules, and Jupyter magics that run OCaml cells
([Python and OCaml in one notebook](../janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md),
[episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md)). The same episode
is frank about the costs: cross-runtime reference cycles leak, and the `Time_ns` boundary is a
recurring pain point. Newer OxCaml work uses modes to make the reference counting across the
boundary type-safe
([type-safe refcounting](../janestreet/blog/2026-06-oxcaml-typesafe-reference-counting-python.md)),
and Python environments are pinned as whole executables
([XARs](../janestreet/blog/2023-04-building-reproducible-python-environments-with-xars.md)).

None of that machinery is needed while our boundary is files. Parquet with `TIMESTAMP_NS` and
`DECIMAL(18,8)` columns is readable from pyarrow, pandas and DuckDB's Python package with no
OCaml in sight. The real risk moves from interop code to type fidelity: a nanosecond
timestamp that silently becomes microseconds, or a decimal read as float. A researcher should
be able to get a frame of one day's trades without reading our OCaml, and that path should be
tested.

## Exploration should rerun from the top

Notebooks evaluate cells in any order, so they can reach states that no top-to-bottom run
reproduces; spreadsheets avoid this by recomputing from a dependency graph
([episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md),
[episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md)). The episode 22 guest
adds that research needs reproducibility as much as production does: without it you cannot
tell whether one change or six moved a result.

Expect tests are the OCaml answer. An exploration written as a `let%expect_test` that prints
its findings is a plain-text notebook that always reruns, gets committed, and later guards
refactors; real data enters by checking a captured file in beside the test
([repeatable exploratory programming](../janestreet/blog/2018-04-repeatable-exploratory-programming.md),
[episode 23](../janestreet/podcast/23-building-tools-for-traders.md)). The craft is choosing
what to print: whole state when it explains a failure, not everything. Episode 22 also names
the porting problem that two toolsets create (research in one, production in another); our
strategy is pure OCaml, so a replay-driven expect test can be research and regression test at
once.

## Research hygiene: point in time, gaps and look-ahead

Several sources describe the same discipline from different angles. Data tooling should offer
point-in-time universes so a study of the past only sees instruments that existed then, and
even vetted data deserves "trust but verify"
([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md)). Vendors revise
history, so the firm stores every delivery with its own receive time; backtesting on corrected
data simulates a time machine rather than what was knowable
([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)). LLMs add a new
look-ahead channel, because a model may already know what happened next; evaluation has to be
split at the model's knowledge cutoff
([memorization in LLMs](../janestreet/blog/2026-09-mitigating-memorization-in-llms.md)).
High-data work needs strict holdouts and no reuse of test sets across teams
([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md)).

The operational form is tested, reviewable transformations (dbt style) with checks at each
stage, and derived datasets that record which inputs and code produced them
([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md),
[episode 21](../janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md)). Our
raw-first design already keeps our own `recv_ts` on every row, which is the receive-time rule.
What we lack is everything around it: no daily record of which instruments existed and their
tick and lot sizes, no marking of reconnect gaps, no automated data checks after day close,
and contract multipliers (`1000PEPEUSDT`, `kPEPE`) that make raw prices incomparable across
venues.

## Put intermediate values next to their inputs

Excel and node-based shader editors are praised for showing each intermediate value beside
the code that produced it, which makes them debuggers as much as tools
([episode 11](../janestreet/podcast/11-building-a-ui-framework.md)). Computations that print
every term of a formula as a tree make plausible-but-wrong results obvious
([self-documenting computations](../janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md)).
For market data the equivalent is joining streams in time: the core debugging question is
the last X before Y, which DuckDB's `ASOF JOIN` answers directly
([2023 interns](../janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md)).

Visualization proper follows from the same views. Plotting price moves across venues by
receive time shows which venue leads and by how much
([information propagation](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md)),
latency is most useful as a distribution over time of day
([2019 interns](../janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md)), and cheap
histograms (trade share, inter-arrival point masses) score how realistic a synthetic market is
([autoregressive diffusion](../janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md)).
Each is a short SQL query over tables we already write; a plotting layer can come later.

## Tools for expert users: dense, keyboard-first, often a terminal

Experts want every state field on one dense screen, keyboard-only operation, and no idle
white space; when a CLI moves to the web, its exact keyboard behaviour must survive or users
stay on the old tool ([episode 19](../janestreet/podcast/19-from-the-lab-to-the-trading-floor.md)).
Trader tools split into exploration and attention management, where alerts need stateful
damping and desk-wide thresholds
([episode 23](../janestreet/podcast/23-building-tools-for-traders.md)). Bonsai models a UI as
an incremental graph of state machines with a view as only one possible output
([episode 11](../janestreet/podcast/11-building-a-ui-framework.md)).

The newest shift is to the terminal. Bonsai_term brings the same model to TUIs, a working
strace viewer took under ten minutes with an agent, and a handful of new internal TUIs appear
daily, from log explorers to a time-travel debugger
([Bonsai_term](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md)).
The key enabler is its test framework: the app renders as text inside expect tests, so an
agent can walk through the UI and read its own "screenshots". A TUI is also a normal native
program, so it can link our libraries directly. For us that makes a terminal viewer over
recorded data, or a dense status table over the recorder's Prometheus text, the cheapest
first UI.

## Research infrastructure: catalogs, usage logs and declarative pipelines

Most of the ML infrastructure in the sources (GPU fleets, activation checkpointing, sequence
weighting, deep nets in OCaml) does not apply to a team that trains no models
([episode 21](../janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md),
[episode 25](../janestreet/podcast/25-why-ml-needs-a-new-programming-language.md),
[activation checkpointing](../janestreet/blog/2026-09-trading-off-compute-for-memory-with-activation-checkpointing.md)).
The transferable parts concern the data layer. The firm's warehouse owns every read and
write, which gives it a catalog and usage logs; those logs are what make deprecation and
schema change possible, instead of grepping everyone's SQL and then views of views
([episode 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md)). Research
jobs increasingly run as lazy, declarative dataframe graphs (Polars) that a scheduler can
shard by date and symbol. Simple models remain valuable because they can be adjusted by hand
when a regime changes ([episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md)).

Our DuckDB views read Parquet directly, which is right for a small team, but it means we have
neither an inventory of what exists nor a record of what is read.

## AI coding tools need ground truth and feedback

The sources agree that agents are strongest where feedback is fast and checkable. Types,
proofs, expect tests and text-rendered UI screenshots all close the loop
([formal methods](../janestreet/blog/2026-06-formal-methods-at-jane-street.md),
[Bonsai_term](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md)).
Agents left to a strict validator may weaken tests instead
([episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md)), and they
write better niche-language code when pointed at real examples
([episode 25](../janestreet/podcast/25-why-ml-needs-a-new-programming-language.md)). Agents
started from a chat message do better when a human shapes the plan first
([2026 SP interns](../janestreet/blog/2026-09-wrought-2026-sp.md)), and an overnight agent
sweep over five heap implementations beat intuition
([message bus](../janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md)).

A designer's account adds two research-tool lessons
([designing with Claude Code](../janestreet/blog/2026-02-i-design-with-claude-code-more-than-figma-now.md)).
First, natural-language prompting inside an existing SQL tool is a small, high-value feature,
but it needs real examples over the real schema to start from. Second, agent-built prototypes
work best labelled as disposable proposals and rewritten for production. LLMs make data
engineering faster for people who can judge the output and easier to get wrong for everyone
else ([episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md)). Documents an
agent reads benefit from a declared genre (tutorial, how-to, reference, explanation)
([episode 10](../janestreet/podcast/10-writing-technically.md)).

## Where we stand

- [market-data](../../repos/market-data.md) has exactly three subcommands: `day-close`,
  `views` and `query`. `views` emits one `CREATE VIEW` per table over `read_parquet` globs;
  there are no join, `ASOF` or quality views. `query` shells out to the `duckdb` CLI with
  `box`, `csv` or `json` output, which agents can already parse.
- There is no Python anywhere in the organization's repositories and no example of reading
  our Parquet from Python, so `TIMESTAMP_NS` and `DECIMAL` fidelity outside DuckDB is
  untested. `market-data` has no scripts directory.
- `market-data` tests build all input in code (`test/sample.ml`); no test stanza declares a
  captured data file, so no exploration runs over real recorded data.
- [mm-core](../../repos/mm-core.md) `Strategy` is a pure state machine (`on_book`,
  `on_fill`, `tick`) and depends only on `exchange-core` and `fixed-decimal`; driving it from
  `Market_data.Replay_feed` in a test would add `market-data` as a test dependency.
- [market-recorder](../../repos/market-recorder.md) offers only `run` and `check-config`;
  its live view is `/healthz` and Prometheus text on `/metrics`. Reconnect gaps are not marked
  in raw files ([data platform](../../design/data-platform.md)).
- No repository uses Bonsai or Bonsai_term; we have no UI, web or terminal.
- `day-close` writes no manifest, instruments table or quality report; the
  [roadmap](../../roadmap.md) lists a replay server and a raw-to-norm tool, but no research
  tooling item.
- [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md) has four skills
  (`oxcaml-setup`, `oxcaml-modes`, `async-http-websocket`, `janestreet-ocaml-style`) and no
  guidance on agent workflow, test removal or reference modules. The `specs` CLAUDE.md has no
  document-kind convention.

## Proposed actions

1. Add `market-data check -dir D -date YYYY-MM-DD` running fixed DuckDB assertions (no crossed
   BBO, positive sizes, `recv_ts` non-decreasing per file, no empty minute on liquid symbols),
   exiting non-zero, and run it after the day-close CronJob in [infra](../../repos/infra.md).
   Repo: [market-data](../../repos/market-data.md). Sources:
   [episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md),
   [episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md).
2. Add a gap view listing, per venue, symbol and day, minutes with zero trades or BBO updates,
   tested on a fixture day with one deliberate gap, in
   [market-data](../../repos/market-data.md). Source:
   [episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md).
3. Have `day-close` write a daily `instruments` table (venue, symbol, tick, lot, first and last
   `recv_ts`) for point-in-time universes, plus a `units_per_contract` view for
   `1000PEPEUSDT`-style multipliers, in [market-data](../../repos/market-data.md). Sources:
   [episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md),
   [episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md).
4. Have `day-close` write `<date>.manifest.sexp` (input `norm/` files with sizes, build
   version, run time) beside each table, with an expect test, in
   [market-data](../../repos/market-data.md). Sources:
   [episode 21](../janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md),
   [episode 29](../janestreet/podcast/29-wrestling-the-world-into-rows.md).
5. Add an expect test in [mm-core](../../repos/mm-core.md) that drives `Strategy` from
   `Market_data.Replay_feed` over a small fixture event log and prints the quotes, making the
   production strategy the research harness. Source:
   [episode 22](../janestreet/podcast/22-finding-signal-in-the-noise.md).
6. Check a small real recorded event log into `market-data` tests as a declared dependency
   and add expect tests over it: candle aggregation printing the candles, and `Candle_agg`
   compared row for row with DuckDB candles over the same day, in
   [market-data](../../repos/market-data.md). Sources:
   [repeatable exploration](../janestreet/blog/2018-04-repeatable-exploratory-programming.md),
   [episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md).
7. Add a `trades_with_bbo` view that `ASOF JOIN`s each trade to the prevailing BBO, so a
   quoted spread and the trades that hit it sit side by side, in
   [market-data](../../repos/market-data.md). Sources:
   [episode 11](../janestreet/podcast/11-building-a-ui-framework.md),
   [2023 interns](../janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md).
8. Add a Python path with a test: `examples/query.py` loading one day of trades through DuckDB
   into pandas, and a script step asserting via pyarrow that `recv_ts` is nanosecond UTC and
   prices are decimal, in [market-data](../../repos/market-data.md). Sources:
   [episode 5](../janestreet/podcast/05-python-ocaml-and-machine-learning.md),
   [Jupyter post](../janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md).
9. Document in the `market-data` README how `exch_ts` and `recv_ts` map to pandas
   `datetime64[ns, UTC]` and the `DECIMAL` widening rule, with one example query, in
   [market-data](../../repos/market-data.md). Source:
   [Jupyter post](../janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md).
10. Add a `specs` page of example DuckDB queries over the `market-data` views with column notes
   (ground truth for agents asked for SQL in plain language), seeded with the lead-lag,
   latency-distribution and realism-histogram queries. Repo:
   [market-data](../../repos/market-data.md) and `specs`. Sources:
   [designing with Claude Code](../janestreet/blog/2026-02-i-design-with-claude-code-more-than-figma-now.md),
   [information propagation](../janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md),
   [autoregressive diffusion](../janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md).
11. Make `market-data query` append UTC time, user and SQL text to `query-log.ndjson` in the
   data directory (opt-out flag), so schema changes can first grep real usage, in
   [market-data](../../repos/market-data.md). Source:
   [episode 28](../janestreet/podcast/28-building-a-data-warehouse-from-scratch.md).
12. Add `market-recorder status -url` that fetches `/metrics` and prints one dense table per
   venue, stream and symbol (messages, last receive age, health), in
   [market-recorder](../../repos/market-recorder.md). Source:
   [episode 19](../janestreet/podcast/19-from-the-lab-to-the-trading-floor.md).
13. Add a `Quoter.For_testing.explain` that prints every term of one quote as a tree, used in
   an expect test with a long inventory, in [mm-core](../../repos/mm-core.md). Source:
   [self-documenting computations](../janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md).
14. Add an agent-workflow section to the skills: a plan-review step before large tasks,
   commits that remove tests or accept changed expect output must say why, and a list of 3-5
   reference modules per skill, in
   [oxcaml-claude-skills](../../repos/oxcaml-claude-skills.md). Sources:
   [episode 26](../janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md),
   [episode 25](../janestreet/podcast/25-why-ml-needs-a-new-programming-language.md),
   [2026 SP interns](../janestreet/blog/2026-09-wrought-2026-sp.md).
15. Prototype a Bonsai_term viewer that pages through one `Event_log` file filtered by stream,
   with a rendered-screen expect test; reuse the pattern for a read-only `market-maker` status
   screen. Repos: [market-data](../../repos/market-data.md),
   [market-maker](../../repos/market-maker.md). Source:
   [Bonsai_term](../janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md).
16. Add a one-line "Kind: tutorial / how-to / reference / explanation" header convention to
   the `specs` CLAUDE.md and apply it to the `design/` pages. Repo: `specs`. Source:
   [episode 10](../janestreet/podcast/10-writing-technically.md).
