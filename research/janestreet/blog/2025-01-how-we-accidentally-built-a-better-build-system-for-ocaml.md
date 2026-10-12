# How we accidentally built a better build system for OCaml

- Source: <https://blog.janestreet.com/how-we-accidentally-built-a-better-build-system-for-ocaml-index/>
- Published: 2025-01-24
- Kind: blog post

## Summary

- History of dune: around 2012 Jane Street replaced OMake with its own build system, Jenga,
  open-sourced it, saw little outside adoption (no Windows, too opinionated) and withdrew it.
- In 2016 it wrote Jbuilder, a shim that read Jenga's build files and simply ran every
  command in topological order so outsiders could build Jane Street packages.
- Jbuilder became popular because it was fast (roughly 5x faster than OCamlbuild) and easy
  to hack on; with OCaml Labs (now Tarides) it grew into a real build system and was renamed
  dune after a trademark conflict.
- That left the firm maintaining two build systems; its codebase grew from 4M lines of
  OCaml in 2016 to 65M plus 5M lines of Python.
- A build-systems team of five spent over a year migrating to dune: porting Jenga's scaling
  work and the Vim, Emacs and VSCode integrations.
- After the switch dune matched or beat Jenga everywhere, and builds that are mostly cache
  hits got 2-3x faster; improvements are being upstreamed to avoid an internal fork.
- Next steps: distributed builds, shallow builds ("builds without the bytes") and a cached
  build graph, with a team of 12 across three offices.

## Relevance to us

- Background for our build tool: every repository builds with dune 3.17, and locally a
  shared untracked `dune-workspace` resolves siblings; the post's headline gain comes from
  cache hits.
- CI in each repository rebuilds everything from scratch after pinning siblings, which is
  where a dune cache would pay off (see [infra](../../../repos/infra.md) for images).
- **Action:** set `dune-cache: true` on the `ocaml/setup-ocaml@v3` step in one repository's
  CI (start with `order-book`), compare the second run's build time, then roll it out.

Tags: `build`, `ocaml-practice`, `performance`
