# Caveat Configurator: how to replace configs with code, and why you might not want to

- Source: <https://blog.janestreet.com/caveat-configurator-how-to-replace-configs-with-code-and-why-you-might-not-want-to/>
- Published: 2017-04-25
- Kind: blog post

## Summary

- Announcement of a tech talk (May 17, 2017) on representing configuration as programs.
- The motivating pattern: a small config format grows features until it is a badly built
  programming language with poor tooling.
- The obvious fix is to write configs in a real (ideally functional) language with proper
  abstractions and tools.
- The talk promises the less obvious lessons learned from actually trying this and getting
  it wrong several times; the post itself does not give them.

## Relevance to us

- Mild: [market-recorder](../../../repos/market-recorder.md) reads a `-config` file and the
  [infra](../../../repos/infra.md) Helm chart templates values, so the "config grows into a
  language" risk exists, but our configs are still small sexp/YAML records.
- **Action:** none.

Tags: `ops`, `deployment`
