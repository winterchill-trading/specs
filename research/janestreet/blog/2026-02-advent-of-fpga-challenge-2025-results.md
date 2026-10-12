# Results from the Advent of FPGA Challenge

- Source: <https://blog.janestreet.com/advent-of-fpga-challenge-2025-results/>
- Published: 2026-02-11
- Kind: blog post

## Summary

- Results of the challenge to solve Advent of Code 2025 puzzles as synthesizable
  hardware: 213 submissions from 46 countries (28% US, 23% India, 11% UK), 59% students and
  32% industry engineers including retirees, plus a few high school students.
- 151 submissions tried at least one problem in Hardcaml. Beyond Verilog, SystemVerilog
  and VHDL, entrants used Chisel, Spade, Bluespec, Veryl, Clash, SpinalHDL, PipelineC and a
  home-made HDL.
- Problem fit varied: days 1 and 3 became greedy algorithms as state machines, days 4 and
  7 suited shift-register pipelines for throughput, and days 8 and 11 needed classical graph
  algorithms translated with clever tricks.
- Judging favored detailed write-ups others can learn from and entries that went further,
  such as running on real hardware or unusual backends.
- Featured: all 12 days in SystemVerilog across ASIC, Altera and Xilinx flows with
  real-time hardware videos; all 12 days in Spade with all parsing in hardware, one answer
  found by generating code from the input and using bounded model checking (the failing
  depth is the answer), run on a small FPGA board over UART.
- A Hardcaml design for day 1 pushed through Yosys and NextPNR, then scripted into a KiCad
  PCB of 125 discrete 74-series chips, manufactured and tested within the holidays.
- A board-agnostic framework driving any Xilinx 7-series part over JTAG alone, with honest
  notes on simulation versus synthesis mismatches and a Vivado bug report.
- Bluespec designs benchmarked against the author's own out-of-order RISC-V core,
  including Gauss-Jordan elimination kept in 16-bit integers by GCD normalization.
- A Hardcaml backtracking solver for day 12, generalized beyond the puzzle, taped out
  through Tiny Tapeout; and a thoroughly documented all-days repository with algorithmic
  shortcuts (an O(1) count for day 2, a pipelined day 9, CSR graphs with union-find for day
  11).

## Relevance to us

- Hardware community post; it does not touch our software repos.
- **Action:** none.

Tags: `fpga`, `hardware`, `education`
