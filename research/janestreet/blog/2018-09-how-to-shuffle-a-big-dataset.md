# How to shuffle a big dataset

- Source: <https://blog.janestreet.com/how-to-shuffle-a-big-dataset/>
- Published: 2018-09-26
- Kind: blog post

## Summary

- Jane Street often has low signal-to-noise data in huge quantity (on the order of a
  billion weakly labelled examples), which raises the engineering question of shuffling a
  dataset that does not fit in RAM.
- In memory, Fisher-Yates suffices; the post presents a known but rarely written-up
  external algorithm and argues it is the difference between feasible and infeasible.
- Two-pass shuffle: pick M piles so that one pile fits in RAM and M files can be open;
  pass one appends each record to a uniformly random pile, pass two shuffles each pile in
  memory and concatenates. Linear time, dominated by reading and writing everything twice,
  and it works for variable-length records.
- Correctness: equivalent to attaching a uniform random key to each record and sorting; the
  pile choice acts like a radix sort on the key's leading digits.
- Oversized piles: allow headroom of about six standard deviations (chance of overflow
  around one in a million with 1000 piles); restarting on overflow does not bias the result
  because pile sizes reveal nothing about order, except when the threshold is in bytes for
  variable-length records, where recursion is the unbiased fix.
- The same margin works when pile storage must be preallocated.
- Practical variants: run pass one in parallel per input file and merge piles; fold pass
  one into preprocessing so it is nearly free; shuffle piles lazily at training time, even
  double-buffering two piles.
- A colleague's trick: treat each pile as a circular buffer in time order to maintain a
  half-shuffled rolling window of recent years incrementally; permuting pile load order
  gives cheap approximate reshuffles.
- Why shuffle: SGD with serially correlated gradient noise and non-commuting updates learns
  badly (50,000 cats then 50,000 dogs); a small local reservoir only helps if correlations
  are shorter than the reservoir.
- Measurements on 220 million 9 kB examples (2 TB raw, 320 GB compressed HDF5): random
  access costs about 394 ms per example (years per pass) versus 120 microseconds
  sequentially, about 1000x; on uncompressed local SSD the gap is still about 48x.

## Relevance to us

- We train no models, so the shuffle itself does not apply; the access-pattern numbers do.
- **Data platform:** random access into compressed files is orders of magnitude slower than
  streaming, which argues that per-record lookups belong in Parquet, not in raw zstd minute
  files. **Action:** add a sentence to the layers table notes in `specs`
  `design/data-platform.md` stating that raw files are for sequential replay only and point
  queries go through Parquet or DuckDB.

Tags: `ml`, `data-platform`, `performance`
