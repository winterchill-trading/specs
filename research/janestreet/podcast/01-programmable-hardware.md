# Programmable Hardware

- Source: <https://signalsandthreads.com/programmable-hardware/>
- Published: 2020-09-09
- Kind: Signals and Threads episode 1

## Summary

- The guest leads Jane Street's hardware design team, spent over a decade shipping modem and
  video codec designs, and created Hardcaml, a hardware design library embedded in OCaml.
- Custom hardware lets you build an architecture for one problem and tune it finely for
  performance, cost and power; a CPU is itself just one such design.
- The cost is effort: hardware is far slower and more detailed to write, and the market for
  third-party blocks ("IP", the hardware word for a library) is small and expensive.
- In the small, hardware is simpler than software (gates and wires, or adders and multiplexers
  handed to a synthesizer); the difficulty is managing very large designs of simple parts.
- An ASIC is a fabricated single-purpose chip; an FPGA is a grid of lookup tables with
  programmable routing that can be reloaded with a new design in the field, while a new ASIC
  takes weeks to six months to come back from a foundry.
- ASICs beat FPGAs on every performance axis (3 to 10 times less power, an order of magnitude
  less area, higher clock rates) but only pay off at volumes in the tens of millions.
- FPGA pricing depends heavily on volume commitments: a chip costing about 8000 dollars one-off
  might be about 500 dollars under a two-year supply deal.
- Hardware can be an order of magnitude faster than software (real-time H.264 encoding with
  more codec features than optimized x86 assembly could manage; deep packet inspection across
  hundreds of ports).
- Determinism is the key property: a design that fits on the chip runs every clock cycle as
  planned, so it consumes a link at line rate by construction; measured latency spread is about
  20 ns from the 10th to the 99th percentile, while software tails reach microseconds.
- CPUs hide parallel hardware behind sequential instructions using speculation and prefetching,
  which makes their timing hard to predict ahead of time.
- Small sources of nondeterminism remain in hardware: clock-domain crossings, Ethernet
  encoding (about 10 ns), and DDR memory, whose bank rules and refresh pauses make access order
  decide between roughly 80 and 5 percent of peak bandwidth.
- The guest found Verilog and VHDL poor for writing test benches, which are more than half of
  hardware work; HDCaml (built on an OCaml compiler for the Confluence language) led to an F#
  rewrite and then to Hardcaml.
- Hardcaml builds a circuit graph from OCaml; tools on that graph include a fast built-in
  simulator, a waveform viewer and RTL generation.
- Hardware tests are written as expect tests, including ASCII waveforms, and run in the same
  continuous integration as all other code, so whoever breaks a design also fixes its tests.
- The host links this to other fields without a software mindset, such as hand-configured
  networks, and to the software-defined networking movement.
- Hardcaml's abstraction level is about the same as Verilog's; its gains are generation
  (parameterized, generic code) and testing, not a higher-level design model.
- High-level synthesis from C suits streaming DSP-style designs; Bluespec's guarded atomic
  actions with compiler-built schedulers give real abstraction, and the guest expects Jane
  Street to adopt that style for much logic while keeping exact control for interfaces like
  DDR.
- Jane Street uses protocol specification languages that emit both OCaml parsers and hardware
  from one description of a packet format.
- Comparable libraries include Chisel (Scala, taught at Berkeley, many RISC-V designs) and
  Python frameworks MyHDL and PyMTL; combinational logic maps naturally onto functional code.
- Hardcaml is open source, with about eleven libraries released around this episode; adoption
  is limited by the lack of realistic public example designs.
- In trading, nearly every FPGA design processes 10 or 25 Gbps network traffic: FPGA NICs parse
  a specific venue's market data and filter it, split it across interfaces, or pass only parts
  to the host over PCIe.
- US markets peak at several million messages per second, and consuming eight feeds means
  close to 100 Gbps; CPUs fall behind exactly when markets are busiest and trading matters most.
- Hardware designs are always tested at line rate with back-to-back packets; the guest wonders
  whether software systems are stress tested as hard.

## Relevance to us

- We run no hardware and take crypto market data from public websockets, so the FPGA and
  pricing material does not apply directly.
- **Testing and simulation:** Testing at the maximum input rate shows where a system falls
  behind, and our recorder has never been driven at saturation. **Action:** add a load test
  that feeds recorded frames back-to-back through the raw writer and event log path and prints
  frames per second and maximum queue depth in
  [market-recorder](../../../repos/market-recorder.md).
- **Testing and simulation:** A per-cycle textual trace (the ASCII waveform idea) makes state
  machine changes reviewable as expect test diffs. **Action:** add an expect test that prints
  one line per tick (mid, best bid, best ask, open interest) for 20 ticks of a seeded
  `Market_sim` in [exchange-core](../../../repos/exchange-core.md).
- **Performance:** Tail latency, not the median, is what fails when markets are busy.
  **Action:** record p50, p99 and max latency from book update to executed plan in the
  `Live.Report` of [mm-core](../../../repos/mm-core.md).
- Filtering data close to the source so downstream sees less matches our per-symbol, per-stream
  subscriptions in each client's `Live_feed`; there is nothing further to push down today.
- One protocol specification emitting several implementations contrasts with our hand-written
  codecs in each `*-protocol` repository; worth remembering if codec drift becomes a problem.

Tags: `fpga`, `hardware`, `expect-tests`, `market-data`, `latency`
