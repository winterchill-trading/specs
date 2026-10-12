# Testing with expectations

- Source: <https://blog.janestreet.com/testing-with-expectations/>
- Published: 2015-12-02
- Kind: blog post

## Summary

- Better testing tools mean more tests. Functional programming discussion focuses on
  property-based testing, but concrete scenario tests are often what you want.
- Expect tests capture the output of the code under test automatically instead of making
  the author write it, and fold it back into the test source.
- Inspired by Mercurial's unified test format, implemented independently by cram: a file of
  shell commands with expected output; failures appear as diffs and are accepted by moving
  the generated `.err` file over the original.
- Jane Street used cram extensively for command-line tools since building Iron, but it is
  awkward outside the shell.
- Three benefits worth keeping: scenario, output and comments in one readable file;
  output generated for you; failures shown as readable diffs.
- The OCaml version uses annotations (`let%expect_test`, `[%expect]`) so Merlin,
  ocp-indent and tuareg keep working; tests register with the inline test framework,
  several expect blocks can appear in one test, and failures produce a `.corrected` file.
- Expect tests shine for larger scenarios; release as open source was promised.

## Relevance to us

- ppx_expect is the backbone of every repository's tests; the cram half is unused.
- **Testing and simulation:** command-line behavior of our binaries is only covered by
  shell e2e scripts that print rather than diff, and no repository has a dune cram test.
  **Action:** add a dune cram test (`test/cli.t`) to
  [market-data](../../../repos/market-data.md) that runs `day-close` on a tiny checked-in
  event log and lists the Parquet files it writes with their row counts.

Tags: `expect-tests`, `testing`
