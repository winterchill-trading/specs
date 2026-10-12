# This is not the performance you were looking for: the tricks systems play on us

- Source: <https://blog.janestreet.com/this-is-not-the-performance-you-were-looking-for-the-tricks-systems-play-on-us/>
- Published: 2017-04-20
- Kind: blog post

## Summary

- A checklist for when an application is unexpectedly slow, on the premise that
  deployment choices can erase optimization work. Tools are Linux-specific.
- First confirm you run the intended binary (hash the file and `/proc/<pid>/exe`) and the
  expected dynamic libraries (`ldd`).
- Check CPU affinity with `taskset`; pinning keeps caches warm, but once one app is pinned,
  others must be pinned away from its cores. The author's team avoids `isolcpus` because it
  concentrated load unexpectedly.
- NUMA: memory, disk and NIC access cost depends on the core; inspect with `numactl -H`,
  sysfs `numa_node` for a NIC, and `hwloc-ls`, and place apps on the node of the devices
  they use.
- Machine checks: the `hypervisor` flag in `/proc/cpuinfo` reveals a VM; compare kernel
  versions, installed packages and `dmidecode` output (including BIOS version) across two
  hosts with a small ssh-plus-diff helper; very long uptimes are a smell.

## Relevance to us

- Applies to the planned AWS deployment ([roadmap](../../../roadmap.md)) on EC2, where we
  will run on VMs and will need to know which build is live.
- [market-recorder](../../../repos/market-recorder.md) exposes `/metrics` counters but no
  build identity, so "is this the binary we deployed" cannot be answered from a scrape.
- **Action:** add a `market_recorder_build_info` gauge (value 1, labels for version and
  executable hash) to the recorder's `/metrics` output, with an expect test on the render.

Tags: `ops`, `performance`, `deployment`, `observability`
