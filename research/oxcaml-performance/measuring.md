# Measuring before optimising

Kind: how-to.

## What it is

Two numbers decide whether an OxCaml technique pays: time per operation and heap words
allocated per operation. `core_bench` gives both as a regression over growing batch sizes;
a `Gc.minor_words` delta around a loop gives exact words per call and is cheap enough to
pin in an expect test. Every other note in this directory reports both.

## When it pays

Always first. The techniques here remove allocation; allocation that was not measured
cannot be shown to be gone, and the optimizer already removes much of it (see
[flambda2 and -O3](flambda2-and-o3.md)).

## Syntax on 5.2.0+ox (verified)

Words per call, the number to pin in tests:

```ocaml
let per_call f =
  let n = 10_000 in
  let before = Gc.minor_words () in
  for _ = 1 to n do f () done;
  (Gc.minor_words () - before) / n
```

`core_bench` executable (dune: `(libraries core core_bench core_unix.command_unix)`):

```ocaml
let () =
  Command_unix.run
    (Bench.make_command [ Bench.Test.create ~name:"best: option" (fun () -> use_opt book) ])
```

Run with `-quota 1 -ascii -clear-columns time alloc`. The bench executable has no name
filter flag on this switch; split benches into several executables if one run is too long.

Build profiles to compare:

| Build | Command |
| --- | --- |
| dev (default) | `dune build` |
| release | `dune build --profile release` |
| release, flambda2 `-O3` | `OCAMLPARAM='_,O3=1' dune build --profile release` |

Give each build its own `DUNE_BUILD_DIR` so the binaries can be run side by side.

## Measured

On the `5.2.0+ox` switch (arm64 macOS), `core_bench` reports 3 minor words for a closure
that allocates nothing: the harness itself. The `Gc.minor_words` loop reports 0 for the
same closure. Subtract 3 from every `mWd/Run` figure, or use the loop.

## Pitfalls

- `core_bench` and an inline test can disagree on words for the same function, because
  inlining into the test differs; pin the inline-test figure (also in GOTCHAS.md).
- Mark the function under test `[@inline never]` when the question is "does the call
  allocate", or the benchmark measures the caller after inlining.
- Results in this directory are from one laptop; differences under 0.5 ns are noise.
- `Gc.quick_stat`'s `top_heap_words` reads below `heap_words` on the ox runtime; do not
  report it as a peak.

## Sources

- Core_bench: <https://blog.janestreet.com/core_bench-micro-benchmarking-for-ocaml/>; our
  note: [2014-05 core_bench](../janestreet/blog/2014-05-core-bench-micro-benchmarking-for-ocaml.md).
- [Performance theme](../themes/performance.md), "Measure with regression and repetition".
