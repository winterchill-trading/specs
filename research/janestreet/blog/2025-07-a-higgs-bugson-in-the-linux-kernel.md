# A Higgs-bugson in the Linux Kernel

- Source: <https://blog.janestreet.com/a-higgs-bugson-in-the-linux-kernel/>
- Published: 2025-07-02
- Kind: blog post

## Summary

- A rarely reproducible `EACCES` broke large file copies in Gord, the system that stores and
  distributes the firm's trading activity data; copies failed only when NFSv3 ran with
  Kerberos, and identical concurrent jobs did not fail together.
- Background: NFSv3 without Kerberos trusts the client's claimed user; with Kerberos the
  kernel obtains credentials through the `rpc_gssd` daemon over the `rpc_pipefs` filesystem,
  and those logs showed no credential problem.
- A weekend of slow writes and loops copying 200 GB files did not reproduce the failure, so
  the author scaled up parallel copies, using a FUSE filesystem (Rust `fuser`, largely
  AI-written in about 20 minutes) that serves deterministic pseudo-random file contents from
  memory so small test boxes could act as sources.
- bpftrace probes on kernel functions printed stack traces whenever `EACCES` was returned, and
  packet captures were kept around each failure; the probe pointed at a GSS bad signature
  in `gss_validate`.
- A third of the test boxes failed at once, unlike production, because the tiny test NFS
  server was overloaded, producing retransmissions and latencies of hundreds of seconds.
- A throwaway Wireshark plugin recomputing reply checksums revealed the cause: a reply's HMAC
  covers the request's GSS sequence number, but a retransmission reuses the XID with a new
  sequence number, so a late reply to the original request fails verification.
- Three consecutive failures surface as `EACCES`, and each failure triggers another
  retransmission, making the bug self-reinforcing under high server latency.
- A deterministic reproducer used NFQUEUE with a userspace script that held packets to
  simulate latency.
- Two upstream patches (Linux 6.16): a cache of recent sequence numbers as RFC 2203 suggests
  (FreeBSD already had one), and no immediate retransmit on a bad checksum, treating it like
  a lost message and leaving retries to the normal timeout.

## Relevance to us

- **Testing and simulation:** bugs in matching replies to retried requests only appear under
  high latency, and our simulators ([hl-sim](../../../repos/hl-sim.md) and siblings) answer
  instantly. **Action:** add a `-response-delay-ms` flag to `hl-sim` that delays `/exchange`
  responses, and run the [hl-mm](../../../repos/hl-mm.md) live-loop test with it to check
  that the reconciler does not double-place orders while acks are outstanding.
- **Market making and trading systems:** an immediate retry on an ambiguous error made the
  kernel bug self-fulfilling; order placement has the same hazard. **Action:** add an
  expect test in [mm-core](../../../repos/mm-core.md) where a place request times out and
  the order later appears in the venue's open orders, checking that the reconciler adopts it
  by client order id instead of placing a second one.
- **Research tooling:** cheap synthetic inputs (a fake filesystem) let the author scale a
  reproduction without big machines. Context only for us.

Tags: `networking`, `simulation`, `testing`, `ops`
