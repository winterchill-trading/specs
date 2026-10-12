# A FUSE server for our in-house storage backend

- Source: <https://blog.janestreet.com/linux-engineering-depot-fuse-index/>
- Published: 2026-10-01
- Kind: blog post

## Summary

- Depot is an in-house OCaml object store for research data; tools that expect POSIX
  files reach it through a new read-only FUSE server written by an intern.
- Instead of libfuse (blocking C, awkward under Async, needs FFI) the team implemented
  the FUSE wire protocol in OCaml, reading kernel source for message semantics.
- Codec tests used captured traffic: a libfuse server was instrumented to record real
  request/response pairs, which became golden data for the serializers, a pattern the post
  says is common at the firm (some systems can mint a test from production after a bug).
- `/dev/fuse` needs exactly one message per `read`/`write` syscall, so library calls that
  silently retry partial writes (such as `Bigstring_unix.write` with a nonzero `min_len`)
  had to be avoided, checked down to the C stubs.
- Semantic mapping: names up to 7,000 characters are shortened for POSIX and mapped back;
  bundles reachable by several paths get inodes keyed by access path, not by object.
- Throughput went from about 30 MiB/s to 1.3 GiB/s: concurrent reads (the client's docs
  were overly cautious) doubled it and enabled kernel readahead, and passing buffers
  instead of `string` removed the double copy that made up 92% of allocations.

## Relevance to us

- Golden tests from captured traffic map directly onto our raw minute files: the
  `*-protocol` decoders ([hl-protocol](../../../repos/hl-protocol.md),
  [binance-protocol](../../../repos/binance-protocol.md),
  [bybit-protocol](../../../repos/bybit-protocol.md)) can be tested against frames that
  [market-recorder](../../../repos/market-recorder.md) already stores verbatim.
- The string-to-buffer copy finding is a reminder to check allocation in the
  [parquet](../../../repos/parquet.md) writer and event log readers.
- **Action:** in `hl-protocol`, check in a small trimmed raw minute file from the recorder
  and add a ppx_expect test that decodes every frame and prints a count per channel plus
  any decode errors.

Tags: `testing`, `expect-tests`, `allocation`, `async`, `performance`
