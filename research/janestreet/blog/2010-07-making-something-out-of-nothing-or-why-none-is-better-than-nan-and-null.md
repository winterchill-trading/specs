# Making something out of nothing (or, why None is better than NaN and NULL)

- Source: <https://blog.janestreet.com/making-something-out-of-nothing-or-why-none-is-better-than-nan-and-null/>
- Published: 2010-07-15
- Kind: blog post

## Summary

- Argues that implicit null propagation leads to confusing semantics and that programmers
  should handle missing values explicitly, with language support for the case analysis.
- IEEE NaN: arithmetic propagates it, but comparisons return false, breaking reflexivity,
  totality and the equivalence of `x > y` with `not (x <= y)`.
- Consequences: a naive `max` is asymmetric with NaN, and two range checks that look
  equivalent disagree on NaN (one passes it, one rejects it).
- SQL `NULL` propagates through arithmetic but a `NULL` condition in `CASE` is treated as
  false, so a column-wise max gives inconsistent rows; `NOT NULL` constraints are the
  saving grace.
- Java null references fail loudly but are invisible in types, so null pointer exceptions
  are everywhere.
- OCaml's `option` makes absence part of the type and the compiler forces the `None` case;
  helpers and an option monad keep that concise.
- Exceptions remain an untyped escape hatch, so they are reserved for truly exceptional
  cases.

## Relevance to us

- **Market making and trading systems:** Float checks reject NaN only when phrased in the passing
  direction, which is fragile under edits. **Action:** add a test in
  [mm-core](../../../repos/mm-core.md) that sets each float field of `Params.t` to `Float.nan` in
  turn and checks that `Params.validate` returns an error for every one.
- **OCaml practice:** NaN and infinity should never reach a fixed-point value silently. **Action:**
  add an expect test in [fixed-decimal](../../../repos/fixed-decimal.md) showing that `of_float`
  raises on `Float.nan` and `Float.infinity`, and document it in the `.mli`.
- Our DuckDB views in [market-data](../../../repos/market-data.md) will meet SQL `NULL` in outer
  joins across venues; `CASE` treats a `NULL` condition as false, which is worth remembering when
  writing queries.

Tags: `ocaml-practice`, `testing`, `risk`
