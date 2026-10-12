# What the interns have wrought: RPC_parallel and Core_profiler

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-rpc_parallel-and-core_profiler/>
- Published: 2014-10-16
- Kind: blog post

## Summary

- Intern-recruiting post describing two summer projects.
- Rpc_parallel replaces Async_parallel's marshalling of arbitrary closures, which could
  silently ship too much data, fail on unmarshallable values, or duplicate mutable state,
  with explicitly typed RPC messages between worker processes.
- It was redesigned mid-summer after an intern visited another office and worked with an
  experienced user; it was then open-sourced.
- Core_profiler provides cheap explicit probes logged for offline analysis.
- Probe cost went from about 60 ns and two words of allocation, to 30 ns with
  zero-allocation generated serializers instead of bin_prot, to 20 to 25 ns with a
  hand-rolled format, to 12 ns by packing several values into one 63-bit int with aligned
  writes, verified by reading the assembly.
- Each probe change was checked against the generated assembly, and the offline analysis became
  about twice as fast as a side effect.

## Relevance to us

- Mostly a hiring post; the probe-cost numbers are a useful budget if we ever instrument the
  [mm-core](../../../repos/mm-core.md) loop, but nothing is planned.
- **Action:** none.

Tags: `hiring`, `observability`, `performance`, `allocation`
