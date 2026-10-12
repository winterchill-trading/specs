# Inspecting Internal TCP State on Linux

- Source: <https://blog.janestreet.com/inspecting-internal-tcp-state-on-linux/>
- Published: 2014-07-09
- Kind: blog post

## Summary

- Congestion window, retransmission timeout and similar state never appear on the wire, so
  packet captures alone cannot explain some TCP behaviour.
- `ss -eipn` with a filter prints per-socket internals pulled through the `tcp_diag`
  module over netlink: RTO, RTT and variance, `cwnd`, `ssthresh`, receive space, window
  scale and the congestion algorithm (cubic).
- `ss` also prints the kernel address of the socket struct; on a debug kernel the `crash`
  tool can cast it to `struct tcp_sock` and print any field, such as `snd_una` or the
  reordering threshold.
- SystemTap is the next step when that is not enough.

## Relevance to us

- **Build and deploy:** When a venue feed stalls, `ss -tipn` on the host is the cheapest way to tell
  a slow peer from a slow consumer. **Action:** add a short troubleshooting section to the
  deployment notes in [infra](../../../repos/infra.md) showing `ss -tipn` against venue endpoints
  from the [market-recorder](../../../repos/market-recorder.md) container (rtt, cwnd, Recv-Q),
  alongside the `/healthz` check.

Tags: `networking`, `ops`, `observability`
