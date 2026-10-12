# Async Parallel

- Source: <https://blog.janestreet.com/async-parallel/>
- Published: 2014-01-09
- Kind: blog post

## Summary

- Async Parallel spawns OCaml processes locally or on other hosts and passes typed messages
  between them, working around the single-threaded runtime of the time.
- `run` executes a thunk returning a `Deferred.t` in a new process; `spawn` also gives the
  child a typed `Hub` and the parent a `Channel`; channels can be handed to other processes
  and reconnect transparently.
- Architecture: a master process forked early in the program forks every worker on request;
  closures and results travel by `Marshal`, so values such as regexes, readers, writers and
  monitors cannot be sent safely.
- Sending right after spawning can race with the worker connecting; waiting for a hello
  message avoids it.
- Plain `fork` is unusable once Async has started threads, because locks held by other
  threads are copied in arbitrary states; hence the early master and the check that Async
  is not used before `Parallel.init`.
- Copy-on-write sharing after fork is defeated because the GC touches every page, so large
  shared data should live in one process behind a query interface.

## Relevance to us

- Our services run one Async process each and scale by running more containers in
  [infra](../../../repos/infra.md), not by spawning workers; the marshalling pitfalls were later
  fixed by Rpc_parallel.
- **Action:** none.

Tags: `async`, `architecture`, `ocaml-practice`
