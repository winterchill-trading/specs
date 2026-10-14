# parquet

A pure OCaml Apache Parquet writer and reader: Thrift compact protocol, PLAIN, dictionary,
RLE/bit-packed and (read-only) DELTA and BYTE_STREAM_SPLIT encodings, definition levels and
footer implemented in OCaml; zstd compression through the `zstd` opam bindings, snappy and
lz4_raw decompression in OCaml. No Arrow, no C++.

| | |
| --- | --- |
| Repository | `winterchill-trading/parquet` |
| opam package | `parquet` |
| Library | `parquet` (module `Parquet`) |
| Binaries | none (`bench/bench.exe` is a benchmark, `examples/trades.exe` the worked example) |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Thrift_compact` | Thrift compact protocol writer and reader |
| `Metadata` | The `parquet.thrift` structs (copy in `docs/`), `to_thrift` and `of_thrift` |
| `Encoding` | PLAIN encoders |
| `Rle_hybrid` | RLE/bit-packing hybrid encoder and decoder (levels, dictionary indices) |
| `Schema` | Typed column combinators: `int32`, `int64`, `float`, `utf8`, `bytes`, `timestamp_ns`, `decimal` (precision <= 18), `bool`; `optional`, `dictionary` |
| `Writer` | `create`/`add`/`close`, `with_file`, `add_all`, `?key_value_metadata`; row groups (default 1,048,576 rows), statistics, compression, footer |
| `Reader` | Flat files from any writer: v1/v2 pages, dictionary, RLE, DELTA, BYTE_STREAM_SPLIT; uncompressed, zstd, snappy, lz4_raw |
| `Delta`, `Decompress` | Format 2 decoders; snappy and lz4_raw decompression |

Each column chunk is one v1 data page (after a dictionary page for dictionary columns)
with `null_count` and min/max statistics. `timestamp_ns` writes `isAdjustedToUTC=false` by
default so DuckDB keeps nanoseconds. About 9.4 M rows/s with zstd on an Apple M-series
laptop; a row group is buffered in memory. The reader reads about 3 M rows/s into boxed
`Reader.Value.t` cells.

- `Writer.Direct`: per-column `add_int`, `add_float`, `add_float_u`, `add_string`,
  `add_bool`, `add_null_*` and `end_row` without a per-cell closure (0 minor words per row
  once warm, also with optional columns); `Byte_buf` and `Zstd_bytes` (a C stub over
  `ZSTD_compress` reading and writing bytes directly) avoid the `Buffer.contents` and
  ctypes copies. `test/reference_writer.ml` is a frozen copy of the old writer; a
  quickcheck test keeps the output byte-equal for required, PLAIN columns.

## Dependencies

- Depends on: no org package (core, zstd; core_unix for tests).
- Used by: `market-data`, `hl-leaderboard`, `hl-copy-core`.

## CI pin order

None. CI installs the DuckDB CLI (v1.5.6), which the tests use as the reader oracle, and
runs `examples/trades.exe`.

## Opam readiness

Audit: [research/opam-readiness/parquet.md](../research/opam-readiness/parquet.md).

## Known gaps

Each needs a design decision or an outside dependency (details in the repository README):

- No nested or repeated columns: the typed schema API has no way yet to describe nesting.
- One page per column chunk when writing (under 2 GiB; lower `row_group_rows`): splitting
  pages costs the hot path and waits for a real need.
- The writer produces no DELTA, BYTE_STREAM_SPLIT or v2 pages, page indexes or bloom
  filters (the reader decodes the encodings and v2 pages).
- No gzip, brotli or framed lz4 in either direction, and no snappy/lz4 compression when
  writing: new C bindings or a large port.
- No encryption; INT96 is rejected by the reader; the reader loads a whole column chunk
  and boxes every cell.
