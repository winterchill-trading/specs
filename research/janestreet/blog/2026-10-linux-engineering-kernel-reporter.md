# A resilient kernel log reporter

- Source: <https://blog.janestreet.com/linux-engineering-kernel-reporter-index/>
- Published: 2026-10-01
- Kind: blog post

## Summary

- Intern project to collect kernel logs from Linux hosts even when the disk or the
  network has failed, which is when the logs matter most; workstations lack lights-out
  management, so this was the only way to see their crashes.
- The shipper removes hidden disk dependencies: it `mlockall`s itself so code pages are
  never paged in, reads `/dev/kmsg` directly instead of on-disk logs, and resolves the
  collectors' DNS names in a background loop with cached IPs so a dead disk (no
  `/etc/resolv.conf`) does not block shipping.
- Transport is plain UDP, one copy per collection server: no TLS certificates on disk, no
  backpressure, no connections to keep alive.
- For panics, the kernel writes compressed, newest-first log fragments to pstore
  (EFI-backed non-volatile memory) before kexec into the crash kernel; kernel arguments
  enable the EFI backend and order pstore before kexec.
- On next boot the shipper drains pstore with its own parser (an old systemd did not
  recognize a renamed backend), reassembles fragments, ships them, and alerts if pstore
  stays non-empty so firmware storage never fills.
- Logs surface through a CLI and an existing why-reboot tool; they pinned a wave of
  desktop freezes on a GPU driver update, which was rolled back.

## Relevance to us

- Weak: we do not run our own hosts yet. The idea of "ship diagnostics without the
  dependencies that just failed" applies loosely to
  [market-recorder](../../../repos/market-recorder.md), whose health endpoint and uploader
  share the host with the disk they report on.
- **Action:** none.

Tags: `ops`, `observability`, `deployment`
