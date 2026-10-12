# Using Python and OCaml in the same Jupyter notebook

- Source: <https://blog.janestreet.com/using-python-and-ocaml-in-the-same-jupyter-notebook/>
- Published: 2019-12-16
- Kind: blog post

## Summary

- Jane Street runs all production systems in OCaml, but quantitative research often prefers
  quick, throwaway Python in Jupyter (NumPy, plotting, ML). The goal is to let researchers
  call existing OCaml services from Python, with bindings written by OCaml developers who
  need little Python knowledge.
- The foundation is pyml, OCaml bindings to the Python C API: OCaml can start the Python
  runtime, build Python values, call methods and evaluate Python expressions; type mismatches
  surface as OCaml exceptions with useful messages.
- `ppx_python` derives `python_of_t` and `t_of_python` converters: basic types map directly,
  `unit` to `None`, tuples to tuples, lists and arrays to lists, records to string-keyed
  dicts, options to value-or-`None` (so `Some None` and `None` collide), and
  `[@python.default]` makes record fields optional on the Python side.
- `pythonlib` defines Python functions in OCaml with an applicative argument spec modelled on
  Core's `Command`: argument types are checked and converted, wrong arity or keyword names
  give clear errors, and docstrings with parameter types are generated for Jupyter
  completion.
- The OCaml module is built as a shared object with a small C init stub, then imported from
  Python like any extension module; a pip package named `ocaml` packages a demo.
- Bindings to the OCaml toploop let Python evaluate OCaml phrases (`eval`) and fetch typed
  OCaml values as Python callables (`get`); Jupyter magics allow whole OCaml cells and inline
  OCaml expressions in Python cells, including passing closures both ways.
- An N-queens comparison showed OCaml much faster than Python even when the toploop compiles
  to bytecode; native toploop would be faster still.
- Internally most wrapped functions use Async and currently block; planned work includes
  bridging to Python asyncio, Python bindings for sexplib and `Time_ns`, and better handling
  of custom OCaml types in the magics.

## Relevance to us

- **Research tooling:** our research path is Parquet plus DuckDB from
  [market-data](../../../repos/market-data.md), which Python reaches through pyarrow or the
  DuckDB Python package without any OCaml bindings; the risk is type fidelity of
  `TIMESTAMP_NS` and `DECIMAL(18,8)` columns, not interop code. **Action:** add a step to the
  `market-data` end-to-end script that loads one day-close table with pyarrow and asserts
  `recv_ts` is nanosecond timestamp and prices are decimal.
- **Research tooling:** `Time_ns` conversion is a known pain point at the language boundary.
  **Action:** document in the `market-data` README how `exch_ts` and `recv_ts` map to pandas
  `datetime64[ns, UTC]`, with one example query.
- `ppx_python` and `pythonlib` would only matter if we exposed live OCaml services (for
  example the quoter in [mm-core](../../../repos/mm-core.md)) to notebooks; nothing planned
  needs that.

Tags: `python-interop`, `research-tooling`, `ppx`
