# Troubleshooting systemd with SystemTap

- Source: <https://blog.janestreet.com/troubleshooting-systemd-with-systemtap/>
- Published: 2020-02-03
- Kind: blog post

## Summary

- Symptom: Linux logins and cron jobs failed intermittently, with systemd, systemd-logind
  and D-Bus logging "No buffer space available" and full message queues.
- The failures correlated with "mount storms": many automounted directories mounted in quick
  succession. Upstream advice was to raise systemd's bus buffer limits, which had just been
  done, but the author wanted to know why the buffer filled and how close to the limit they
  ran.
- SystemTap probes on the running systemd binary (function entry and return, with access to
  arguments and struct fields) showed the write queue `wqueue_size` climbing to its
  hard-coded 196,608-entry cap (`BUS_WQUEUE_MAX`), after which `bus_send_internal` returned
  `ENOBUFS`; the queue drained about a minute later, and a login attempt hung meanwhile.
- A second probe printed each message's interface, member and path, revealing a flood of
  `PropertiesChanged` signals for mount units.
- Root cause part 1: systemd watches `/proc/self/mountinfo` and creates a unit for every
  mount, including ones made by the classic automounter or plain `mount`, which surprised
  even the automounter's maintainer.
- Root cause part 2: on any change to the mount table, systemd re-announces every existing
  mount over D-Bus (about four messages per mount point), so mounting N directories one at a
  time costs work quadratic in N.
- Measured: mounting 2,148 directories produced about 1.34 million messages sent by systemd
  and 2.67 million reads in systemd-logind.
- Tracing the socket file descriptors through `/proc` and `ss -xp` identified
  systemd-logind, via dbus-daemon, as the consumer; when logind is busy it falls behind and
  everything depending on the bus stalls.
- An upstream rate-limiting fix had been reverted; the author proposed a different fix on
  the systemd issue tracker.

## Relevance to us

- **Logs and state machines:** re-broadcasting full state on every small change turns a
  burst of N updates into O(N^2) messages, and the consumer silently falls behind.
  **Action:** in [market-recorder](../../../repos/market-recorder.md), check that each
  `Live_feed` subscription is sent once per symbol at connect and reconnect, and add a
  ppx_expect test that counts subscribe frames sent for a 3-symbol config.
- **Build and deploy:** a bounded queue that fills under a burst should be visible before it
  fails. **Action:** export the length of each `Recorder` pipe into `Norm_writer` as a
  `/metrics` gauge in [market-recorder](../../../repos/market-recorder.md).
- **Performance:** dynamic probes on a live binary answered questions logs could not.
  **Action:** add a note to the `oxcaml-claude-skills` gotchas log on running `perf` or
  `bpftrace` uprobes against OCaml symbols in the recorder container on the
  [roadmap](../../../roadmap.md) AWS hosts.

Tags: `ops`, `observability`, `performance`
