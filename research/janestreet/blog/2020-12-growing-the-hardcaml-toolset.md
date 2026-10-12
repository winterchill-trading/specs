# Growing the Hardcaml toolset

- Source: <https://blog.janestreet.com/growing-the-hardcaml-toolset-index/>
- Published: 2020-12-01
- Kind: blog post

## Summary

- Announces a batch of open-source Hardcaml libraries that restore, and exceed, the breadth
  of the old pre-Jane Street Hardcaml release, now with much better tests.
- Documentation is written as MDX (executable Markdown), so docs break the build when APIs
  change.
- New libraries: `hardcaml_circuits` (arbiters, multipliers, sorting networks),
  `hardcaml_xilinx_components` (generates typed OCaml wrappers from the Xilinx Unisims
  library), `hardcaml_xilinx` (RAM/FIFO primitives with simulation models).
- `hardcaml_verify` proves circuit properties with SAT; `hardcaml_verilator` and `hardcaml_c`
  are faster simulator backends compatible with Cyclesim.
- `hardcaml_of_verilog` imports Verilog via yosys; `hardcaml_step_testbench` is a monadic
  testbench with clock-synchronized spawned tasks; `hardcaml_fixed_point` offers fixed-point
  types with many rounding and clamping modes.
- Packages ship with v0.15 in opam, with bleeding-edge builds in the Jane Street opam repo.

## Relevance to us

- We do no FPGA work; Hardcaml itself is out of scope.
- **Testing and simulation:** MDX makes documentation code compile, so examples cannot drift
  from the API. **Action:** none for now; our READMEs carry few OCaml snippets and none are
  known to be stale, so revisit if `specs` or a repo README gains runnable examples.
- **OCaml practice:** `hardcaml_fixed_point` offers explicit rounding and clamping modes,
  as our [fixed-decimal](../../../repos/fixed-decimal.md) does with `round_down` and
  `round_nearest`. **Action:** none.

Tags: `fpga`, `hardware`, `testing`
