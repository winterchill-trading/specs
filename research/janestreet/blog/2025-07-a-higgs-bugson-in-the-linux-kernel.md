# A Higgs-bugson in the Linux Kernel

- Source: <https://blog.janestreet.com/a-higgs-bugson-in-the-linux-kernel/>
- Published: 2025-07-02
- Kind: blog post

## Summary

- A rarely reproducible `EACCES` broke large file copies in Gord, the system that stores and
  distributes the firm's trading activity data, but only when NFSv3 ran with Kerberos.
- Low-load reproduction attempts failed; the author scaled up parallel copies, using a
  quickly written FUSE filesystem (Rust `fuser`, largely AI-written) that serves
  deterministic pseudo-random files from memory so small test boxes could copy hundreds of
  GB.
- bpftrace probes on kernel functions printed stack traces whenever an `EACCES` was
  returned, and a packet capture around each failure was kept; the probe showed a GSS bad
  signature.
- A throwaway Wireshark plugin recomputing reply checksums revealed the cause: a reply's
  HMAC covers the request's GSS sequence number, but a retransmission reuses the XID with a
  new sequence number, so a late reply to the original request fails verification.
- Three consecutive failures surface as `EACCES`, and each failure triggers another
  retransmission, making the bug self-reinforcing under high server latency.
- A deterministic reproducer used NFQUEUE with a userspace script that held packets to
  simulate latency.
- Two upstream patches (Linux 6.16): a cache of recent sequence numbers as RFC 2203 suggests
  (FreeBSD already had one), and no immediate retransmit on a bad checksum.

## Relevance to us

- Indirect: the lesson is about matching replies to retried requests and about bugs that
  only appear under high latency, which applies to order acknowledgements between
  [mm-core](../../../repos/mm-core.md) adapters and the simulators
  ([hl-sim](../../../repos/hl-sim.md) and siblings), which today answer instantly.
- **Action:** add a `-response-delay-ms` flag to `hl-sim` that delays `/exchange` responses,
  and run the `hl-mm` live-loop test with it to check the reconciler does not double-place
  orders while acks are outstanding.

Tags: `networking`, `simulation`, `testing`, `ops`
