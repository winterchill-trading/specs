# What Is an Operating System?

- Source: <https://signalsandthreads.com/what-is-an-operating-system/>
- Published: 2021-11-03
- Kind: Signals and Threads episode 12

## Summary

- MirageOS began in the early 2000s, when C network services were being torn apart by
  worms. The guest rewrote DNS and SSH in OCaml as fast as the C versions and amenable to
  model checking, then asked why such code should sit on 25 million lines of C kernel.
- Mirage is a library operating system: the compiler keeps specializing the application, its
  OCaml configuration and OCaml TCP/IP, storage and driver libraries into one bootable
  unikernel that does only its job. Multi-user isolation is given up, so it fits
  specialized services rather than desktops.
- The host frames this within the decline of multi-user operating systems: virtualization
  and containers made hardware the abstraction and the OS a frozen application stack.
- The Xen hypervisor (started as a pub bet) used paravirtualization to run several
  unmodified-userland operating systems on one machine with little overhead, and became a
  foundation of cloud computing.
- Mirage grew from testing Xen with a tiny OCaml guest of a few hundred kilobytes: then an
  OCaml TCP/IP stack, then HTTP. The guest argues good systems projects start as stunts that
  test a hypothesis before productizing.
- The design rests on module signatures (for example "flow" for byte streams) with many
  implementations, such as Unix sockets for development and a pure OCaml stack for
  unikernels. Interfaces are never final; they evolve and implementations follow.
- Mirage code can run as a normal Unix program, on a hypervisor or on bare metal. A
  solar-powered website started as a Unix app on a Raspberry Pi and was then narrowed to the
  unikernel interfaces to target a microcontroller with a far smaller energy budget.
- Mixing languages works with clean layering and understanding value lifetimes on both
  sides: Tezos unikernels combine Rust and OCaml, and Docker Desktop interfaces Go and
  OCaml.
- Docker for Mac and Windows routes container networking and file sharing through a
  Mirage-based translation layer, which cut support calls by about 99%. Mirage-derived TLS
  and HTTP stacks became community defaults; a public Bitcoin-bounty unikernel was never
  breached and rebooted in about 20 ms after crashes.
- OCaml is valued as a "generational" language: 20-year-old code still compiles, and a
  well-defined semantics lets code be transformed or verified (via Coq extraction) later.
- OCaml stagnated in the mid-2000s for lack of investment and tooling. OCaml Labs at
  Cambridge, co-founded with Jane Street support, became glue for maintenance and for
  community tools (opam, Merlin, ocamlformat, dune) and trained people who later moved into
  industry.
- Multicore OCaml took years because it first needed a memory model. Local data-race
  freedom keeps the effects of a race contained in space and time (unlike undefined
  behavior in C++ or time-spreading effects in Java) at no cost on x86 and small costs on
  ARM and PowerPC.
- Backward compatibility drove the work: existing single-threaded code (the Coq community
  was the reference) must not slow down, and the overhead was brought from 10 to 20% down
  to near noise across two garbage-collector designs.
- Roadmap at the time: OCaml 5.0 with domains for parallelism, then runtime effects, then
  typed effect handlers. Fibers are cheap and schedulers can be written in OCaml for
  application-specific scheduling.
- Eio, a direct-style IO stack on effects, uses io_uring on Linux, Grand Central Dispatch on
  macOS and IOCP on Windows, avoiding monadic concurrency.

## Relevance to us

- Our `Mm_core.Venue.S` signature in [mm-core](../../../repos/mm-core.md), with simulator
  and live implementations behind it, is the same swappable-signature pattern, and the
  [infra](../../../repos/infra.md) chart already drops capabilities and uses a read-only
  root filesystem.
- **Data platform:** New exchanges should plug in through a signature rather than edits to
  a central match. **Action:** introduce a `Venue_source.S` module type in
  [market-recorder](../../../repos/market-recorder.md) (config to `Market_data.Feed.t`
  plus `on_raw`) and register the three clients as first-class modules, so the planned
  `okx-feed` and other `*-feed` repositories plug in without editing `Config`.
- **Testing and simulation:** Developing on the full Unix implementation and then narrowing
  the interface works because both satisfy one signature. **Action:** add an expect test in
  [hl-client](../../../repos/hl-client.md) that feeds a checked-in sample of recorded raw
  frames through `Live_feed`'s pure `normalize`, so parsing is tested on real venue data
  without a socket, next to the existing loopback test.
- **Performance:** Domains are available on our 5.2-based compiler and races stay local.
  **Action:** measure single-day `day-close` time per table in
  [market-data](../../../repos/market-data.md) and, if one table dominates, prototype
  writing tables on separate domains behind a `-jobs` flag.

Tags: `architecture`, `ocaml-practice`, `testing`, `networking`
