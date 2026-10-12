# Advent of Hardcaml

- Source: <https://blog.janestreet.com/advent-of-hardcaml-2024/>
- Published: 2025-03-22
- Kind: blog post

## Summary

- An FPGA engineer solved several Advent of Code 2024 puzzles entirely in hardware, in the
  community's "upping the ante" tradition, on a small Lattice ECP5 part (84K LUTs, 4 Mbit
  RAM) with the open-source Yosys and NextPNR toolchain; the small part forced algorithmic
  economies.
- Hardcaml, Jane Street's HDL embedded in OCaml, covers design, simulation and RTL
  generation, so the whole flow stays in OCaml; types give meaning to otherwise untyped
  wires, and functors and higher-order functions make pipeline unrolling concise and
  reusable, unlike the primitive generators of traditional HDLs.
- Each puzzle implements a shared board-design module type, with a common board wrapper
  (clock, UART) and a build list, and input parsing is shared between simulation tests and
  the physical board.
- Day 4 builds sliding windows of any size over a row shift register with one higher-order
  generator, using nested arrays at build time that flatten to fixed-width signals.
- Day 7 is a very deep pipeline that evaluates one operator combination per clock cycle,
  testing hundreds of millions of combinations in seconds.
- The post also covers conference outreach (ISFPGA, FCCM, Latch-Up, FPL), hiring, and a
  challenge to compare HDLs on these puzzles; an update notes the later Advent of FPGA
  contest drew over 200 submissions.

## Relevance to us

- None: we have no FPGA work and no plans for it; the shared simulated-versus-real parser
  idea is already how our `*-protocol` repositories serve both simulators and clients.
- **Action:** none.

Tags: `fpga`, `hardware`, `education`
