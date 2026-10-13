# parquet

A pure OCaml Apache Parquet writer: Thrift compact protocol, PLAIN encoding and footer
implemented in OCaml, zstd compression through the `zstd` opam bindings. No Arrow, no
C++.

| | |
| --- | --- |
| Repository | `winterchill-trading/parquet` |
| opam package | `parquet` |
| Library | `parquet` (module `Parquet`) |
| Binaries | none (`bench/bench.exe` is a benchmark) |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Thrift_compact` | Thrift compact protocol writer |
| `Metadata` | The `parquet.thrift` structs used (copy in `docs/`) |
| `Encoding` | PLAIN encoders |
| `Schema` | Typed column combinators: `int32`, `int64`, `float`, `utf8`, `bytes`, `timestamp_ns`, `decimal` (precision <= 18), `bool` |
| `Writer` | `create`/`add`/`close`, `with_file`, `add_all`; row groups (default 1,048,576 rows), statistics, compression, footer |

Each column chunk is one v1 data page with `null_count` and min/max statistics.
`timestamp_ns` writes `isAdjustedToUTC=false` by default so DuckDB keeps nanoseconds.
About 9.4 M rows/s with zstd on an Apple M-series laptop; a row group is buffered in
memory.

- `Writer.Direct`: per-column `add_int`, `add_float`, `add_float_u`, `add_string`,
  `add_bool` and `end_row` without a per-cell closure (0 minor words per row once warm);
  `Byte_buf` and `Zstd_bytes` (a C stub over `ZSTD_compress` reading and writing bytes
  directly) avoid the `Buffer.contents` and ctypes copies. `test/reference_writer.ml` is
  a frozen copy of the old writer; a quickcheck test keeps the output byte-equal.

## Dependencies

- Depends on: no org package (core, zstd; core_unix for tests).
- Used by: `market-data`.

## CI pin order

None. CI installs the DuckDB CLI (v1.5.6), which the tests use as the reader oracle.

## Known gaps

- No `OPTIONAL` (nullable), nested or repeated columns.
- PLAIN only: no dictionary, RLE, delta or byte-stream-split encodings.
- No data page v2, page indexes, bloom filters, key-value metadata or encryption.
- zstd only; one page per column chunk (under 2 GiB); no reader.
