# Tracing probes

Kind: reference.

## What it is

`[%probe "name" handler]` marks a static tracing point. A disabled probe costs almost
nothing and does not evaluate its handler; the `ocaml-probes` tool enables probes in a
running process.

## When it pays

Turning on detailed timing in production for one Async cycle or one venue without a
rebuild, where a log line per message would be too expensive.

## Syntax on 5.2.0+ox (verified to compile)

```ocaml
let f x = [%probe "tick" (print_int x)]; x
```

## Measured

Not measurable here.

## Pitfalls

- Gated: `ocamlopt -config` reports `probes: false` on this switch, and `-probes` is
  "option not available". The expression compiles and is ignored, so code using it builds
  but nothing can enable it. Probes are a Linux ELF mechanism (unverified for macOS).
- Use `perf` or `bpftrace` uprobes on Linux, or counters on `/metrics`, until a switch
  with probes is available (GOTCHAS.md, "perf, bpftrace and magic-trace").

## Sources

- <https://oxcaml.org/documentation/miscellaneous-extensions/probes/>
