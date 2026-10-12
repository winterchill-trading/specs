# What the interns have wrought, 2018 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2018/>
- Published: 2018-08-06
- Kind: blog post

## Summary

- Annual intern round-up: 45 interns across New York, London and Hong Kong, each doing two
  projects; three are highlighted.
- Networking motivation: US equities alone can peak near 5 million market data messages per
  second, so the firm uses 10G and 25G cards and bypasses the kernel.
- Vendor user-space stacks work but differ subtly, hurt portability and are constrained by
  traditional socket APIs, so the firm increasingly writes to the cards' frame-level APIs.
  UDP is easy there; TCP is not.
- An intern built a user-space TCP in pure OCaml tuned for fast local LANs (connection
  setup, retransmission, congestion control), reusing existing APIs and a protocol testing
  framework, and wrote many tests; it worked on a real card on first wiring and survived
  induced packet drops.
- A second project wrote an OCaml netlink library to talk to Linux conntrack for the
  in-house firewall, replacing a crash-prone command-line tool that could not stream
  events; it required reading kernel source.
- Message construction is wrapped in an indexed monad so the underlying C library is used
  safely and messages are valid at the generic netlink level.
- Tests needing root run in a network namespace owned by a user namespace that maps the
  test user to root, confining privileged calls to test resources.
- Incr_dom redesign: the "derived model" shared between `view` and `apply_action` was
  awkward because every layer had to thread it. Rather than clever common-subexpression
  caching (hampered by weak references in JavaScript), one incremental `create` function
  now returns a component holding both the view and the action handler.
- The same intern also wrote a ppx for incremental pattern matching; interns need no prior
  OCaml or finance background.

## Relevance to us

- Mostly culture and hiring. The lesson that a protocol implementation was trusted because
  the test framework existed first already matches our simulators
  ([hl-sim](../../../repos/hl-sim.md) and siblings), and
  [venue-net](../../../repos/venue-net.md) already has loopback tests for reconnects and
  silent connections. **Action:** none.

Tags: `hiring`, `networking`, `ui`, `testing`
