# The Network as a Program

- Source: <https://signalsandthreads.com/the-network-as-a-program/>
- Published: 2026-06-01
- Kind: Signals and Threads episode 27

## Summary

- The guest is a professor working on programming languages and networking who spends about one day
  a week as a visiting researcher with Jane Street's networking team. He moved from physics to CS,
  worked on adding generics to Java as an undergraduate, then did a PhD on lenses.
- Lenses grew out of the Unison file synchronizer and its generic successor, Harmony. Converting
  data between formats both ways needs two near-inverse functions, so a lens defines both from one
  description, with laws that guarantee edits round-trip. Haskell libraries later generalized the
  idea by relaxing the laws.
- Software-defined networking (SDN) arose about 15 years ago as hyperscalers wanted to change
  network behaviour at software speed and manage very large data-center networks. Instead of
  configuring each switch by hand, you describe the network's behaviour as a program.
- A language-based view adds three things: abstractions above what the hardware exposes, ways to
  compose (or deliberately isolate) several network functions, and tools that reason over the
  semantics to verify behaviour.
- Network programs are constrained: no per-packet heap allocation at line rate, and even inside one
  organization several teams control the network, so control stays partly federated.
- NetKAT describes forwarding behaviour only (not end hosts, congestion control or the control
  plane). It turned out to match Kleene algebra with tests (KAT), a decades-old framework. That
  match gave confidence in the design plus ready-made constructions from automata theory for
  compilers and verifiers.
- That foundation guided extensions such as probabilistic NetKAT for failures, unknown traffic and
  randomized load balancing. The guest thinks they would have ended up with an incoherent language
  without it.
- The guest's slogan is that the network should be just another program: no waiting on vendors or
  standards bodies to deploy a new idea. This mostly applies inside one administrative domain; the
  open internet has ossified because tens of thousands of autonomous systems can't switch over
  together.
- The idea won so completely that a vision paper arguing for it was rejected as describing how
  things already work. Some parts did not catch on: logically centralized control, and fully
  programmable routers, mostly for economic reasons.
- The host stresses a second benefit: once the network is a program you get software practice
  (version control, code review, testing) instead of engineers logging into routers to make changes
  by hand.
- Verifying snapshots of the forwarding plane is now routine at large operators: model it with SAT
  solvers, model checkers or NetKAT and check reachability and isolation. What to do when a
  control-plane change violates the spec is still open; rejecting a change made in response to a
  failure can leave the failure in place.
- Networking research is a tight community of academics, hyperscalers and switch vendors, so ideas
  reach practice quickly, unlike the decades programming languages took (garbage collection, type
  systems).
- OpenFlow modelled a switch as one big lookup table and hoped compilers would map it onto real
  pipelines; P4, a second attempt, exposes the real pipeline structure. The guest spent a sabbatical
  at Barefoot Networks, a programmable-switch startup, to learn how routers are built. A colleague
  there saw a programmable switch as another kind of processor: little memory and state, very high
  throughput.
- One stretch of the published transcript (about in-network computing) is elided at the source.
- Multicast failed on the open internet because data-plane bandwidth became cheap while
  control-plane state for many distribution trees stayed scarce. It suits trading, where a few
  channels go to everyone. Clouds offer no real multicast; where they emulate it, it is slow and
  exists for legacy software.
- A Jane Street paper notes that commodity routers keep gaining bandwidth while multicast support
  stays flat or gets worse and latency creeps up as pipelines grow. It sketches alternatives such as
  optical or circuit-switched fabrics that broadcast cheaply but push filtering to receivers.
- The host thinks multicast is underused elsewhere, especially for state machine replication and
  inside large systems, as distinct from exchanges using it to publish data fairly to many firms.
- The guest cites a proposal for ML training traffic: because it is regular, switches could replace
  packet switching with scheduled permutations, which would be simpler and faster; hybrids may
  follow. ML is driving rapid change in transports, collectives and scale-up versus scale-out
  networks.
- BGP is a path-vector protocol: each autonomous system advertises paths with attributes and each
  router picks routes by local preference. On the internet it converges well because the
  customer-provider economics of ISPs impose well-studied conditions that make it stable. It is also
  widely used inside organizations because it is expressive, well supported, familiar to engineers,
  and reacts to failures quickly.
- Butane, Jane Street's wide-area routing system, compiles a central policy kept in a repository and
  code-reviewed into BGP snippets for each router. Defaults just deliver traffic; specific traffic
  can be pinned to the lowest-latency paths; site structure and traffic classes are first-class.
- The engineers valued Butane's tooling most. A semantics for Butane and BGP, tested both
  mathematically and against vendor hardware, combined with historical measurements, previews the
  latency change between sites before a push. What-if analysis (lose n links, remove a hotspot) and
  synthesis of changes from constraints are still research.
- The team chose a deliberately simple policy abstraction that compiles predictably (like OCaml in
  spirit) rather than a fancier research language; being able to see through to the generated BGP
  mattered more.
- Formal models here are less a safety check than a way to explore: engineers make bigger changes
  with confidence, and the team has started using the model for capacity planning (which links to
  buy).
- Rollout went first to a new, unused site as a live lab, then needed firmware upgrades across the
  fleet and integration with homegrown deployment tools whose owners could add features on request.
- The guest's lab now studies routing algebras (from the MetaRouting line of work) as composable
  building blocks for policy languages, including conditions that rule out oscillation, possibly as
  an IR for a richer Butane.
- Side points: the host contrasts Java-era roofline GC tuning (use all the RAM) with OCaml's
  percentage-based tuning, and says research communities need room for ideas that fail.

## Relevance to us

- Weak relevance: we receive venue data over public websockets rather than exchange multicast, and
  we run no network of our own.
- [infra](../../../repos/infra.md) already treats deployment config as reviewed code (a rendered
  Helm example checked in CI), which is the software-practice benefit the host describes.
- The host's point that multicast suits state machine replication does not apply to our planned
  replication, which merges two independent collectors by earliest `recv_ts` (see the
  [roadmap](../../../roadmap.md)).
- **Data platform:** Butane's main value was letting engineers see the effect of a change, including
  failure what-ifs, before making it. **Action:** add a failure table to `specs`
  `design/cloud-sinks-and-replication.md` (one collector down, one region down, uploader stalled)
  giving for each the expected gap in raw files, `norm/` and Parquet and how a reader detects it.

Tags: `networking`, `multicast`, `formal-methods`, `deployment`
