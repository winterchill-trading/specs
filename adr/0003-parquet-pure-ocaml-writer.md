# ADR 0003: A pure OCaml Parquet writer

Status: accepted

## Context

Research tooling (DuckDB, pandas, Polars, Spark) reads Parquet. Writing Parquet from
OCaml usually means binding Arrow's C++ library, which is a large native dependency that
complicates the OxCaml build, the container images and cross-compilation.

## Decision

Write Parquet with a small pure OCaml library, `parquet`: the Thrift compact protocol,
PLAIN encoding, statistics and footer in OCaml, compression through the `zstd` opam
bindings. Support only what the market data tables need: flat required columns of
`int32`, `int64`, `double`, `bool`, UTF-8 and byte strings, `TIMESTAMP(NANOS)` and
`DECIMAL` up to 18 digits.

## Consequences

- No C++ dependency; the writer builds wherever the switch builds.
- Around 9 to 13 million rows per second on a laptop; a row group is buffered in memory.
- No nullable or nested columns, no dictionary or RLE encodings, zstd only, no reader.
  Files are larger than a dictionary-encoded writer would produce.
- The DuckDB CLI is the test oracle: the tests write files and read them back with
  `duckdb`, which CI installs.
