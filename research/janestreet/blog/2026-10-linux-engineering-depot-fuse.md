# A FUSE server for our in-house storage backend

- Source: <https://blog.janestreet.com/linux-engineering-depot-fuse-index/>
- Published: 2026-10-01
- Kind: blog post

## Summary

- Research workloads need high-throughput storage; vendor products (Isilon, VAST) hit
  scaling limits, so the firm built Depot, an S3-like object store written in OCaml with an
  OCaml client. Many research tools still expect POSIX files, so an intern built a
  read-only, high-performance FUSE server for Depot.
- libfuse was avoided: its blocking I/O clashes with Async and it would need FFI. The team
  implemented the FUSE wire protocol in OCaml as a reusable library, reading kernel source
  for each message type because documentation is thin (and FUSE differs from FUSEBLK,
  CUSE and virtio-fs).
- Codec tests use captured traffic: an existing libfuse server was modified to record real
  request and response pairs while operations were run against it, and those became test
  data. The post notes some internal systems can turn production traffic into such a test
  after the fact.
- `/dev/fuse` is a character device that needs exactly one message per `read` or `write`
  syscall. Standard libraries buffer and retry partial I/O, so every call path was checked
  down to the C stubs; for example `Bigstring_unix.write` with a nonzero `min_len` may loop.
- Semantic mapping between an immutable object store and POSIX is a policy choice: names
  up to 7,000 characters (FUSE allows 1,024, many tools 256) are shortened for listing and
  mapped back on access.
- Depot "bundles" can be reached by several paths, which POSIX forbids for directories;
  each path is exposed as a separate object by keying inodes on the access path.
- The first version served about 30 MiB/s. Concurrent reads of one file, which the client
  documentation discouraged but the code handled, doubled throughput and let kernel
  readahead work.
- The largest gain came from removing copies: `string`-based reads copied every byte twice
  (a 4 GiB read allocated about 8 GiB), 92% of all allocation. Passing I/O buffers through,
  with care over buffer lifetimes, reached 1.3 GiB/s without saturating CPU or NIC; the
  readahead window is the next suspected limit.

## Relevance to us

- **Testing and simulation:** captured real traffic makes the best codec test data, and
  our recorder already stores every frame verbatim. **Action:** check a trimmed raw minute
  file from [market-recorder](../../../repos/market-recorder.md) into
  [hl-protocol](../../../repos/hl-protocol.md) test data and add a ppx_expect test that
  decodes every frame and prints a count per channel plus any decode errors.
- **Testing and simulation:** the same golden-data test is worth having for every venue
  codec. **Action:** repeat that test with one recorded minute in
  [binance-protocol](../../../repos/binance-protocol.md) and
  [bybit-protocol](../../../repos/bybit-protocol.md).
- **Performance:** string round trips between I/O buffers can dominate allocation.
  **Action:** measure allocation per frame in the [market-recorder](../../../repos/market-recorder.md)
  `on_raw` to `Raw_writer` path with `Gc.allocated_bytes` in a small benchmark and record
  the number in its repo page.
- **OCaml practice:** library I/O helpers may silently split or retry syscalls.
  **Action:** add the `Bigstring_unix.write ~min_len` behavior to `GOTCHAS.md` in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).

Tags: `testing`, `expect-tests`, `allocation`, `async`, `performance`
