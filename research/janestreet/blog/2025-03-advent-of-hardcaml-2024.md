# Advent of Hardcaml

- Source: <https://blog.janestreet.com/advent-of-hardcaml-2024/>
- Published: 2025-03-22
- Kind: blog post

## Summary

- An FPGA engineer solved several Advent of Code 2024 puzzles entirely in hardware on a small
  Lattice ECP5 part (84K LUTs, 4 Mbit RAM) with the open-source Yosys and NextPNR toolchain.
- Hardcaml, Jane Street's HDL embedded in OCaml, covers design, simulation and RTL
  generation, so the whole flow stays in OCaml; types give meaning to otherwise untyped
  wires, and functors and higher-order functions make pipeline unrolling reusable.
- Each puzzle implements a shared board-design module type, and input parsing is shared
  between simulation tests and the physical board.
- Day 4 builds sliding windows of arbitrary size over a row shift register with one
  higher-order generator; Day 7 is a deep pipeline that evaluates one operator combination
  per clock cycle, testing hundreds of millions in seconds.
- The post also covers conference outreach (ISFPGA, FCCM, Latch-Up, FPL), hiring, and a
  challenge to compare HDLs on these puzzles, later run as an Advent of FPGA contest.

## Relevance to us

- Weak: we have no FPGA work and no plans for it; the only transferable idea is sharing one
  input parser between simulated and real targets, which our simulators and clients
  already do through the `*-protocol` repositories.
- **Action:** none.

Tags: `fpga`, `hardware`, `education`
