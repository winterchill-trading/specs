# How to shuffle a big dataset

- Source: <https://blog.janestreet.com/how-to-shuffle-a-big-dataset/>
- Published: 2018-09-26
- Kind: blog post

## Summary

- Jane Street trains on huge, low signal-to-noise datasets (on the order of a billion
  examples), which need shuffling before SGD but do not fit in RAM.
- The method is a two-pass external shuffle: first append each record to one of M random
  "piles" (files), then shuffle each pile in memory and concatenate.
- Correctness argument: it is equivalent to tagging each record with a uniform random key
  and sorting, with pile choice acting as a radix on the leading digits.
- Oversized piles are rare if memory allows a margin of about six standard deviations;
  restarting on overflow does not bias the result because pile sizes are independent of the
  permutation (except with a byte-size threshold on variable-length records).
- Practical tricks: run pass one in parallel per input file and fold it into preprocessing;
  shuffle piles lazily at load time; keep piles as circular buffers to maintain a shuffled
  rolling window; cheap reshuffles by permuting pile order.
- Measured on 220 million 9 kB examples (320 GB compressed HDF5): random access would take
  years per epoch, while the two-pass approach is about 1000x faster; even on uncompressed
  local SSD, sequential reads beat random reads by about 48x.

## Relevance to us

- Indirect: the sequential-versus-random access numbers back our design of streaming whole
  minute files and event logs in [market-data](../../../repos/market-data.md) replay and day
  close rather than seeking per record. We do no model training that needs shuffling.
- **Action:** none.

Tags: `ml`, `data-platform`, `performance`
