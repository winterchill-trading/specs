# Results from the ASIC puzzle

- Source: <https://blog.janestreet.com/asic-puzzle-results/>
- Published: 2026-10-02
- Kind: blog post

## Summary

- Solution post for the August puzzle that shipped only the GDS layout of a small chip:
  the chip checks an 11x11 Star Battle ("Two Not Touch") board fed in over 121 cycles.
- Inside: 2-bit counters per row, column and region (regions from a 121-bit ROM), a delay
  line for the no-touching rule, and an LFSR checksum of the board that scrambles the
  stored answer string so forcing the success line yields garbage.
- Built with the SKY130 open cell library and the LibreLane flow; cell names were left in
  the layout so LVS passes in Magic or KLayout could extract a gate netlist.
- About 400 entries from more than 30 countries; common tools were KLayout, Yosys and Z3
  plus custom, often AI-written, simulators. Approaches: tracing back from the success
  output, impulse-response style probing of flops, SAT solving, and attacking the LFSR.
- A solver's model reproduced the sample waveform yet treated tie-high cells as zero,
  silently disabling the adjacency check; a second, independent simulator exposed it.
- The organizers note current models could solve the puzzle from one prompt in under 30
  minutes; the post lists several easter eggs, including a floating wire left in on
  purpose after LVS caught it.

## Relevance to us

- Puzzle and recruiting post; no direct bearing on our repos.
- The one transferable lesson (a model that matches the sample trace can still be wrong;
  compare two independent implementations on inputs that should fail) is already how we
  should treat the simulators versus real venues.
- **Action:** none.

Tags: `hardware`, `education`, `hiring`
