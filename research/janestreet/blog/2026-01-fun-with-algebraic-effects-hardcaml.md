# Fun with Algebraic Effects - from Toy Examples to Hardcaml Simulations

- Source: <https://blog.janestreet.com/fun-with-algebraic-effects-hardcaml/>
- Published: 2026-01-06
- Kind: blog post

## Summary

- The author ported `Hardcaml_step_testbench`, a Hardcaml simulation library, from monads
  to OCaml 5 algebraic effects through the open-source `Handled_effect` library, and argues
  most monadic code is more elegant with effects. Effects were added for concurrency but
  generalize well, and can be used without mastering the theory.
- Problem 1 with monads: they spread through code. Async's `Deferred.t` forces
  `let%bind`, explicit `return ()`, and monadic variants of library functions such as
  `Deferred.for_`, and every caller must deal with the monad. An effect-based Async could
  use plain loops and return plain values.
- Problem 2: monads block OxCaml features. A `let%map` desugars to a global closure, which
  cannot capture a `@ local` value; and the closure must return a `value`-layout type, so an
  unboxed result such as `float#` is rejected. ppx_let can use local closures in some cases,
  but Async needs global ones because the scheduler stores them.
- Effects push the job of saving the continuation into the runtime, so no global closure is
  needed; they also give better stack traces and compose more easily than monad
  transformers.
- Model: performing an effect suspends the computation and hands a handler a continuation
  (everything after the perform), which it can resume with a value, raise into, or store for
  later.
- The OxCaml typed API differs from stock OCaml effects. Operations are a GADT whose
  index is the result type; `Handled_effect.Make` turns it into a module with a handler type,
  `perform` (taking the handler `@ local`), and `run`, which returns a result that is a
  value, an exception, or an operation plus its continuation.
- Business logic only calls `perform`; the interpreter loops over results, matches
  operations and resumes with `continue`.
- Hardware simulation: a synchronous circuit consumes inputs and produces outputs every
  clock cycle, and testbenches often run several threads that each drive part of the
  circuit and must meet at each cycle boundary.
- With monads, synchronization points require storing closures in a step monad, and the
  scheduler for a list of such computations is complex. With effects, a `Step` operation
  suspends a thread; each thread's state is unstarted, running (a stored one-shot
  continuation) or finished, and the runner advances every thread to its next step, then
  advances the circuit, until all finish.
- Continuations carry a `unique` mode (resumable exactly once); a `Unique.Once` wrapper
  moves that check to runtime so continuations can sit in an array. Spawning new threads
  is also possible with effects.
- The handler must be `@ local` for type safety: otherwise code could return the handler
  out of `run` and perform an effect with no handler installed; the mode checker rejects
  that at compile time (the formal argument is in a POPL 2026 paper on locality and effect
  reflection).

## Relevance to us

- **Testing and simulation:** effects make lockstep, multi-actor simulations read like
  straight-line code. **Action:** in [exchange-core](../../../repos/exchange-core.md),
  prototype an expect-test harness on `Handled_effect` where two scripted traders call a
  `step` operation between actions and the runner calls `Exchange.step` once per round,
  checking first that `Handled_effect` builds on the `5.2.0+ox` switch.
- **Market making and trading systems:** a deterministic stepped harness would address the
  known gap that `market-maker` runs are not bit-repeatable because request timing changes
  matching order. **Action:** once the harness exists, drive the
  [mm-core](../../../repos/mm-core.md) `Strategy` state machine against the engine through
  it and pin one fixed-seed run's fills in an expect test.
- **OCaml practice:** monadic `let%map` closures cannot capture `@ local` values or return
  unboxed types. **Action:** add that rule, with the compiler error it produces, to
  `GOTCHAS.md` in [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).

Tags: `oxcaml`, `async`, `simulation`, `testing`, `ocaml-practice`
