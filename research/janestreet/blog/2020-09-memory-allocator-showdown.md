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

- The allocator switch itself is a 4.x runtime knob; the OCaml 5 runtime under OxCaml has a
  different major heap, so the specific choice does not apply to us.
- **Performance:** in a GC language one run gives a single point on a space/time curve, so
  comparisons need several `space_overhead` settings and RSS, not `top_heap_size`.
  **Action:** add a section to the [infra](../../../repos/infra.md) deployment notes
  describing how to compare GC settings for the recorder: run the `market-recorder`
  sims e2e script under `OCAMLRUNPARAM=o=40,80,160` and record peak RSS and CPU time.
- **Build and deploy:** container memory limits are enforced on RSS, which can differ from
  what `Gc.stat` reports. **Action:** export process RSS (from `/proc/self/statm`) next to
  the heap counters on `/metrics` in [market-recorder](../../../repos/market-recorder.md).

Tags: `gc`, `allocation`, `performance`
