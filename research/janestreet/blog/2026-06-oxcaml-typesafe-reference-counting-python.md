# Using OxCaml to implement type-safe reference counting between OCaml and Python

- Source: <https://blog.janestreet.com/oxcaml-typesafe-reference-counting-python/>
- Published: 2026-06-15
- Kind: blog post

## Summary

- PyOCaml exposes OCaml libraries to Python. A Python object seen from OCaml is a
  `Py.Object.t` custom block holding a pointer; wrapping increments the Python refcount and
  only the OCaml GC finalizer decrements it, so large data frames or GPU buffers can stay
  alive long after Python dropped them. The GC also sees only 8 bytes and feels no
  pressure.
- Python C extensions either borrow a reference (no incref, valid for the call) or steal
  one (ownership moves to the callee); getting this wrong by hand leaks or dangles.
- OxCaml modes encode both: an argument taken `@ local` cannot escape the call, so glue
  code passes it without an incref and without a finalizer, then nulls the pointer; a
  result returned `@ unique` is the only handle, so glue code steals it back to Python
  without an incref (the finalizer must tolerate the nulled pointer).
- Signatures change accordingly, for example `Py.Int.to_int` takes its argument
  `@ local`.
- Uniqueness is consumed by passing a value to a function; the new `borrow_` keyword
  lends a unique value to a function that takes it locally, so it stays unique afterwards.
- For manual control there are `Py.newref` (local to unique) and `Py.decref` (consumes a
  local unique value), plus a `ppx_release` binding form that releases objects promptly
  even when the body raises.
- The contrast drawn with Rust: ownership tracking is opt-in where it matters, while most
  code keeps relying on the GC.

## Relevance to us

- We build on the OxCaml switch but have no Python bridge; the parts that matter are the
  mode syntax (`@ local`, `@ unique`, `borrow_`) and the pattern of encoding resource
  ownership in modes, which [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md)
  should document for agents.
- The finalizer-delays-release problem applies to any C-backed resource we wrap (zstd or
  OpenSSL handles in [market-recorder](../../../repos/market-recorder.md) and
  [venue-net](../../../repos/venue-net.md)), which are closed explicitly today.
- **Action:** in `oxcaml-claude-skills`, add a short entry with a compiling example of a
  `@ local` argument, a `@ unique` return and `borrow_`, noting which of these the
  `5.2.0+ox` switch accepts (record any rejection in `GOTCHAS.md`).

Tags: `oxcaml`, `python-interop`, `gc`, `allocation`
