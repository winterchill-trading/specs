# Memory allocator showdown

- Source: <https://blog.janestreet.com/memory-allocator-showdown/>
- Published: 2020-09-15
- Kind: blog post

## Summary

- OCaml 4.10 added a best-fit major heap allocator next to the default next-fit; Jane Street
  saw broad gains after switching, but the post is about how hard it was to show that.
- One benchmark looked slower under best-fit (about 36 s against 34 s), yet it used less
  memory: a single run measures one point on a trade-off, not the whole picture.
- In a garbage-collected language the GC speed (`space_overhead`, default 80) trades space
  for time, so each program has a space/time curve; sweeping it from 20 to 320 showed
  best-fit dominating next-fit at every point.
- `top_heap_size` from `Gc.stat` is a poor memory metric: it grows in coarse chunks and
  overstates use. RSS is better, since Linux only backs pages with RAM when touched.
- Next-fit tends to consume the big free block at the end of the heap, touching all of it;
  best-fit fills holes first, so it saves RAM that heap-size metrics do not reveal.
- A simple model of major GC cost gives heap size as `b / (t - a) + c`: `a` is the minimum
  runtime with no collection, `c` the minimum space (live data plus fragmentation), and `b`
  the shape; best-fit improves both `a` and `c`.

## Relevance to us

- The allocator choice itself is a 4.x runtime knob; the OCaml 5 runtime that OxCaml builds
  on has a different major heap, so the specific switch does not apply to us.
- The method does apply: when we tune GC for
  [market-recorder](../../../repos/market-recorder.md) or the simulators, compare RSS across
  several `space_overhead` settings rather than one run's wall time.
- **Action:** none for now; revisit when we first tune `OCAMLRUNPARAM` for a deployed
  service.

Tags: `gc`, `allocation`, `performance`
