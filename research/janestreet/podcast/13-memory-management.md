# Memory Management

- Source: <https://signalsandthreads.com/memory-management/>
- Published: 2022-01-05
- Kind: Signals and Threads episode 13

## Summary

- The basic options are fixed static placement (fine for microcontrollers), a stack for
  data whose lifetime matches a function call, and a heap for everything else. Unchecked
  `malloc`/`free` turns any slip (double free, use after free) into an exploitable bug.
- Safe languages either collect garbage automatically or check manual management
  statically, as Rust does with ownership and borrowing. OCaml sits at the
  collect-everything end, and the compiler team is adding more explicit control.
- Tracing collectors walk everything still live from the roots; reference counting walks
  everything that just died. Plain refcounting cannot free cycles, so systems either run
  an occasional tracer (as Python does) or ask programmers to mark weak references.
- Refcounting is usually slower, especially with threads, where every count update is
  atomic, but it reuses memory sooner and so needs less of it. Tracing is usually faster and
  offers a space-for-time dial; OCaml's GC has essentially one such knob.
- The belief that refcounting avoids pauses is a myth: dropping the last pointer to a
  large tree frees the whole tree at once. OCaml's incremental collector splits work into
  slices of a few hundred microseconds. Lazy refcounting gets the worst of both.
- Refcounting suits a single large pointer-free buffer that is reused for each file, while
  a tracing GC may cycle through a hundred of them. That is why GC languages favor APIs where
  the caller passes the buffer in.
- Refcounted finalization is less predictable than it looks, because any callee may have
  kept a reference. Ownership or uniqueness types are the real tool for scarce resources such
  as GPU memory.
- Static ownership also removes aliasing bugs and the defensive deep copies people make to
  avoid them. The other escape from shared mutable state is immutable data plus a GC, as
  with OCaml's maps; the guest would like both in one language.
- OCaml's major heap is an incremental mark-and-sweep collector: it marks from roots
  (stack and globals) using a mark stack, then sweeps unmarked blocks back to the
  allocator. A full collection of a gigabyte heap would pause for a second or two.
- The minor heap applies the generational hypothesis: bump-pointer allocation (a
  subtraction), then a minor collection that copies survivors out. Usually around 90% of
  objects die there, so cost scales with survivors and the major allocator's real work is
  skipped for most objects.
- Streaming memory delivers a cache line every 16 or so cycles, while a dependent pointer
  load costs about 300. Marking is a cache-miss machine, so a small prefetch queue in
  front of it, which lets about 10 misses overlap (about 20 on recent Apple chips), made
  marking two to three times faster on real programs.
- That gain was bigger than in older papers because memory-level parallelism has grown,
  and because OCaml's tagged integers (low bit set) let the marker tell pointers apart
  without side tables.
- Prefetching in general code such as `List.map` is hard: too early and the line is
  evicted, too late and it does not help. Performance does not compose across contexts and
  falls off cliffs between L1, L2, last-level cache and RAM.
- Minor allocation is cheap but still fills the minor heap and brings collections
  closer. Stack allocation reuses memory already in L1. That explains two opposite tunings
  seen in practice: a bigger minor heap cuts promotions, while a smaller one helps tight,
  low-allocation code stay in cache. Local allocation gets both benefits.
- Go keeps values on the stack only when the compiler proves they do not escape, which
  programmers cannot see in types. Rust uses lifetime variables, which in higher-order code
  need higher-rank bounds and explicit annotations because inference stops working.
- OCaml's local allocation (now OxCaml modes) instead lets a function state that it does
  not capture its argument. This needs no type variables, so inference keeps working; it is
  less expressive than Rust, but the GC still covers the hard cases.
- Local values live on a separate data stack, as in Forth, apart from the call stack.
  An annotated function can leave values on its caller's region, which lets smart
  constructors work without copying. Letting the compiler put everything on the stack was
  rejected because stack regions would never be freed.
- OCaml's uniform representation (one word for every field, an `Int32` stored as a pointer
  to three words) keeps one compiled `List.map` working for all types. The cost is
  scattered, oversized data and extra allocation, for example a tuple just to return two
  values.
- Alternatives are whole-program monomorphization (fast code, large binaries, slow
  builds, no first-class polymorphism) and .NET-style JIT specialization (compiler pauses
  at run time).
- Unboxed types add layouts as kinds: code is polymorphic within one layout, `value` is
  today's polymorphism, and unboxed tuples travel in several registers (following the
  "Kinds are Calling Conventions" paper). They can be boxed onto the heap explicitly.
- For now the GC requires a block to be all tagged values or all raw data, so a pointer
  next to an unboxed float or char cannot be stored on the heap.
- Unboxed variants are hard because each case has a different size. Returning a
  locally allocated variant is a simpler route. A non-null kind would let `t option` be
  represented as a nullable `t` with no allocation, while still ruling out nested options.

## Relevance to us

- [order-book](../../../repos/order-book.md) already uses `local_` and `exclave_` for
  per-order temporaries in its matching loop, which is the local allocation feature
  described here; [fixed-decimal](../../../repos/fixed-decimal.md) keeps values as
  immediate `int`s, the unboxed-friendly representation the episode recommends.
- **Performance:** a hot path can quietly start allocating again, and nothing would show
  it. **Action:** add a ppx_expect test that runs 10,000 submit/cancel cycles and prints
  `Gc.minor_words` per operation, so an allocation regression shows up as a diff, in
  [order-book](../../../repos/order-book.md).
- **Build and deploy:** the GC trades memory for speed through one knob, and a
  long-running service should show where it sits on that curve. **Action:** add
  `Gc.quick_stat` gauges (heap words, minor and major collection counts) to `/metrics` in
  [market-recorder](../../../repos/market-recorder.md).
- **OCaml practice:** with a tracing GC, APIs where the caller passes in a buffer avoid
  churning large short-lived buffers. **Action:** check whether the `Framed` reader in
  [market-data](../../../repos/market-data.md) allocates a fresh buffer per frame, and if
  it does, add a variant that decodes into a caller-supplied reusable buffer.

Tags: `gc`, `allocation`, `oxcaml`, `performance`
