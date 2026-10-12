# How to fail -- introducing Or_error.t

- Source: <https://blog.janestreet.com/how-to-fail-introducing-or-error-dot-t/>
- Published: 2014-04-23
- Kind: blog post

## Summary

- `option` makes failure explicit but carries no reason, so a config loader can only say
  "duplicate keys" without naming them.
- Alternatives compared: per-function variants of failure cases (precise but not
  composable, leading to deeply nested matches), `Result` with polymorphic variant errors,
  with `exn` (non-local definitions, costly and leaky conversion, invites matching on
  exceptions), or with `string` (pays for formatting even when nobody reads the error).
- Core standardizes on `'a Or_error.t = ('a, Error.t) Result.t`, where `Error.t` is
  essentially a lazy string with attached sexp-able context.
- Context accumulates with `Error.tag` and `Or_error.tag`, avoiding the nested escaping
  that comes from stringifying errors at every layer.
- `Or_error.combine_errors_unit` runs independent checks and reports all failures together;
  destructuring a record in full makes the compiler force every field to be validated.
- Constructing an error still allocates, so hot loops may preallocate static errors.
- Explicit variants remain right when callers must handle each case; the main win is
  consistency across libraries.

## Relevance to us

- **OCaml practice:** Errors should carry the offending value as sexp context, not a bare message.
  **Action:** change the checks in `Params.validate` in [mm-core](../../../repos/mm-core.md) to
  build errors with `Error.create_s` carrying the field value (for example `levels 0`), and update
  the expect test output.
- **OCaml practice:** Destructuring a record in full makes the compiler force a decision for every
  field, including new ones. **Action:** rewrite `Params.validate` in
  [mm-core](../../../repos/mm-core.md) to bind `let { tick; lot; ... } = t` with no `_` wildcard, so
  adding a parameter without a check fails to compile.
- **OCaml practice:** Each layer should tag errors with its context rather than replace them.
  **Action:** in [market-recorder](../../../repos/market-recorder.md) `check-config`, wrap parse and
  validation errors with `Or_error.tag_s` naming the config file and the venue entry index.

Tags: `ocaml-practice`, `testing`, `expect-tests`
