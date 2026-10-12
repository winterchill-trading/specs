# Results from the ASIC puzzle

- Source: <https://blog.janestreet.com/asic-puzzle-results/>
- Published: 2026-10-02
- Kind: blog post

## Summary

- Solution post for the August puzzle that published only the final GDS layout of a
  small chip, with no netlist or signal names.
- About 400 submissions from more than 30 countries, from high school students to
  retirees. Common tools were KLayout, Yosys and Z3, plus custom (often AI-written) tools in
  Python, Rust, C++, OCaml, Haskell and Odin.
- The chip checks an 11x11 Star Battle ("Two Not Touch") board: exactly two stars per row,
  column and region, none touching even diagonally. It takes 121 cycles of one-bit inputs.
- Parallel checks: 2-bit counters per row and column, a 121-bit ROM mapping squares to
  regions with 2-bit region counters, a delay line for adjacency, and a total-star counter
  for easter egg messages; the results are ANDed into the success signal.
- The answer string sits in ROM XORed with an LFSR checksum of the board, so forcing the
  success line yields garbage; some solvers attacked the LFSR directly.
- Built with the SKY130 open cell library and the LibreLane flow. Cell names were left in
  the layout, so LVS passes in Magic or KLayout could extract a gate netlist; some solvers
  wrote their own extractors and debugged them on the warm-up design.
- Simulation: some used SKY130 cell models with existing simulators, others wrote
  evaluators. One model matched the sample waveform while treating tie-high cells as zero,
  which silently disabled the adjacency check; comparison with an independent Icarus
  Verilog simulation exposed it.
- Approaches: tracing back from the success output using floorplan "islands" that matched
  RTL modules; impulse-response probing (flip one input, diff every flop against a
  baseline); SAT solving for the input, sometimes followed by real analysis; and
  reverse-engineering the output generator.
- Extras: netlist-and-layout viewers, animated walkthroughs, an FPGA port, a Minecraft
  build, an analog SPICE run and a zero-knowledge proof of the solution. Easter eggs
  included Morse code under the die, a logo drawn in metal, and a floating wire kept on
  purpose after LVS caught it.
- Takeaways: current models could solve it from one prompt in under 30 minutes; the best
  write-ups explained the circuit rather than stopping at the answer; and deliberately
  trying to break one's own tools caught errors that replaying the examples missed.

## Relevance to us

- Puzzle and recruiting post; it does not touch our repos.
- The transferable lesson (a model that reproduces the sample trace can still be wrong,
  and an independent second implementation exposes it) is general; our simulators versus
  the real venues already raise the same question, covered by the planned price-anchor
  ([roadmap](../../../roadmap.md)).
- **Action:** none.

Tags: `hardware`, `education`, `hiring`
