# Clock Synchronization

- Source: <https://signalsandthreads.com/clock-synchronization/>
- Published: 2020-10-14
- Kind: Signals and Threads episode 6

## Summary

- The guest, a systems engineer at Jane Street since 2012, rebuilt the firm's clock
  synchronization.
- A computer clock is driven by a cheap crystal oscillator whose frequency changes with heat
  and load; servers typically need corrections of 50 to 100 ppm, which is seconds per day if
  uncorrected.
- Synchronization means two things: clocks agreeing with each other within a bound, and
  agreeing with an external reference.
- The reference chain runs from national laboratories' atomic clocks, combined into UTC, through
  the GPS constellation to GPS appliances with roughly 100 ns accuracy.
- Uses: regulators building a total order of events across firms, correlating logs across
  machines, distributed algorithms breaking ties, and protocols like Kerberos (five-minute
  tolerance against replay).
- Typical NTP setups reach tens of milliseconds without anyone knowing why or how well.
- NTP rests on four timestamps (client send, server receive, server send, client receive),
  which give offset and round-trip delay only by assuming both directions take equal time; any
  asymmetry becomes error, and the server's two timestamps remove its processing time.
- Daemons take many samples from several servers, drop outliers (popcorn spikes), vote out
  servers that disagree (falsetickers versus truechimers) and favour sources with small error
  bars.
- Clocks are slewed, not stepped: the daemon adjusts the rate so time never jumps, especially
  never backwards; chrony by default removes one second of error per 12 seconds.
- A Windows setup that stepped the clock showed a sawtooth of drift and sudden correction.
- MiFID II required showing clocks within 100 us of UTC; the old GPS-to-NTP-servers setup was
  a few hundred microseconds off and jumped to 400 or 500 us when CPU load changed machine
  temperature.
- PTP is usually recommended, but it uses the same four timestamps; its precision comes from
  NIC hardware timestamping, sync messages every second (versus a minimum of 8 s in reference
  NTP), and switches that account for their own delay.
- NTP can match much of this: some NICs timestamp all or only NTP packets, and chrony can poll
  up to 16 times per second.
- Involving switches spreads responsibility to the network team and its firmware upgrades, and
  every black box reduces inspectability, which the host calls the sysadmin's main currency.
- PTP's default multicast delay request and response involve every peer; the team uses a hybrid
  mode with multicast sync and unicast delay messages in ptp4l.
- PTP follows one grandmaster chosen by claimed quality, with no way to reject a wrong one; GPS
  appliances have emitted absurd timestamps when shut down for maintenance.
- Final design: GPS appliances feed Linux servers over PTP (the appliances hardware-timestamp
  only PTP), and those servers serve NTP via chrony with hardware timestamps in interleaved
  mode, which sends each packet's transmit timestamp in the next packet.
- Each Linux server is paired with one appliance; clients must sync to their two local servers
  and use distant servers only to detect a bad local source.
- NIC clocks are separate from the system clock; tools such as phc2sys move time between them.
- The error bound is computed, not assumed: daemon-estimated error, half the round trip,
  accumulated uncertainty while updates are rejected, the PTP leg, and about 100 ns for GPS.
- Results: about 20 us worst case with client hardware timestamping and 35 to 40 us without;
  saturating an old NIC for minutes can still exceed 100 us, while newer NICs stay within 50 us.
- A dedicated time network was rejected as costly and complex.
- Compliance is shown by sampling each machine's error bound every 10 seconds into a database
  and checking it during the day, with different accuracy targets per system; real violations
  persist (large copies, misconfiguration) rather than spike briefly.
- Ten times better would need White Rabbit (PTP plus synchronous Ethernet for frequency
  syntonization, reaching sub-nanosecond) and a redundancy design such as a standby grandmaster.

## Relevance to us

- [market-recorder](../../../repos/market-recorder.md) stamps every frame with a local
  `recv_ts`, and planned replication in the [roadmap](../../../roadmap.md) merges two collectors
  in different regions by earliest `recv_ts`.
- **Data platform:** Comparing timestamps from two hosts is only meaningful within their clock
  error bounds, which we neither measure nor record. **Action:** add a clock error gauge to
  `/metrics`, sampled every 10 s from `chronyc -c tracking` as root dispersion plus half the
  root delay, in [market-recorder](../../../repos/market-recorder.md).
- **Data platform:** Exchange and receive timestamps together expose network delay and clock
  drift. **Action:** add a DuckDB view giving per venue and minute the median and p99 of
  `recv_ts` minus `exch_ts`, in [market-data](../../../repos/market-data.md).
- **Logs and state machines:** Code that assumes time only moves forward breaks when a clock is
  stepped, and minute files and `Merge` assume ordered `recv_ts`. **Action:** clamp `recv_ts`
  to be non-decreasing per stream and count clamped frames in `/metrics`, in
  [market-recorder](../../../repos/market-recorder.md).
- **Build and deploy:** Synchronization quality depends on configuration we do not yet specify
  for AWS. **Action:** document chrony against the Amazon Time Sync Service and a
  `chronyc tracking` check in the node bootstrap in `docs/aws.md` in
  [infra](../../../repos/infra.md).
- **Logs and state machines:** The replication merge should treat near-ties honestly.
  **Action:** state in the replication section of `design/cloud-sinks-and-replication.md` in
  `specs` that frames whose `recv_ts` differ by less than the clock error bound are unordered.
- Venue `exch_ts` values come from clocks we cannot inspect, so latency estimates from them are
  approximate.

Tags: `clocks`, `ops`, `observability`, `market-data`, `replay`
