# Caveat Configurator: how to replace configs with code, and why you might not want to

- Source: <https://blog.janestreet.com/caveat-configurator-how-to-replace-configs-with-code-and-why-you-might-not-want-to/>
- Published: 2017-04-25
- Kind: blog post

## Summary

- Announces a tech talk on May 17, 2017 about representing configuration as programs.
- The familiar failure: making a config format clearer and more concise gradually turns it
  into a poorly built programming language with bad tooling, because nobody has time to
  make it a proper one.
- The obvious alternative is to write configs in a real language with good tools and
  abstractions, ideally a functional one suited to clear declarative code.
- The talk promises the non-obvious lessons from actually doing this and getting it wrong
  several times; the post does not state them.

## Relevance to us

- Our configs are still small records ([market-recorder](../../../repos/market-recorder.md)
  `-config` sexp files, the [infra](../../../repos/infra.md) Helm values), so the
  "config becomes a language" risk is distant.
- **Build and deploy:** the cheapest guard against config drift is to load every shipped
  example in tests, and `market-recorder/examples/sims.sexp` is not exercised by the config
  tests. **Action:** add an expect test in `market-recorder` that parses
  `examples/sims.sexp` (declared as a test dependency) and prints the resulting config as
  a sexp.

Tags: `ops`, `deployment`, `testing`
