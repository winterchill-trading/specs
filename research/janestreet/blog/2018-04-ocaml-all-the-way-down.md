# OCaml all the way down

- Source: <https://blog.janestreet.com/ocaml-all-the-way-down/>
- Published: 2018-04-04
- Kind: blog post

## Summary

- Announces a tech talk in the New York office (April 18, 2018) on building FPGA
  applications with OCaml.
- The author recalls starting with narrow systems for statistical research on strategies and
  then executing them, and how the firm's software since spread into many unexpected areas.
- Nearly everything (mail handling, market data, machine learning) is written in OCaml;
  that has costs since no language suits everything.
- The payoff is a unified environment: shared tools, libraries and idioms refined for the
  whole organization.
- FPGAs, increasingly attractive reconfigurable hardware, are the newest domain, aiming to
  reuse the existing OCaml codebase (this became the Hardcaml work).

## Relevance to us

- Reinforces our single-stack choice (even [parquet](../../../repos/parquet.md) is pure
  OCaml), but we have no hardware work. **Action:** none.

Tags: `fpga`, `culture`, `hardware`
