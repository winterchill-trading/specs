# Python, OCaml, and Machine Learning

- Source: <https://signalsandthreads.com/python-ocaml-and-machine-learning/>
- Published: 2020-10-07
- Kind: Signals and Threads episode 5

## Summary

- The guest used OCaml for financial contract modelling at LexiFi, a Python-like in-house
  language as an equity strategist at a bank, OCaml for trading systems at Jane Street,
  Python and Swift at DeepMind, and is back at Jane Street doing research half in Python and
  half in OCaml.
- The guest's open-source work includes OCaml and Rust bindings for PyTorch, contributions to
  the Rust linter Clippy, and OCaml bindings for TensorFlow and Apache Arrow.
- Python is used in notebooks: cells are evaluated interactively with plots inline, giving a
  fast loop between code and results; OCaml is used for long-lived production work, and OCaml
  jobs often keep running for years untouched.
- OCaml robustness comes from the language (result types force error handling) and from
  engineering practice (tests, thinking about corner cases); Python code tends to rely on
  trying a library call and checking interactively.
- Python's ecosystem snowballed into the default for data analysis and machine learning, with
  frameworks shipping Python APIs first; OCaml has fewer, often better libraries and fills gaps
  with bindings, including Matplotlib called through Python.
- Both workflows aim for fast iteration: visual results in notebooks, type errors on save in
  OCaml.
- Expect tests give OCaml a notebook-like loop (edit, rebuild, inspect captured output, accept
  the diff), useful even for exploratory work like web scraping, but in plain text and aimed at
  corner cases rather than one dataset.
- Dynamic typing lets exploratory code skip handling inputs it will never see, and generalize
  for free (integers to floats); static types give guarantees for all executions but require
  fitting code to the type system.
- Types help little with numerical bugs, which show up as slightly wrong floats, poor
  convergence or NaNs rather than type errors.
- Long training runs are where static checks pay off: a trivial bug at the end of days of
  compute is costly; one proposed split keeps models in Python and the surrounding resilient
  infrastructure in OCaml.
- Trading systems that use a model are in OCaml; options are calling Python from OCaml or
  reimplementing the model, in which case the exported model carries sample inputs and outputs
  and the OCaml side must reproduce them exactly on deployment.
- Interop uses the pyml library: OCaml calling Python, and more often Python loading an OCaml
  shared library that starts the OCaml runtime and registers functions, so OCaml developers
  expose services to notebooks without writing Python.
- Logic needed by many callers belongs in OCaml and is exposed to Python, avoiding duplicate
  implementations; the Emacs (Ecaml) and Vim integrations use the same cross-runtime pattern.
- Cross-runtime reference cycles leak because neither garbage collector sees the whole cycle;
  one such bug wasted tens of megabytes, and Ecaml has the same class of bug.
- Choose OCaml for code meant to last and for symbolic or combinatorial work (syntax
  extensions, systems with many cases) where exhaustive pattern matching catches bugs; trading
  systems in Python are discouraged.
- Jane Street's Python practice (tests, annotations, generated docs) is still catching up;
  when Python is glue around tested OCaml, less Python testing is needed, though short code
  still hides bugs.
- pandas and NumPy are powerful but have surprising corner cases found only when results look
  wrong; Excel's type inference has similar hazards (gene names read as dates, a ticker named
  True).
- Excel recomputes cells from a dependency graph and so stays consistent; notebooks can reach
  states no top-to-bottom run reproduces; Netflix's Polynote tracks cell state partially and
  Julia's Pluto reruns dependents.
- Differentiable programming moves gradient computation into the compiler; Swift was chosen for
  this at Google because it is compiled, closer to functional style, and less stateful than
  Python.
- Reference counting (Python, Swift) or borrow checking (Rust) frees large GPU tensors promptly;
  with OCaml's GC the guest forces a collection every training loop.
- Garbage collection suits memory but not scarce external resources like file descriptors or
  GPU memory; the host mentions planned OCaml work on effects and type-level resource
  management.

## Relevance to us

- Our boundary with Python is files rather than bindings:
  [market-data](../../../repos/market-data.md) writes Parquet through
  [parquet](../../../repos/parquet.md) and defines DuckDB views that pandas and notebooks can
  read directly.
- **Data platform:** When logic exists in two implementations, a golden sample of inputs and
  outputs keeps them aligned; candles exist both in OCaml and as SQL over Parquet. **Action:**
  add a test that compares `Candle_agg` output for one fixture trade log row for row with the
  same candles computed by DuckDB over that day's Parquet, in
  [market-data](../../../repos/market-data.md).
- **Research tooling:** Researchers should reach data without learning our OCaml code.
  **Action:** add a short `examples/query.py` that opens the generated DuckDB views and loads
  one day of trades into a pandas frame, in [market-data](../../../repos/market-data.md).
- **Market making and trading systems:** Shipping sample outputs with a model makes parameter
  changes visible. **Action:** add an expect test that prints the quotes produced for a fixed
  `Market_state` and `Inventory` under each `Params` preset, in
  [mm-core](../../../repos/mm-core.md).
- **OCaml practice:** The GC does not manage scarce resources such as file descriptors.
  **Action:** add a test that rolls 100 minute files and checks the process's open descriptor
  count stays constant, in [market-recorder](../../../repos/market-recorder.md).
- Notebook state drift is a reason to keep research queries as files re-run from scratch rather
  than as saved notebook state.

Tags: `python-interop`, `ml`, `research-tooling`, `parquet`, `expect-tests`
