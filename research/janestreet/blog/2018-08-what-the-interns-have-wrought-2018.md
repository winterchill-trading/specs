# What the interns have wrought, 2018 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2018/>
- Published: 2018-08-06
- Kind: blog post

## Summary

- Annual intern round-up (45 interns across New York, London and Hong Kong) highlighting
  three projects.
- User-space TCP/IP in pure OCaml: kernel bypass on 10G/25G cards matters because US
  equities alone peak near 5 million messages per second, and vendor user-space stacks vary
  in behavior. An intern built TCP over the cards' frame-level APIs, leaning on an existing
  protocol testing framework, and it ran on real hardware and survived induced drops.
- Netlink library: an OCaml interface to Linux kernel subsystems (mainly conntrack for the
  in-house firewall), replacing a fragile command-line tool. Message construction is wrapped
  in an indexed monad so the C library is used safely.
- Tests that need root run inside a network namespace owned by a user namespace mapping the
  test user to root, keeping privileged calls confined to the test's resources.
- Incr_dom redesign: the awkward "derived model" shared between view and apply_action was
  removed by having one incremental function return a component holding both, so work can
  be shared without clever common-subexpression caching.
- The same intern also wrote a ppx for incremental pattern matching.

## Relevance to us

- Mostly culture and hiring. The point that a protocol implementation was trustworthy
  because a test framework existed first is a general lesson our simulators already follow
  ([hl-sim](../../../repos/hl-sim.md) and siblings).
- **Action:** none.

Tags: `hiring`, `networking`, `ui`, `testing`
