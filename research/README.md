# Research notes

Reading notes on public engineering writing from a trading firm whose stack ours is built
on: the Jane Street tech blog and the Signals and Threads podcast. The goal is to pull out
what matters for this organization (trading system and data platform architecture,
OCaml and OxCaml practice, testing, performance, deployment, research tooling) and turn it
into concrete proposals for our repositories.

## How to read

- **Theme documents** under [themes/](themes/) synthesize across sources, compare with
  where our repositories stand, and end with a merged, ordered list of proposed actions.
  Read these first.
- **Top 20** below is the short list we would start with.
- **Insights for us** lists every actionable insight found in the notes, one line each,
  grouped by theme and ordered by value, with a link to the source note and the
  repositories it affects. Several insights from different sources often point at the
  same change; the theme documents merge them.
- **Per-source notes** live under [janestreet/blog/](janestreet/blog/) (named
  `<yyyy-mm>-<slug>.md`) and [janestreet/podcast/](janestreet/podcast/) (named
  `<nn>-<slug>.md`, by episode number). Each gives the source URL and date, a summary in
  our own words, a "Relevance to us" section with one bullet per actionable insight, and a
  tags line. The [index](#index) lists them all.
- The proposed actions also appear one line each in
  [roadmap.md](../roadmap.md#from-research).
- Notes summarize; they do not reproduce. Quotes are short and attributed. Read the
  original for anything load-bearing. Claims about our repositories were checked against
  the code at the time of writing; the repository's own README and `.mli` files win when
  they disagree.

## Scope

- Every Signals and Threads episode (30 episodes; the two trailers are not covered).
- Every blog post from 2018 onward (88 posts), and 33 earlier posts whose titles are
  relevant to trading systems, OCaml practice, testing, performance or tooling.

## Top 20

To be filled in once the insights list is complete.

## Insights for us

To be filled in.

## Themes

| Theme | Covers |
| --- | --- |
| [State machines and logs](themes/state-machines-and-logs.md) | Concord and Aria, sequencers, total order, gap fill, snapshots, replay, log formats |
| [Data platform](themes/data-platform.md) | Raw-first storage, symbology and units, catalogs and lineage, data quality, layout, Python through files |
| [OCaml and OxCaml practices](themes/ocaml-practices.md) | Stable types, expect tests, errors as values, modes and layouts, Core and Async conventions, review |
| [Performance](themes/performance.md) | Allocation, GC visibility, benchmarking, tail latency, tracing, hardware and network |
| [Testing and simulation](themes/testing-and-simulation.md) | Expect and property tests, reference models, deterministic simulation, fault injection, recorded traffic |
| [Research tooling](themes/research-tooling.md) | Files as interop, repeatable exploration, research hygiene, expert tools, AI coding tools |
| [Build and deploy](themes/build-and-deploy.md) | CI pins, caching, gating, revisions per deployment, configuration, hosts, clocks, observability |
| [Market making and trading systems](themes/market-making-and-trading-systems.md) | Exchanges as sequencers, feeds and gaps, order gateways and reconciliation, risk, venue semantics, latency |

## Index

### Signals and Threads episodes

| Published | Note | Actions | Tags |
| --- | --- | --- | --- |
| 2020-09-09 | [Programmable Hardware](janestreet/podcast/01-programmable-hardware.md) | 3 | `fpga`, `hardware`, `expect-tests`, `market-data`, `latency` |
| 2020-09-16 | [Build Systems](janestreet/podcast/02-build-systems.md) | 4 | `build`, `ocaml-practice`, `deployment`, `data-platform` |
| 2020-09-23 | [Multicast and the Markets](janestreet/podcast/03-multicast-and-the-markets.md) | 4 | `multicast`, `sequencer`, `market-data`, `networking`, `latency` |
| 2020-09-30 | [Compiler Optimization](janestreet/podcast/04-compiler-optimization.md) | 4 | `performance`, `oxcaml`, `formal-methods`, `testing`, `build` |
| 2020-10-07 | [Python, OCaml, and Machine Learning](janestreet/podcast/05-python-ocaml-and-machine-learning.md) | 4 | `python-interop`, `ml`, `research-tooling`, `parquet`, `expect-tests` |
| 2020-10-14 | [Clock Synchronization](janestreet/podcast/06-clock-synchronization.md) | 5 | `clocks`, `ops`, `observability`, `market-data`, `replay` |
| 2020-10-21 | [Language Design](janestreet/podcast/07-language-design.md) | 4 | `ocaml-practice`, `oxcaml`, `architecture`, `education` |
| 2020-10-28 | [Building a functional email server](janestreet/podcast/08-building-a-functional-email-server.md) | 4 | `testing`, `ops`, `data-platform`, `replay` |
| 2020-11-06 | [An inside look at Jane Street's tech internship](janestreet/podcast/09-an-inside-look-at-jane-streets-tech-internship.md) | 2 | `hiring`, `culture`, `risk`, `education` |
| 2021-09-01 | [Writing, Technically](janestreet/podcast/10-writing-technically.md) | 3 | `education`, `testing`, `build`, `culture` |
| 2021-10-06 | [Building a UI Framework](janestreet/podcast/11-building-a-ui-framework.md) | 2 | `ui`, `state-machines`, `ppx` |
| 2021-11-03 | [What Is an Operating System?](janestreet/podcast/12-what-is-an-operating-system.md) | 3 | `architecture`, `ocaml-practice`, `testing`, `networking` |
| 2022-01-05 | [Memory Management](janestreet/podcast/13-memory-management.md) | 3 | `gc`, `allocation`, `oxcaml`, `performance` |
| 2022-04-20 | [State Machine Replication, and Why You Should Care](janestreet/podcast/14-state-machine-replication-and-why-you-should-care.md) | 7 | `state-machines`, `sequencer`, `replay`, `architecture`, `multicast` |
| 2022-09-12 | [Swapping the Engine Out of a Moving Race Car](janestreet/podcast/15-swapping-the-engine-out-of-a-moving-race-car.md) | 4 | `architecture`, `market-data`, `stable-types`, `performance`, `ops` |
| 2023-05-18 | [The Future of Programming](janestreet/podcast/16-future-of-programming.md) | 2 | `ai-tools`, `oxcaml`, `property-testing`, `ocaml-practice` |
| 2023-08-15 | [A Poet's Guide to Product Management](janestreet/podcast/17-a-poets-guide-to-product-management.md) | 1 | `culture`, `hiring` |
| 2023-11-28 | [Performance Engineering on Hard Mode](janestreet/podcast/18-performance-engineering-on-hard-mode.md) | 5 | `performance`, `latency`, `observability`, `allocation` |
| 2024-07-12 | [From the Lab to the Trading Floor: Designing for Expert Users](janestreet/podcast/19-from-the-lab-to-the-trading-floor.md) | 1 | `ui`, `culture`, `hiring`, `observability` |
| 2024-10-07 | [Solving Puzzles in Production](janestreet/podcast/20-solving-puzzles-in-production.md) | 7 | `ops`, `observability`, `culture`, `testing` |
| 2024-10-14 | [The Uncertain Art of Accelerating ML Models](janestreet/podcast/21-the-uncertain-art-of-accelerating-ml-models.md) | 2 | `ml`, `performance`, `data-platform`, `research-tooling` |
| 2025-03-12 | [Finding Signal in the Noise](janestreet/podcast/22-finding-signal-in-the-noise.md) | 4 | `research-tooling`, `data-platform`, `ml`, `market-data`, `trading` |
| 2025-05-28 | [Building Tools for Traders](janestreet/podcast/23-building-tools-for-traders.md) | 4 | `expect-tests`, `property-testing`, `ui`, `ocaml-practice`, `simulation` |
| 2025-07-25 | [The Thermodynamics of Trading](janestreet/podcast/24-the-thermodynamics-of-trading.md) | 3 | `hardware`, `ops`, `observability`, `latency` |
| 2025-09-03 | [Why ML Needs a New Programming Language](janestreet/podcast/25-why-ml-needs-a-new-programming-language.md) | 2 | `ml`, `hardware`, `performance`, `ai-tools`, `oxcaml` |
| 2026-03-17 | [Why Testing is Hard and How to Fix it](janestreet/podcast/26-why-testing-is-hard-and-how-to-fix-it.md) | 6 | `testing`, `simulation`, `property-testing`, `ai-tools`, `culture` |
| 2026-06-01 | [The Network as a Program](janestreet/podcast/27-the-network-as-a-program.md) | 1 | `networking`, `multicast`, `formal-methods`, `deployment` |
| 2026-06-24 | [Building a data warehouse from scratch](janestreet/podcast/28-building-a-data-warehouse-from-scratch.md) | 3 | `data-platform`, `parquet`, `architecture`, `sequencer`, `research-tooling` |
| 2026-09-02 | [Wrestling the world into rows](janestreet/podcast/29-wrestling-the-world-into-rows.md) | 4 | `market-data`, `data-platform`, `trading`, `risk`, `research-tooling` |
| 2026-09-23 | [Learning Goals and the Goals of Learning: Teaching in the Age of AI](janestreet/podcast/30-learning-goals-and-the-goals-of-learning-teaching-in-the-age-of-ai.md) | 1 | `education`, `ai-tools`, `culture`, `testing` |

### Blog posts

| Published | Note | Actions | Tags |
| --- | --- | --- | --- |
| 2026-10-05 | [Scaling and benchmarking a critical message bus using a new indexing strategy](janestreet/blog/2026-10-scaling-and-benchmarking-a-critical-message-bus.md) | 4 | `sequencer`, `replay`, `performance`, `property-testing`, `data-platform` |
| 2026-10-01 | [A resilient kernel log reporter](janestreet/blog/2026-10-linux-engineering-kernel-reporter.md) | 2 | `ops`, `observability`, `deployment` |
| 2026-10-01 | [A FUSE server for our in-house storage backend](janestreet/blog/2026-10-linux-engineering-depot-fuse.md) | 4 | `testing`, `expect-tests`, `allocation`, `async`, `performance` |
| 2026-10-02 | [How recurring network maintenance exposed 6 bugs](janestreet/blog/2026-10-how-recurring-network-maintenance-exposed-6-bugs.md) | 5 | `async`, `networking`, `ops`, `observability`, `testing` |
| 2026-10-06 | [Building and testing a config management orchestrator for Windows](janestreet/blog/2026-10-config-management-orchestrator-for-windows.md) | 3 | `ops`, `testing`, `deployment`, `ocaml-practice` |
| 2026-10-02 | [Results from the ASIC puzzle](janestreet/blog/2026-10-asic-puzzle-results.md) | 0 | `hardware`, `education`, `hiring` |
| 2026-09-30 | [What the interns have wrought, special jumbo 2026 edition](janestreet/blog/2026-09-wrought-2026.md) | 0 | `hiring`, `culture`, `oxcaml`, `ml` |
| 2026-09-30 | [What the SP interns have wrought, 2026 edition](janestreet/blog/2026-09-wrought-2026-sp.md) | 1 | `risk`, `hiring`, `culture` |
| 2026-09-30 | [Trading off compute for memory with activation checkpointing](janestreet/blog/2026-09-trading-off-compute-for-memory-with-activation-checkpointing.md) | 0 | `ml`, `performance` |
| 2026-09-30 | [What the TDOE interns have wrought, 2026 edition](janestreet/blog/2026-09-tdoe-intern-projects-2026.md) | 3 | `trading`, `market-data`, `testing`, `hiring` |
| 2026-09-10 | [Can you design a chip? Announcing the protocol emulator ASIC competition](janestreet/blog/2026-09-protocol-emulator-asic-competition.md) | 0 | `hardware`, `education`, `hiring` |
| 2026-09-30 | [Mitigating memorization in LLMs](janestreet/blog/2026-09-mitigating-memorization-in-llms.md) | 0 | `ml`, `research-tooling` |
| 2026-09-30 | [Can you use autoregressive diffusion to generate market data?](janestreet/blog/2026-09-can-you-use-autoregressive-diffusion-to-generate-market-data.md) | 2 | `simulation`, `market-data`, `ml` |
| 2026-09-14 | [A study of sequence weighting at scale](janestreet/blog/2026-09-a-study-of-sequence-weighting-at-scale.md) | 0 | `ml`, `research-tooling` |
| 2026-08-05 | [Can you reverse engineer an ASIC?](janestreet/blog/2026-08-can-you-reverse-engineer-an-asic.md) | 0 | `hardware`, `education`, `hiring` |
| 2026-06-15 | [Using OxCaml to implement type-safe reference counting between OCaml and Python](janestreet/blog/2026-06-oxcaml-typesafe-reference-counting-python.md) | 2 | `oxcaml`, `python-interop`, `gc`, `allocation` |
| 2026-06-07 | [Formal methods and the future of programming](janestreet/blog/2026-06-formal-methods-at-jane-street.md) | 3 | `formal-methods`, `ai-tools`, `oxcaml`, `ocaml-practice` |
| 2026-05-26 | [strace-ui, Bonsai_term, and the TUI renaissance](janestreet/blog/2026-05-strace-ui-bonsai-term-and-the-tui-renaissance.md) | 4 | `ui`, `expect-tests`, `ai-tools`, `observability` |
| 2026-04-22 | [Using group theory to explore the space of positional encodings for attention](janestreet/blog/2026-04-using-group-theory-to-explore-positional-encodings-attention.md) | 0 | `ml`, `education` |
| 2026-02-05 | [I design with Claude more than Figma now](janestreet/blog/2026-02-i-design-with-claude-code-more-than-figma-now.md) | 1 | `ai-tools`, `ui`, `culture` |
| 2026-02-24 | [Can you reverse engineer our neural network?](janestreet/blog/2026-02-can-you-reverse-engineer-our-neural-network.md) | 0 | `ml`, `education`, `hiring` |
| 2026-02-11 | [Results from the Advent of FPGA Challenge](janestreet/blog/2026-02-advent-of-fpga-challenge-2025-results.md) | 0 | `fpga`, `hardware`, `education` |
| 2026-01-06 | [Fun with Algebraic Effects - from Toy Examples to Hardcaml Simulations](janestreet/blog/2026-01-fun-with-algebraic-effects-hardcaml.md) | 3 | `oxcaml`, `async`, `simulation`, `testing`, `ocaml-practice` |
| 2025-12-03 | [Getting from tested to battle-tested](janestreet/blog/2025-12-getting-from-tested-to-battle-tested.md) | 5 | `testing`, `simulation`, `property-testing`, `state-machines`, `sequencer` |
| 2025-11-24 | [Advent of FPGA — A Jane Street Challenge](janestreet/blog/2025-11-advent-of-fpga-challenge-2025.md) | 0 | `fpga`, `hardware`, `education` |
| 2025-08-27 | [What the interns have wrought, 2025 edition](janestreet/blog/2025-08-wrought-2025.md) | 3 | `property-testing`, `oxcaml`, `simulation`, `trading`, `data-platform` |
| 2025-07-02 | [A Higgs-bugson in the Linux Kernel](janestreet/blog/2025-07-a-higgs-bugson-in-the-linux-kernel.md) | 2 | `networking`, `simulation`, `testing`, `ops` |
| 2025-06-14 | [Introducing OxCaml](janestreet/blog/2025-06-introducing-oxcaml.md) | 2 | `oxcaml`, `build`, `performance`, `allocation` |
| 2025-03-22 | [Advent of Hardcaml](janestreet/blog/2025-03-advent-of-hardcaml-2024.md) | 0 | `fpga`, `hardware`, `education` |
| 2025-01-24 | [How we accidentally built a better build system for OCaml](janestreet/blog/2025-01-how-we-accidentally-built-a-better-build-system-for-ocaml.md) | 2 | `build`, `ocaml-practice`, `performance` |
| 2024-10-04 | [Developer education at Jane Street](janestreet/blog/2024-10-developer-education-at-jane-street.md) | 4 | `education`, `testing`, `async`, `market-data`, `performance` |
| 2024-08-26 | [What the interns have wrought, 2024 edition](janestreet/blog/2024-08-what-the-interns-have-wrought-2024-edition.md) | 3 | `replay`, `state-machines`, `observability`, `data-platform`, `risk` |
| 2024-08-29 | [ICFP 2024](janestreet/blog/2024-08-icfp-2024.md) | 1 | `oxcaml`, `allocation`, `ppx`, `performance` |
| 2024-07-22 | [Visualizing piecewise linear neural networks](janestreet/blog/2024-07-visualizing-piecewise-linear-neural-networks.md) | 0 | `ml`, `education` |
| 2023-09-12 | [What the interns have wrought, 2023 edition](janestreet/blog/2023-09-what-the-interns-have-wrought-2023.md) | 2 | `observability`, `data-platform`, `async`, `research-tooling`, `trading` |
| 2023-09-01 | [Oxidizing OCaml: Data Race Freedom](janestreet/blog/2023-09-oxidizing-ocaml-parallelism.md) | 1 | `oxcaml`, `ocaml-practice`, `ai-tools` |
| 2023-07-06 | [We're sponsoring SoME3](janestreet/blog/2023-07-were-sponsoring-some3.md) | 0 | `education`, `culture` |
| 2023-06-21 | [Oxidizing OCaml: Rust-Style Ownership](janestreet/blog/2023-06-oxidizing-ocaml-ownership.md) | 0 | `oxcaml`, `allocation`, `ocaml-practice` |
| 2023-05-26 | [Oxidizing OCaml: Locality](janestreet/blog/2023-05-oxidizing-ocaml-locality.md) | 2 | `oxcaml`, `allocation`, `gc`, `performance` |
| 2023-04-14 | [Building reproducible Python environments with XARs](janestreet/blog/2023-04-building-reproducible-python-environments-with-xars.md) | 2 | `deployment`, `build`, `python-interop`, `research-tooling` |
| 2023-01-09 | [What if writing tests was a joyful experience?](janestreet/blog/2023-01-the-joy-of-expect-tests.md) | 1 | `expect-tests`, `testing`, `market-data`, `replay` |
| 2022-12-07 | [Accelerating zk-SNARKs - MSM and NTT algorithms on FPGAs with Hardcaml](janestreet/blog/2022-12-zero-knowledge-fpgas-hardcaml.md) | 0 | `fpga`, `hardware`, `performance` |
| 2022-11-23 | [Visualizing information propagation in markets](janestreet/blog/2022-11-visualizing-information-propagation-in-markets.md) | 3 | `market-data`, `latency`, `clocks`, `trading`, `research-tooling` |
| 2022-11-17 | [Computations that differentiate, debug, and document themselves](janestreet/blog/2022-11-computations-that-differentiate-debug-and-document-themselves.md) | 2 | `ocaml-practice`, `expect-tests`, `risk`, `trading`, `research-tooling` |
| 2022-08-25 | [What the interns have wrought, 2022 edition](janestreet/blog/2022-08-what-the-interns-have-wrought-2022.md) | 3 | `property-testing`, `testing`, `performance`, `observability`, `market-data` |
| 2022-08-30 | [Introducing the Jane Street Graduate Research Fellowship](janestreet/blog/2022-08-graduate-research-fellowship.md) | 0 | `hiring`, `education` |
| 2022-03-04 | [Research internships in our Tools and Compilers group](janestreet/blog/2022-03-research-internships-tnc.md) | 0 | `hiring`, `oxcaml`, `education` |
| 2022-01-14 | [How Jane Street Pairs Interns to Projects and Teams During the Software Engineering Internship](janestreet/blog/2022-01-project-pairing.md) | 0 | `hiring`, `culture` |
| 2022-01-11 | [Magic-trace: Diagnosing tricky performance issues easily with Intel Processor Trace](janestreet/blog/2022-01-magic-trace.md) | 2 | `performance`, `latency`, `async`, `observability`, `hardware` |
| 2021-10-21 | [Hiring a Developer Educator](janestreet/blog/2021-10-hiring-a-developer-educator.md) | 0 | `hiring`, `education` |
| 2021-08-09 | [What the interns have wrought, 2021 edition](janestreet/blog/2021-08-what-the-interns-have-wrought-2021.md) | 2 | `testing`, `ppx`, `observability`, `culture` |
| 2021-08-26 | [Goodbye Core_kernel](janestreet/blog/2021-08-goodbye-core-kernel.md) | 1 | `ocaml-practice`, `build` |
| 2021-06-15 | [Looking for a developer experience engineer](janestreet/blog/2021-06-looking-for-a-developer-experience-engineer.md) | 0 | `hiring`, `culture` |
| 2020-12-01 | [Growing the Hardcaml toolset](janestreet/blog/2020-12-growing-the-hardcaml-toolset.md) | 0 | `fpga`, `hardware`, `testing` |
| 2020-11-24 | [Announcing Our Market Prediction Kaggle Competition](janestreet/blog/2020-11-announcing-our-market-prediction-kaggle-competition.md) | 0 | `ml`, `hiring` |
| 2020-10-06 | [Finding memory leaks with Memtrace](janestreet/blog/2020-10-finding-memory-leaks-with-memtrace.md) | 3 | `gc`, `allocation`, `observability`, `ops` |
| 2020-09-15 | [Memory allocator showdown](janestreet/blog/2020-09-memory-allocator-showdown.md) | 2 | `gc`, `allocation`, `performance` |
| 2020-08-17 | [What the interns have wrought, 2020 edition](janestreet/blog/2020-08-what-the-interns-have-wrought-2020.md) | 2 | `property-testing`, `testing`, `networking`, `culture` |
| 2020-08-31 | [Announcing Signals and Threads, a new podcast from Jane Street](janestreet/blog/2020-08-announcing-signals-and-threads.md) | 0 | `education`, `culture` |
| 2020-07-24 | [The Jane Street Interview Process — 2020 Edition](janestreet/blog/2020-07-jane-street-interview-process-2020.md) | 0 | `hiring`, `culture` |
| 2020-06-01 | [Using ASCII waveforms to test hardware designs](janestreet/blog/2020-06-using-ascii-waveforms-to-test-hardware-designs.md) | 2 | `expect-tests`, `testing`, `fpga` |
| 2020-06-22 | [Really low latency multipliers and cryptographic puzzles](janestreet/blog/2020-06-really-low-latency-multipliers-and-cryptographic-puzzles.md) | 0 | `fpga`, `hardware`, `latency` |
| 2020-04-17 | [Chrome extensions: Finding the missing proof](janestreet/blog/2020-04-chrome-extensions-finding-the-missing-proof.md) | 0 | `ops`, `deployment` |
| 2020-02-20 | [Watch all of Jane Street's tech talks](janestreet/blog/2020-02-watch-all-of-jane-streets-tech-talks.md) | 0 | `education`, `architecture` |
| 2020-02-03 | [Troubleshooting systemd with SystemTap](janestreet/blog/2020-02-troubleshooting-systemd-with-systemtap.md) | 3 | `ops`, `observability`, `performance` |
| 2019-12-16 | [Using Python and OCaml in the same Jupyter notebook](janestreet/blog/2019-12-using-python-and-ocaml-in-the-same-jupyter-notebook.md) | 2 | `python-interop`, `research-tooling`, `ppx` |
| 2019-12-06 | [Deep-Learning the Hardest Go Problem in the World](janestreet/blog/2019-12-deep-learning-the-hardest-go-problem-in-the-world.md) | 0 | `ml`, `research-tooling` |
| 2019-10-14 | [Commas in big numbers everywhere: An OpenType adventure](janestreet/blog/2019-10-commas-in-big-numbers-everywhere.md) | 0 | `ui`, `research-tooling` |
| 2019-08-30 | [What the interns have wrought, 2019 edition](janestreet/blog/2019-08-what-the-interns-have-wrought-2019.md) | 2 | `observability`, `latency`, `testing`, `async`, `research-tooling` |
| 2019-08-19 | [Using OCaml to drive a Raspberry Pi robot car](janestreet/blog/2019-08-using-ocaml-to-drive-a-raspberry-pi-robot-car.md) | 0 | `hardware`, `async`, `education` |
| 2019-08-16 | [Do applied programming languages research at Jane Street](janestreet/blog/2019-08-applied-pl-research.md) | 0 | `hiring`, `oxcaml` |
| 2019-07-09 | [Of Pythons and Camels](janestreet/blog/2019-07-of-pythons-and-camels.md) | 0 | `ml`, `python-interop` |
| 2019-07-12 | [A look at OCaml 4.08](janestreet/blog/2019-07-a-look-at-ocaml-4-08.md) | 1 | `ocaml-practice`, `build` |
| 2019-05-13 | [Thoughts from AAAI 2019](janestreet/blog/2019-05-thoughts-from-aaai-19.md) | 1 | `ml`, `simulation`, `testing` |
| 2019-04-17 | [Learning ML Depth-First](janestreet/blog/2019-04-learning-ml-depth-first.md) | 0 | `ml`, `education`, `culture` |
| 2019-02-28 | [Machining the ultimate hackathon prize](janestreet/blog/2019-02-hackathon-keyboards.md) | 0 | `culture`, `hardware` |
| 2019-02-28 | [Accelerating Self-Play Learning in Go](janestreet/blog/2019-02-accelerating-self-play-learning-in-go.md) | 0 | `ml`, `culture` |
| 2019-01-29 | [L2 Regularization and Batch Norm](janestreet/blog/2019-01-l2-regularization-and-batch-norm.md) | 0 | `ml` |
| 2019-01-15 | [A tutorial for building web applications with Incr_dom](janestreet/blog/2019-01-a-tutorial-for-building-web-applications-with-incrdom.md) | 0 | `ui`, `ocaml-practice` |
| 2018-09-26 | [How to shuffle a big dataset](janestreet/blog/2018-09-how-to-shuffle-a-big-dataset.md) | 1 | `ml`, `data-platform`, `performance` |
| 2018-09-20 | [Deep learning experiments in OCaml](janestreet/blog/2018-09-deep-learning-experiments-in-ocaml.md) | 0 | `ml`, `ocaml-practice`, `python-interop` |
| 2018-08-06 | [What the interns have wrought, 2018 edition](janestreet/blog/2018-08-what-the-interns-have-wrought-2018.md) | 0 | `hiring`, `networking`, `ui`, `testing` |
| 2018-06-29 | [Plans for OCaml 4.08](janestreet/blog/2018-06-plans-for-ocaml-408.md) | 0 | `ocaml-practice`, `oxcaml` |
| 2018-04-22 | [Repeatable exploratory programming](janestreet/blog/2018-04-repeatable-exploratory-programming.md) | 2 | `expect-tests`, `testing`, `market-data`, `research-tooling` |
| 2018-04-04 | [OCaml all the way down](janestreet/blog/2018-04-ocaml-all-the-way-down.md) | 0 | `fpga`, `culture`, `hardware` |
| 2018-03-27 | [Putting the I back in IDE: Towards a Github Explorer](janestreet/blog/2018-03-putting-the-i-back-in-ide-towards-a-github-explorer.md) | 0 | `culture`, `build` |
| 2018-02-15 | [Proofs (and Refutations) using Z3](janestreet/blog/2018-02-proofs-and-refutations-using-z3.md) | 2 | `formal-methods`, `property-testing`, `testing` |
| 2018-02-16 | [Learn OCaml in NYC](janestreet/blog/2018-02-learn-ocaml-nyc.md) | 0 | `education`, `ocaml-practice` |
| 2017-10-29 | [How Jane Street Does Code Review (Jane Street Tech Talk)](janestreet/blog/2017-10-jane-street-tech-talk-how-jane-street-does-code-review.md) | 0 | `culture` |
| 2017-08-24 | [Ironing out your development style](janestreet/blog/2017-08-ironing-out-your-development-style.md) | 1 | `expect-tests`, `testing`, `culture`, `build` |
| 2017-05-11 | [When Bash Scripts Bite](janestreet/blog/2017-05-when-bash-scripts-bite.md) | 2 | `ops`, `testing`, `build` |
| 2017-04-20 | [This is not the performance you were looking for: the tricks systems play on us](janestreet/blog/2017-04-this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us.md) | 2 | `ops`, `performance`, `deployment`, `observability` |
| 2017-04-25 | [Caveat Configurator: how to replace configs with code, and why you might not want to](janestreet/blog/2017-04-caveat-configurator-how-to-replace-configs-with-code-and-why-you-might-not-want-to.md) | 1 | `ops`, `deployment`, `testing` |
| 2017-03-20 | [Trivial meta-programming with cinaps](janestreet/blog/2017-03-trivial-meta-programming-with-cinaps.md) | 0 | `ppx`, `ocaml-practice`, `build` |
| 2017-01-11 | [How to Build an Exchange](janestreet/blog/2017-01-how-to-build-an-exchange.md) | 1 | `architecture`, `sequencer`, `multicast`, `trading` |
| 2017-01-09 | [A brief trip through Spacetime](janestreet/blog/2017-01-a-brief-trip-through-spacetime.md) | 1 | `allocation`, `gc`, `observability`, `performance` |
| 2016-06-21 | [Let syntax, and why you should use it](janestreet/blog/2016-06-let-syntax-and-why-you-should-use-it.md) | 0 | `async`, `ppx`, `ocaml-practice` |
| 2016-03-09 | [Seven Implementations of Incremental](janestreet/blog/2016-03-seven-implementations-of-incremental.md) | 0 | `ocaml-practice`, `performance` |
| 2016-02-24 | [A better inliner for OCaml, and why it matters](janestreet/blog/2016-02-flambda.md) | 1 | `oxcaml`, `allocation`, `performance` |
| 2015-12-02 | [Testing with expectations](janestreet/blog/2015-12-testing-with-expectations.md) | 1 | `expect-tests`, `testing` |
| 2015-10-26 | [Quickcheck for Core](janestreet/blog/2015-10-quickcheck-for-core.md) | 3 | `property-testing`, `testing`, `ocaml-practice` |
| 2015-07-18 | [Introducing Incremental](janestreet/blog/2015-07-introducing-incremental.md) | 0 | `architecture`, `risk`, `ui`, `performance` |
| 2015-05-05 | [CPU Registers and OCaml](janestreet/blog/2015-05-cpu-registers-and-ocaml-2.md) | 0 | `performance`, `ocaml-practice`, `hardware` |
| 2015-04-09 | [Faster OCaml to C calls](janestreet/blog/2015-04-faster-ocaml-to-c-calls.md) | 0 | `performance`, `allocation`, `ocaml-practice` |
| 2015-04-10 | [Building a lower-latency GC](janestreet/blog/2015-04-building-a-lower-latency-gc.md) | 2 | `gc`, `latency`, `allocation`, `observability` |
| 2015-03-30 | [Why GADTs matter for performance](janestreet/blog/2015-03-why-gadts-matter-for-performance.md) | 0 | `performance`, `ocaml-practice`, `allocation` |
| 2014-10-16 | [What the interns have wrought: RPC_parallel and Core_profiler](janestreet/blog/2014-10-what-the-interns-have-wrought-rpc-parallel-and-core-profiler.md) | 0 | `hiring`, `observability`, `performance`, `allocation` |
| 2014-09-29 | [What is gained and lost with 63-bit integers?](janestreet/blog/2014-09-what-is-gained-and-lost-with-63-bit-integers.md) | 3 | `performance`, `ocaml-practice`, `trading` |
| 2014-07-06 | [Making “never break the build” scale](janestreet/blog/2014-07-making-never-break-the-build-scale.md) | 2 | `build`, `testing`, `culture` |
| 2014-07-09 | [Inspecting Internal TCP State on Linux](janestreet/blog/2014-07-inspecting-internal-tcp-state-on-linux.md) | 1 | `networking`, `ops`, `observability` |
| 2014-06-24 | [Iron out your release process](janestreet/blog/2014-06-ironing-out-your-release-process.md) | 2 | `build`, `deployment`, `culture` |
| 2014-05-17 | [Core_bench: better micro-benchmarks through linear regression](janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md) | 2 | `performance`, `allocation`, `gc`, `testing` |
| 2014-04-23 | [How to fail -- introducing Or_error.t](janestreet/blog/2014-04-how-to-fail-introducing-or-error-dot-t.md) | 3 | `ocaml-practice`, `testing`, `expect-tests` |
| 2014-01-09 | [Async Parallel](janestreet/blog/2014-01-async-parallel.md) | 0 | `async`, `architecture`, `ocaml-practice` |
| 2013-09-11 | [What's 2013 + 50? 1969, of course](janestreet/blog/2013-09-whats-2013-50-1969-of-course.md) | 0 | `clocks`, `ops` |
| 2010-07-15 | [Making something out of nothing (or, why None is better than NaN and NULL)](janestreet/blog/2010-07-making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null.md) | 2 | `ocaml-practice`, `testing`, `risk` |
| 2009-11-07 | [Core Gems: Time](janestreet/blog/2009-11-core-gems-time.md) | 1 | `clocks`, `ocaml-practice`, `stable-types` |
| 2008-12-03 | [Lightweight versioning for lightweight protocols](janestreet/blog/2008-12-lightweight-versioning-for-lightweight-protocols.md) | 0 | `stable-types`, `ocaml-practice`, `architecture` |
| 2008-08-18 | [The perils of polymorphic compare](janestreet/blog/2008-08-the-perils-of-polymorphic-compare.md) | 0 | `ocaml-practice`, `performance` |
| 2008-08-05 | [Better float unboxing](janestreet/blog/2008-08-better-float-unboxing.md) | 0 | `allocation`, `performance`, `ocaml-practice` |
| 2008-03-15 | [Typing RPCs](janestreet/blog/2008-03-typing-rpcs.md) | 0 | `ocaml-practice`, `architecture`, `networking` |
