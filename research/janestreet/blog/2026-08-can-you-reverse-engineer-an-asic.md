# Can you reverse engineer an ASIC?

- Source: <https://blog.janestreet.com/can-you-reverse-engineer-an-asic/>
- Published: 2026-08-05
- Kind: blog post

## Summary

- Puzzle announcement: a small chip is published only as its final GDS mask (metal,
  routing and transistor layers) plus sample inputs and outputs; solvers must recover a
  netlist, work out the circuit's purpose, and drive it to emit a hidden answer string.
- Includes a short primer on the flow from HDL to synthesized netlist, placement and
  routing, and the GDS file a foundry fabricates from.
- Hints: the floorplan mirrors the design's structure, one block produces the output but
  does not affect the success signal, and solvers need their own simulator; reset must be
  toggled before each attempt.
- A warm-up (a binary adder with Verilog, netlist and GDS) is provided; open tools such as
  KLayout and Magic open the files, and the design uses an open-source PDK.
- Rules ask entrants not to feed puzzle files directly to AI tools, while allowing AI for
  helper scripts; submissions closed 2026-09-04. It teases a later chip design contest.

## Relevance to us

- Puzzle and recruiting post; no bearing on our repos.
- **Action:** none.

Tags: `hardware`, `education`, `hiring`
