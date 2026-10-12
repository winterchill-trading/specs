# Data-race-free parallelism: portable and contended

Kind: reference.

## What it is

Two mode axes make OCaml 5 domains safe: `portable` (a function may run on another domain:
it captures nothing mutable that is shared) and `contended` (a value may be accessed from
several domains, so its mutable parts cannot be read or written). The compiler rejects a
closure sent to another domain that mutates a captured `ref`. Libraries `parallel`
(fork/join with a work-stealing scheduler) and `capsule` build on this.

## When it pays

Independent CPU-bound work that is large compared with the cost of a domain: per-table
day-close in market-data, per-file compression, a replay over several days. Not the
single-threaded Async hot paths (feed handling, quoting), which gain more from removing
allocation.

## Syntax on 5.2.0+ox (verified)

```ocaml
let (double @ portable) x = x * 2

module Counter : sig
  type t
  val create : unit -> t
  val incr : t @ contended -> unit @@ portable
end = struct
  type t = int Atomic.t
  let create () = Atomic.make 0
  let incr t = Atomic.incr t
end

let spawn () =
  let d = (Stdlib.Domain.Safe.spawn [@alert "-do_not_spawn_domains"]) (fun () -> double 21) in
  Stdlib.Domain.join d
```

Capturing `let r = ref 0` in the spawned closure and calling `incr r` fails:

```text
Error: This value is "contended" because it is used inside the function ...
       which is expected to be "portable".
       However, the highlighted expression is expected to be "uncontended".
```

## Measured

Not benchmarked.

## Pitfalls

- `Domain.spawn` carries alerts `unsafe_multidomain` (use `Domain.Safe.spawn`) and
  `do_not_spawn_domains` (use the `Multicore` threading library). Neither `Multicore` nor
  the `parallel` library is installed on the switch (`capsule`, `portable` and
  `portable_lockfree_htbl` are). Fork/join from the oxcaml.org tutorial is therefore gated.
- More domains than cores degrades the GC, per the alert text.
- `Atomic.t` is a pointer and atomic operations are costly; prefer splitting data.

## Sources

- <https://oxcaml.org/documentation/parallelism/intro/>
- <https://oxcaml.org/documentation/tutorials/intro-to-parallelism-part-1/>
- <https://blog.janestreet.com/oxidizing-ocaml-parallelism/>; our note
  [2023-09 parallelism](../janestreet/blog/2023-09-oxidizing-ocaml-parallelism.md).
