# A brief trip through Spacetime

- Source: <https://blog.janestreet.com/a-brief-trip-through-spacetime/>
- Published: 2017-01-09
- Kind: blog post

## Summary

- Introduces Spacetime, then a new OCaml memory profiler for finding space leaks and
  unwanted allocations; useful though rough, and documented mainly by a readme.
- Demonstrated by profiling the js_of_ocaml compiler. It needs a dedicated
  Spacetime-enabled compiler switch to build the target.
- Profiling turns on at run time via an environment variable giving the heap sampling
  interval in milliseconds; each process (including forks) writes a file named by pid.
- Profiled programs run slower and use more system memory, but the OCaml heap itself is
  unchanged.
- The prof_spacetime tool, installed on a normal switch, post-processes the profile (this
  can take minutes; passing the executable adds locations for C code).
- Web viewer: a stacked graph of live words over time split by allocation site; clicking a
  band splits it by the caller one frame up, so you see which call to `List.map`
  allocated, and repeated clicks reveal the full backtrace.
- Live words and live blocks views target leaks; the cumulative allocated-words view
  targets allocation removal.
- A terminal viewer offers the same three modes with keyboard navigation over time and
  call frames.

## Relevance to us

- **Performance:** allocation-site profiling with backtraces is how to find leaks in
  long-running processes; Spacetime was later removed and memtrace now does this on a normal
  compiler, but none of our binaries can produce a trace. **Action:** add `memtrace` to
  [market-recorder](../../../repos/market-recorder.md) and call
  `Memtrace.trace_if_requested` at startup, so setting `MEMTRACE=<file>` captures a trace
  from a running deployment without a rebuild.
- Context: [market-maker](../../../repos/market-maker.md) could take the same one-line
  hook once the recorder shows it is useful.

Tags: `allocation`, `gc`, `observability`, `performance`
