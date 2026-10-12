# Using OxCaml to implement type-safe reference counting between OCaml and Python

- Source: <https://blog.janestreet.com/oxcaml-typesafe-reference-counting-python/>
- Published: 2026-06-15
- Kind: blog post

## Summary

- Python is the firm's second language (data analysis, ML); PyOCaml lets OCaml library
  authors expose Python interfaces. Mixing the two memory managers delayed deallocation of
  Python objects, which matters for huge data frames and scarce GPU memory.
- OxCaml modes now let library authors make prompt release a compile-time guarantee:
  Python code written against such libraries cannot hold objects too long by construction.
- Python objects are reference counted: a new reference increments, dropping one
  decrements, zero frees. In C extensions a function either borrows an argument (no
  increment, valid only during the call) or steals it (takes over the caller's reference).
- Manual reference handling in C is error-prone: a missing decrement leaks, a missing
  increment on a borrowed or stolen object dangles, and free-threaded Python adds more
  hazards.
- In PyOCaml a Python object is a `Py.Object.t` custom block holding an 8-byte pointer on
  the OCaml heap. Wrapping increments the Python count, and only the GC finalizer
  decrements it, so freeing the Python object waits for an OCaml collection.
- The glue code must increment both the argument and the result because either could be
  stored globally by OCaml code; after a call both stay alive until the OCaml GC runs. The
  GC sees only 8 bytes per object and feels no pressure to collect.
- With modes: an argument typed `@ local` cannot escape the call, so glue code passes it
  without an increment and without a finalizer, then nulls the stored pointer; for example
  `Py.Int.to_int` now takes its argument `@ local`.
- A result typed `@ unique` is the only handle, so glue code steals it back to Python
  without an increment, again nulling the pointer and making the finalizer tolerate null.
- Passing a unique value to any function consumes its uniqueness; the new `borrow_`
  keyword lends it to a function that takes it locally, so it is still unique afterwards
  (for example appending to a fresh list before returning it).
- Escape hatches for manual control: `Py.newref` turns a local reference into a unique
  global one, and `Py.decref` consumes a local unique value, useful to free a large frame
  early before a risky call.
- `ppx_release` adds a binding form that releases the bound Python objects promptly even
  when the body raises.
- Compared with Rust, ownership tracking here is opt-in: most code can still rely on the
  GC, and only performance-critical paths pay the annotation cost, matching OxCaml's goal of
  control only where needed.

## Relevance to us

- **OCaml practice:** modes can encode resource ownership (`@ local` cannot escape,
  `@ unique` is the only handle, `borrow_` lends without consuming) and agents need
  working examples to use them. **Action:** add a short entry with a compiling example of a
  `@ local` argument, a `@ unique` return and `borrow_` to
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md), noting which ones the
  `5.2.0+ox` switch accepts and logging any rejection in `GOTCHAS.md`.
- **OCaml practice:** finalizer-based release ties a large external resource to GC timing.
  **Action:** list the C-backed handles in [market-recorder](../../../repos/market-recorder.md)
  (zstd compression, files) and [venue-net](../../../repos/venue-net.md) (SSL sockets) in
  their repo pages and note for each whether it is closed explicitly or by finalizer.
- **Research tooling:** a Python bridge would only matter if research moves off DuckDB SQL
  into Python over our Parquet; context only, no change.

Tags: `oxcaml`, `python-interop`, `gc`, `allocation`
