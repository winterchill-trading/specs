# Can you reverse engineer an ASIC?

- Source: <https://blog.janestreet.com/can-you-reverse-engineer-an-asic/>
- Published: 2026-08-05
- Kind: blog post

## Summary

- Second puzzle after the neural network one, going further down the stack: a small chip
  is published only as its final mask layout (metal, routing and active transistor layers)
  with sample inputs and outputs.
- Primer: hardware is written in an HDL such as Verilog, synthesized into a gate netlist,
  then placed and routed across stacked metal layers; the result is a GDS file of polygons,
  which is what a foundry fabricates. Everything the chip does is in it, but nothing is
  labelled.
- The task: recover a netlist from the layout, work out what the circuit is for, then
  drive it to produce the output it expects and read the hidden answer string.
- Hints: the physical arrangement mirrors the design; one section only generates the
  output and can be ignored at first; solvers need their own simulator; success is a signal
  going high; reset must be toggled before each attempt; easter eggs are hidden in the
  circuit and repository.
- A warm-up (a binary adder with its Verilog, netlist and GDS) helps solvers test their
  tools; the design uses an open-source PDK and opens in KLayout or Magic.
- Rules ask solvers not to feed puzzle files to AI tools or write their write-ups with AI,
  while allowing AI for helper scripts and the warm-up; submissions closed 2026-09-04.
- It announces a later competition to design a chip that would actually be fabricated.

## Relevance to us

- Puzzle and recruiting post; it does not touch our repos.
- **Action:** none.

Tags: `hardware`, `education`, `hiring`
