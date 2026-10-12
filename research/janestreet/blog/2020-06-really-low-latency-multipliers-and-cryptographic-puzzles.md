# Really low latency multipliers and cryptographic puzzles

- Source: <https://blog.janestreet.com/really-low-latency-multipliers-and-cryptographic-puzzles/>
- Published: 2020-06-22
- Kind: blog post

## Summary

- Background: a 1999 time-lock puzzle asks for 2^(2^t) mod n by repeated squaring, which
  cannot be parallelized but is cheap to verify for whoever knows the factors of n. It is an
  early verifiable delay function (VDF), a primitive used in blockchains for randomness
  beacons and proofs of replication.
- A VDF alliance competition asked for the lowest latency per squaring of a 1024-bit
  modulus on cloud FPGAs (rentable on AWS for under USD 3 per hour).
- The round 2 winner used an Ozturk multiplier: redundant bit representation (64 words of
  16 bits plus a spare bit) keeps carries local, and lookup tables fold high bits back mod p
  in three cycles; it ran at 158.6 MHz, 25.2 ns per iteration, but spanned several dies and
  drew up to 48 W.
- The author's round 3 winner, a predictive Montgomery multiplier, makes the modular step a
  shift, uses 65 words of 17 bits so each partial product fits one DSP, and sums with arity-3
  fast-carry adders.
- "Predictive branching" computes only the needed half of a product to stay within one die's
  2280 DSPs, falling back to the full product in the rare case a carry may cross the boundary.
- A deliberately short pipeline (one stage in the loop, 65 MHz) cut routing delay and power:
  46 ns per iteration, 2.3x less area, 3.7x less power and 2.1x less energy per operation.
- Takeaway: low latency on hardware favors fewer pipeline stages and designs built around the
  device's resource limits, unlike throughput-oriented software habits.

## Relevance to us

- We run no FPGAs and no cryptographic hot loops; the lesson that low latency favors short
  pipelines is hardware-specific. **Action:** none.

Tags: `fpga`, `hardware`, `latency`
