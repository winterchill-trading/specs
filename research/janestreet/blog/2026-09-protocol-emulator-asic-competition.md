# Can you design a chip? Announcing the protocol emulator ASIC competition

- Source: <https://blog.janestreet.com/protocol-emulator-asic-competition/>
- Published: 2026-09-10
- Kind: blog post

## Summary

- Follow-up to the ASIC reverse-engineering puzzle: a competition to design an
  open-source, general-purpose protocol emulator ASIC, with the best designs fabricated at
  the organizers' expense.
- A protocol emulator is a tiny CPU whose instruction set reads and writes pins and
  counts cycles precisely enough to "bit-bang" protocols in firmware, which is useful for
  hardware debugging and reverse engineering.
- The challenge is flexibility: not fixed UART, SPI and I2C blocks, but a chip
  reprogrammable for new protocols after fabrication, in the spirit of RP2040 PIO state
  machines or TI PRU cores.
- Required: UART, SPI, I2C. Stretch: low-speed USB and 10 Mbit Ethernet. Also suggested:
  JTAG, SWD, PS/2, CAN, and testing RTL on an FPGA first.
- The organizers generate RTL with Hardcaml and want to see verification approaches
  (formal, constrained random, AI-assisted), arguing verification becomes more important
  as AI-assisted chip design spreads.
- Process: IHP 130 nm CMOS5L through Tiny Tapeout, starting from its Verilog template.
  Area: 6x4 tiles (about 0.7 mm², roughly 1K logic cells per tile), possibly 8x4 later.
  Designs must be open source; teams are encouraged.
- Advice: SRAM is denser than flip-flops for instruction memory; synthesize early, check
  mapped area, leave room for clock tree and routing, and run full place-and-route and
  timing, because a design that fits after synthesis may still fail to route or meet timing.
- Deadline 2027-01-18; winners are taped out on a March 2027 shuttle and receive chips on
  dev boards.

## Relevance to us

- Hardware competition and recruiting post; it does not touch our software repos.
- **Action:** none.

Tags: `hardware`, `education`, `hiring`
