# A resilient kernel log reporter

- Source: <https://blog.janestreet.com/linux-engineering-kernel-reporter-index/>
- Published: 2026-10-01
- Kind: blog post

## Summary

- Kernel logs from all Linux hosts are stored centrally, but the logs that matter most are
  produced when disks, storage or networking fail. Workstations (and servers with flaky
  lights-out management) give no other way to see them. A 2025 intern project made log
  collection survive both disk and network failure.
- Hidden disk dependencies were removed one by one. The shipper `mlockall`s itself so code
  pages never need to be paged in from disk.
- It reads `/dev/kmsg`, the kernel ring buffer as a character device that returns whole
  structured lines, instead of on-disk logs.
- Service discovery normally needs DNS, which reads `/etc/resolv.conf` and `/etc/hosts`.
  The shipper resolves collector addresses in a background loop and caches the IPs, so the
  send loop never blocks and keeps working on old IPs if the disk dies.
- Transport is plain UDP, one copy of each line to every collection server: no TLS
  certificates read from disk, no backpressure, no connections to maintain. A simple server
  persists what arrives.
- For panics, the crash kernel (kexec) needs a working disk, enough reserved memory, and
  its own correctness. As a fallback, pstore writes compressed log fragments, newest first,
  to firmware-backed non-volatile memory using direct firmware calls.
- Kernel arguments enable the EFI pstore backend and make the kernel write pstore before
  jumping into the crash kernel.
- On next boot the shipper drains pstore and ships it. The team wrote its own pstore parser
  because the installed systemd did not recognize the renamed EFI backend. It reassembles
  fragments and alerts if pstore is not empty, so firmware storage never fills up.
- Logs are exposed via a CLI and an existing why-reboot tool. A wave of desktop freezes
  traced to a GPU driver null dereference reached through a browser's crash reporter; the
  driver update was rolled back and the vendor contacted.

## Relevance to us

- **Logs and state machines:** diagnostics must not share a dependency with the failure
  they report. **Action:** make the [market-recorder](../../../repos/market-recorder.md)
  `/healthz` report a failing disk write (for example the last `Raw_writer` flush error
  and its age) instead of only silent streams.
- **Build and deploy:** cached service discovery keeps a process working when DNS or
  config files are unavailable. **Action:** document in the [infra](../../../repos/infra.md)
  deployment notes whether the recorder's upload command depends on DNS and what happens
  to `upload-pending.sexp` during a DNS outage.
- Pstore and crash kernels apply only when we run our own hosts; nothing to do yet.

Tags: `ops`, `observability`, `deployment`
