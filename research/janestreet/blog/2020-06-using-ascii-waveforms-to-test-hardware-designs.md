# Using ASCII waveforms to test hardware designs

- Source: <https://blog.janestreet.com/using-ascii-waveforms-to-test-hardware-designs/>
- Published: 2020-06-01
- Kind: blog post

## Summary

- Recaps the expect test workflow: write code that prints, let the build fill in the output,
  accept it with a keypress, and let CI flag any later diff.
- Hardware at Jane Street is designed in Hardcaml, an OCaml embedded DSL with a
  cycle-accurate simulator (`Cyclesim`), so designs and testbenches are both OCaml.
- Example: an 8-bit counter with clear and increment inputs, tested first by printing one
  line of signal values per clock cycle inside a `let%expect_test`.
- `Hardcaml_waveterm` renders a simulation as a box-drawn ASCII waveform (clock, inputs,
  multi-bit outputs as labelled segments), and since it is text it can sit in an expect block.
- This makes hardware development feel like software development and plugs into the Iron
  code review flow.
- Downsides: limited screen space forces choosing which signals to show, code must be
  factored to serve both the interactive viewer and tests, and diff tools do not yet
  understand waveforms.

## Relevance to us

- **Testing and simulation:** rendering a time series as compact text inside an expect test
  makes behavior over time reviewable at a glance; quoter tests are easier to read as
  aligned columns than as nested sexps. **Action:** add a test helper in
  [mm-core](../../../repos/mm-core.md) that prints one aligned row per step (mid, bid, ask,
  position) and use it in one expect test that drives the quoter through a scripted price
  path.
- **Testing and simulation:** the same trick suits replayed market data. **Action:** add an
  expect test in [market-data](../../../repos/market-data.md) that replays a small event log
  and prints best bid, best ask and last trade per event as aligned columns.
- **Testing and simulation:** limited screen space forces choosing which signals to show.
  **Action:** none; it is a design rule for the helpers above.

Tags: `expect-tests`, `testing`, `fpga`
