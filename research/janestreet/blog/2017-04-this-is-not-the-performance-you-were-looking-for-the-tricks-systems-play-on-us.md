# This is not the performance you were looking for: the tricks systems play on us

- Source: <https://blog.janestreet.com/this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us/>
- Published: 2017-04-20
- Kind: blog post

## Summary

- Premise: deployment choices (scheduler policy, affinity, background load) can erase
  optimization work. A checklist for unexpectedly slow apps, with Linux tools.
- Check you run the intended binary: hash the executable and `/proc/<pid>/exe` and compare
  with what you meant to deploy.
- Check the dynamic libraries actually linked, with `ldd` on the binary or the process.
- Affinity: `taskset` shows and sets allowed cores; pinning keeps caches warm, one core may
  suit a single-threaded app while busy multi-threaded apps need several.
- NUMA: memory, disk and network latency depend on the core, each penalty small (hundreds
  of nanoseconds) but adding up; `numactl -H` shows the topology; place apps near what
  they use.
- Pinning one app means pinning the others away from its cores. The author's team avoids
  the `isolcpus` boot option because it concentrated load instead of spreading it.
- Peripherals: find a NIC's NUMA node via sysfs, or map the machine with `hwloc-ls`, and
  co-locate the app on that node.
- Machine setup: VMs are often much slower; the `hypervisor` CPU flag reveals one.
- Software drift: compare kernel versions and installed package lists across two hosts with
  a small helper that diffs the output of the same command run over ssh.
- Hardware drift: compare CPU model and speed and `dmidecode` output, especially BIOS
  version; and check uptime, since a box up for 300 days is suspect.

## Relevance to us

- **Build and deploy:** the first question when a deployed process misbehaves is which
  build is running, and [market-recorder](../../../repos/market-recorder.md) `/metrics`
  exposes only counters. **Action:** add a `market_recorder_build_info` gauge (value 1,
  labels for version and executable hash) to `Metrics.render`, with an expect test on the
  rendered text.
- **Build and deploy:** our AWS target runs on EC2 VMs, where host drift and noisy
  neighbors matter, and the plan lists no host checks. **Action:** add a short "host
  checks" list (instance type, kernel version, chrony sync status, uptime) to the AWS
  target section of `specs` `design/deployment.md`.
- Context: affinity and NUMA tuning only matter once the [roadmap](../../../roadmap.md)
  deployment exists and latency is measured; nothing to pin yet.

Tags: `ops`, `performance`, `deployment`, `observability`
