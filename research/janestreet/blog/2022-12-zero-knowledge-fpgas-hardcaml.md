# Accelerating zk-SNARKs - MSM and NTT algorithms on FPGAs with Hardcaml

- Source: <https://blog.janestreet.com/zero-knowledge-fpgas-hardcaml/>
- Published: 2022-12-07
- Kind: blog post

## Summary

- A group of Jane Street hardware engineers entered the 2022 ZPrize competition in their
  spare time, in the multi-scalar multiplication (MSM) and number theoretic transform (NTT)
  tracks, using the open-source Hardcaml libraries the firm uses for its own FPGAs.
- zk-SNARK proving is slow (minutes to hours for millions of constraints), and roughly 70%
  of prover time is MSM and 30% NTT, so both must be accelerated, down to the finite-field
  and elliptic-curve primitives (Montgomery or Barrett reduction, Karatsuba multiplication).
- The MSM entry computes a fixed-base MSM over 2^26 BLS12-377 G1 points with a heavily
  optimized Pippenger algorithm: the FPGA accumulates points into buckets and streams
  partial sums back, while the host finishes the rare corner cases and the final combination.
- Its core is a fully pipelined point adder of more than 200 stages, with a controller that
  stalls to avoid bucket data hazards instead of flushing; host and FPGA work overlap across
  rounds.
- Results on an AWS f1.2xlarge (about $1.65 per hour): four rounds of 2^26 MSMs in 20.3 s,
  about 5.1 s each, at about 52 W, beating published FPGA designs and winning first place.
- The NTT entry uses the 4-step algorithm to split a 2^24 transform over the Solinas prime
  2^64 - 2^32 + 1 into 2^12-size Cooley-Tukey transforms that fit in on-chip SRAM, with
  clusters of 8 cores matching a 512-bit HBM bus.
- On a C1100 card, latency fell from 0.23 s with 8 cores to 0.045 s with 64, with power
  rising from 17 W to 28 W; the entry placed second for its power-area-performance balance.
- Designs interoperate with the standard vendor RTL flow, and a companion website documents
  the algorithms, source code and future optimizations.

## Relevance to us

- None: we do no FPGA work and no zero-knowledge cryptography; the host-plus-accelerator
  split and pipelining lessons do not map onto any repository or roadmap item.
- **Action:** none.

Tags: `fpga`, `hardware`, `performance`
