# The Thermodynamics of Trading

- Source: <https://signalsandthreads.com/the-thermodynamics-of-trading/>
- Published: 2025-07-25
- Kind: Signals and Threads episode 24

## Summary

- Jane Street's physical engineering team leases, designs, builds and operates the
  firm's data centers and offices.
- Trading data centers need proximity to venues (fiber length matters at microseconds),
  high-performance hardware with its power and cooling load, and room to grow in place,
  since a second site further away adds latency.
- PUE (total power over IT power) ranges from about 1.1 to 2. Cooling is the largest
  non-IT power draw, cut by economizers using outside air, higher allowed temperatures and
  less mechanical cooling.
- Basic loop: chillers cool water to roughly 50 to 65 F; CRAH units blow server exhaust
  over coils to move heat into the water; large sites may reject heat to river water or
  use evaporative cooling.
- Industry guidance (ASHRAE) sets allowable temperature and humidity ranges. The firm
  runs CFD studies for normal and failed-equipment cases, keeping redundancy on the
  units most likely to fail.
- Heat rejected scales with airflow times temperature rise; 20 to 30 F across a server
  is typical. Too little airflow leaves the last components in a box uncooled, while too
  high a rise overloads chillers designed for a given delta T.
- Fan power grows with the cube of air velocity, so cooling close to the load (rear-door
  heat exchangers, hot and cold aisle containment) saves energy and prevents hot exhaust
  recirculating into server inlets; mixed airflow directions between servers and
  switches complicate this.
- Fire suppression uses dry pre-action pipes and heat-melting sprinkler heads. After a
  cooling failure melted standard heads (with no water in the pipes), the firm moved to
  higher-rated heads; some containment roofs use panels that shrink and drop in a fire.
- In-house monitoring merges power, cooling, fire and lighting data into one view with
  the firm's own, more conservative thresholds than vendors use. It adds capacity
  projections that find stranded power and cooling for the next servers.
- Alert thresholds are tuned through commissioning tests, real incidents and postmortems
  that ask when the earliest warning appeared; out-of-hours pages must be real
  emergencies.
- Incident: at 3:58 pm a maintenance chiller switch-over with a mis-set valve drained
  thousands of gallons of chilled water. Rack-level sensors caught the temperature rise
  before the provider did, which let the team tell traders how long they could run and
  estimate refill time.
- Lessons: write a step-by-step method of procedure for maintenance before the work, send
  staff on site rather than relying on the provider, and build trust with third-party
  operators long before incidents so they share bad news early.
- Unlike hyperscalers, a trading firm cannot fail over transparently because the other
  site has different latency, so it invests in per-site resilience.
- GPUs drove rack power from 10 to 15 kW a decade ago to designs at 170 kW, with vendor
  talk of 600 kW; 415 V distribution helps, and retrofitted rooms may hold one GPU server
  per rack.
- Water carries heat thousands of times better than air per volume. Options in rising
  order of risk: rear-door exchangers, direct liquid cooling to cold plates on chips,
  and immersion in dielectric fluid.
- Direct liquid cooling needs fine filtration and propylene glycol against clogging and
  bacteria, compatible wetted materials, welded joints, leak detection, and procedures
  for leaks near 400 V racks, since a leak may stop a month-long training run or live
  inference.
- Limits on density are pipe and cable size, fixed-size UPS blocks and their failover
  paths, power format (AC or DC), and the cabling of rail-optimized GPU networks; rack
  standards (Open Compute Project) are still unsettled, and neat cabling speeds repairs.
- Offices: trading floors keep everyone close for shouted collaboration. Desks are on
  wheels with modular power whips under a raised floor and fiber to end-of-row switches,
  so a dedicated team moves desks weekly, sometimes hundreds at once, without
  disturbing anyone's setup.
- Underfloor air at about 60 to 65 F cools people and desk PCs through adjustable
  diffusers, replacing an earlier London design that piped CO2 coolant to desks.
- Comfort: circadian lighting from about 2,700 K to cooler midday light, high-volume air
  with MERV 16 filtration, and CO2 monitoring (worry starts around 1,500 to 2,000 ppm).
  The firm brings in more outside air, steers it to busy rooms with human oversight, and
  is evaluating spacecraft-style scrubbers.
- Hiring mixes industry veterans and new graduates; a physical-engineering internship
  recently started.

## Relevance to us

- Weak overall: we run no hardware. The nearest points are the
  [roadmap](../../../roadmap.md) AWS plan to place collectors near each venue and the
  planned replication merge by earliest `recv_ts`.
- **Build and deploy:** the firm's own fine-grained sensors noticed trouble before the
  provider did. **Action:** expose a per-stream gauge of the latest `recv_ts - exch_ts`
  on `/metrics` so venue or network degradation shows before streams go silent, in
  [market-recorder](../../../repos/market-recorder.md).
- **Build and deploy:** maintenance mistakes come from improvising under pressure.
  **Action:** write a step-by-step runbook for upgrading the recorder Helm release
  (drain, wait for the minute roll, upgrade, verify `/healthz` and uploads), in
  [infra](../../../repos/infra.md).
- **Data platform:** failing over to a farther site is a latency change, not a
  transparent swap. **Action:** add an open question to
  `design/cloud-sinks-and-replication.md` about tagging each event with its collector
  and region, so a merged stream shows which site supplied each record, in `specs`.

Tags: `hardware`, `ops`, `observability`, `latency`
