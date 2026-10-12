# OCaml all the way down

- Source: <https://blog.janestreet.com/ocaml-all-the-way-down/>
- Published: 2018-04-04
- Kind: blog post

## Summary

- Short announcement of a tech talk in the New York office about building FPGA
  applications from OCaml.
- The author reflects that Jane Street's software grew from narrow research and execution
  systems into many domains (mail handling, market data, machine learning), nearly all in
  OCaml.
- A single language brings shared tools, libraries and idioms that the whole organization
  refines together, despite OCaml not being ideal for every task.
- FPGAs are the newest extension of that approach, reusing the existing OCaml codebase
  (this line of work became the Hardcaml library).

## Relevance to us

- Weak relevance: we have no hardware work. It does reinforce our choice to keep every
  repo, including tooling such as [parquet](../../../repos/parquet.md), in one OCaml stack.
- **Action:** none.

Tags: `fpga`, `culture`, `hardware`
