# How recurring network maintenance exposed 6 bugs

- Source: <https://blog.janestreet.com/how-recurring-network-maintenance-exposed-6-bugs/>
- Published: 2026-10-02
- Kind: blog post

## Summary

- Weekend network maintenance cuts a cabinet off for 15 to 25 minutes. For months, Kafka
  support processes (relays and consumer-group monitors, dozens per host) failed to recover
  cleanly: segfaults, hundreds of thousands of leaked sockets, or crashes from a reconnect
  surge. Six bugs were found across glibc, the in-house socket library, Async, the Kafka
  client and a job runner; two were over a decade old.
- Context: OCaml code resolves names by two paths, glibc via `Core_unix`/`Async_unix` on
  the Async thread pool, and an in-house OCaml DNS client used by service discovery. After
  an earlier outage starved the thread pool, Async caps glibc lookups at half the pool;
  the in-house client bypasses that throttle. Ephemeral ports (28,232 by default) are shared
  by every process on the host.
- Act I, segfaults: a 2015 glibc change meant a failed `res_init` re-initialization (for
  example EMFILE opening `resolv.conf`) left the nameserver count nonzero but its pointers
  null, so the next lookup on that thread crashed. The in-house DNS client calls `res_init`
  to parse `resolv.conf`, so the corruption needed both libraries on the same worker
  thread.
- It was reproduced in C by capping the FD limit, and in OCaml by pinning the Async pool
  to one thread. The fix shipped upstream in glibc 2.44; the same crash signature had been
  hitting unrelated systems, browsers included, for years.
- Act II, FD leak: the socket library created a UDP socket and leaked it when `bind`
  failed with EADDRINUSE under port exhaustion. An LD_PRELOAD shim that fails such binds
  reproduced it without any network; bpftrace showed the DNS client as the caller.
- Per-second sar history showed bound UDP sockets pinned at 24,835 during the partition,
  total sockets above 580,000, and a permanent plateau about 345,000 sockets above
  baseline afterwards. With about 79 processes sharing the port range (about 358 ports
  each) and three parallel nameserver queries per lookup, exhaustion was easy; the leak
  then supplied the FD pressure for Act I.
- Act III, thundering herd: after the fixes, two relays died at their 32,768 FD limit as
  TCP connections jumped from 429 to 474,033 within half a minute of recovery.
- Cause: the Kafka client's pool opens a connection per blocking request; its retry loop
  timed out without cancelling the attempt; and since a 2012 refactor Async
  `Tcp.connect_sock` started its timeout only after DNS resolution, so attempts sat in the
  DNS throttle queue for the whole outage and all connected at once on recovery.
- The theory predicted a number: about 18 retry cycles of 80 s in a 1,435 s partition,
  times about 1,500 consumer groups, gives about 27,000 attempts; logs showed 27,898 and
  27,786, FD counts matched, and the drain matched Kafka's 600 s idle timeout.
- The UDP surge most likely came from concurrent, uncached lookups of the metadata
  service through the unthrottled DNS path; an old code comment had already flagged the
  missing de-duplication.
- Why April: a job-runner move to systemd user services silently dropped the FD override
  from 262,144 to 32,768; earlier symptoms (a relay holding 145k unbound sockets in 2025,
  unexplained memory growth) had been restarted away.
- Fixes at every layer: graceful `res_init` failure, closing the socket on bind failure,
  the Async timeout now covering DNS (and late results no longer open unwanted
  connections), retry loops that cancel expired attempts, cached in-flight bootstrap
  lookups, and restored FD limits.
- Lessons: a timeout is not a cancellation; make multi-step setup failure-atomic and test
  the failure paths directly with injected faults; make each hypothesis predict a number;
  model resources at the scope where they are shared; and read the layer below, since old
  widely deployed code can still be wrong. Redundancy made the incidents survivable, which
  bought time to investigate.

## Relevance to us

- **Testing and simulation:** failure paths can be forced without a real outage
  (rlimits, an LD_PRELOAD shim, a one-thread Async pool). **Action:** add an expect test
  in [venue-net](../../../repos/venue-net.md) that points `Ws_client.connect` at a local
  listener that accepts and never completes the handshake, and checks the connection
  times out and the FD count returns to its starting value.
- **Performance:** a timeout that does not cancel leaves work running that fires all at
  once on recovery. **Action:** audit every `with_timeout` in
  [venue-net](../../../repos/venue-net.md) and the three clients
  ([hl-client](../../../repos/hl-client.md), [binance-client](../../../repos/binance-client.md),
  [bybit-client](../../../repos/bybit-client.md)) and record in `oxcaml-claude-skills`
  `GOTCHAS.md` which ones abandon a still-running request.
- **Market making and trading systems:** a recorder with many feeds in one process
  reconnects them all in lockstep after a partition. **Action:** add random jitter to the
  `Ws_client` exponential backoff in [venue-net](../../../repos/venue-net.md) and log the
  chosen delay per reconnect.
- **Build and deploy:** resource limits set outside the program can silently change with
  the process launcher. **Action:** have [market-recorder](../../../repos/market-recorder.md)
  log its soft and hard `RLIMIT_NOFILE` at startup and export the open FD count in
  `/metrics`.
- **Logs and state machines:** per-second host socket history (sar) was what made a
  weeks-old incident reconstructable. **Action:** add node-exporter (or an equivalent
  socket and FD collector) to the [infra](../../../repos/infra.md) compose stack and Helm
  chart notes.

Tags: `async`, `networking`, `ops`, `observability`, `testing`
