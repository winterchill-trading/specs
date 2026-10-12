# Magic-trace: Diagnosing tricky performance issues easily with Intel Processor Trace

- Source: <https://blog.janestreet.com/magic-trace/>
- Published: 2022-01-11
- Kind: blog post

## Summary

- Intel Processor Trace (IPT) records a program's full control flow with timing accurate to
  about 30 ns, but is rarely used because capture is fiddly and the output is huge text.
- magic-trace, open-sourced by Jane Street, snapshots roughly the last 10 ms before a chosen
  function is called and shows every call on a timeline in a fork of Google's Perfetto viewer
  patched to zoom to nanoseconds.
- Sampling profilers (one sample every 250 µs or so) are nearly useless for trading systems
  that must react well below that interval and cannot tell ten calls from one slow call;
  instrumentation tracing needs annotations and can distort tiny functions.
- IPT needs no instrumentation, costs 2-20% (usually under 5-10% on the author's programs),
  but requires a recent Intel CPU, is often unavailable in VMs, produces about 1 GB/s, and
  decodes about 60x slower than real time.
- The MVP limited scope: circular-buffer mode, snapshots triggered by a function call, and only
  call/return events; a first version wrapped `perf` (snapshot via SIGUSR2) and parsed its
  text, handling OCaml tail calls and exceptions; early traces showed OCaml startup dominated
  by module initializers page-faulting.
- A rewrite used `perf_event_open` and Intel's libipt directly (apparently a first), and
  snapshots on attach use hardware breakpoints on the trigger symbol: zero cost when not
  attached, works on any function, and can sample registers to capture arguments.
- Being early meant real kernel and hardware bugs: a null-pointer crash from a missing flag
  check in a recent kernel patch, and dropped trace packets on one CPU generation, probably
  an Intel erratum.
- Uses so far: a 100 ns regression from a lost inlining, a compiler upgrade slowdown (also
  inlining), and long Async cycles: call the snapshot when a cycle exceeds a threshold and
  look at what the last 10 ms were doing, which found a loop over an unexpectedly large
  collection.
- Advice for tool builders: start from `perf` with a dlfilter shared library rather than
  libipt; ideas include line-level views, feedback-directed optimization, PTWRITE-based
  instrumentation, PEBS-via-PT cache-miss sampling and whole-machine tracing.

## Relevance to us

- **Performance:** our market maker and recorder are single-threaded Async programs, so one
  slow job (a big snapshot resync, a Parquet flush) delays every feed; the post's long-cycle
  trigger is the cheap first step even without IPT. **Action:** in
  [market-recorder](../../../repos/market-recorder.md), count Async cycles longer than 50 ms
  (from `Scheduler.long_cycles`) and export the counter and the maximum on `/metrics`.
- **Market making and trading systems:** the same long-cycle signal matters more in the
  quoting loop, where a stalled cycle means stale quotes. **Action:** log a warning with the
  cycle duration from the `market-maker` binary in
  [market-maker](../../../repos/market-maker.md) whenever an Async cycle exceeds 20 ms.
- **Build and deploy:** magic-trace needs a recent Intel CPU with IPT exposed, which most
  cloud VMs do not provide, so it fits a local or bare-metal profiling box rather than the
  planned EC2 deployment in [infra](../../../repos/infra.md).

Tags: `performance`, `latency`, `async`, `observability`, `hardware`
