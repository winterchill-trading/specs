# Let syntax, and why you should use it

- Source: <https://blog.janestreet.com/let-syntax-and-why-you-should-use-it/>
- Published: 2016-06-21
- Kind: blog post

## Summary

- After about six months of use, Jane Street recommends ppx_let for monadic and
  applicative libraries such as Command, Async, Result and Incremental.
- Forms: `let%bind`, `let%map`, `match%bind`, and parallel `let%map ... and ...`
  (implemented with `map` and `both`, slightly slower than explicit `mapN`); the monad is
  picked by opening a `Let_syntax` module, and Async opens the Deferred one by default.
- Parallel maps keep each variable beside its expression instead of positional `map3`
  arguments, a big readability win for applicatives like Command.Param, replacing older
  combinator tricks.
- Variables come first, as in ordinary lets, removing awkward `begin ... end >>= fun x`
  shapes.
- Bind is a "programmable let", and the syntax makes that analogy visible, which seems to
  help beginners.
- Diffs shrink: when a call becomes asynchronous, only `%bind` is added at the call site.
- Downsides: novelty; the `%` and wordiness (native `let*` and `let+` were floated); unit
  binds lack a monadic semicolon; and the Async interleaving point is less visible than an
  explicit `>>=`, though rarely a problem in practice.
- Idioms: let syntax when binding names, infix operators when point-free; `Let_syntax` now
  also carries `return` and the infix operators so opening it switches monads cleanly.
- Avoid mixing monads in one scope: open Command.Param or Deferred syntax locally as
  needed; between Deferred and Deferred.Result, convert explicitly with `ok_exn` or the
  newly added `Deferred.ok`.

## Relevance to us

- Already standard in our Async code ([venue-net](../../../repos/venue-net.md), the
  clients, [market-recorder](../../../repos/market-recorder.md)); nothing new to adopt.
  **Action:** none.

Tags: `async`, `ppx`, `ocaml-practice`
