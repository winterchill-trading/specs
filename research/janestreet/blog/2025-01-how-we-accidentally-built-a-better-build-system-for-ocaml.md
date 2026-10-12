# How we accidentally built a better build system for OCaml

- Source: <https://blog.janestreet.com/how-we-accidentally-built-a-better-build-system-for-ocaml-index/>
- Published: 2025-01-24
- Kind: blog post

## Summary

- Around 2012 Jane Street replaced OMake with its own build system, Jenga, open-sourced it,
  saw little outside adoption (no Windows support, and adopting it meant adopting the whole
  Jane Street way of building) and withdrew the release.
- In 2016 it wrote Jbuilder, a shim that read Jenga's build files and simply ran every
  command in topological order, so outsiders could build Jane Street packages without
  Jenga and without the firm porting its builds to OCamlbuild.
- Jbuilder became popular because it was fast (roughly 5x faster than OCamlbuild on their
  projects), portable and easy to hack on; with OCaml Labs (now Tarides) it grew into a real
  incremental build system and was renamed dune after a trademark conflict with an old IDE.
- That left the firm maintaining two build systems while its codebase grew from 4M lines of
  OCaml in 2016 to 65M plus 5M lines of Python; migration kept slipping to "next year".
- A five-person build-systems team spent over a year migrating: porting a decade of Jenga's
  scaling work to a 70M-line monorepo and the separate Vim, Emacs and VSCode integrations.
- After the switch dune matched or beat Jenga everywhere, and builds that are mostly cache
  hits (a common case) got 2-3x faster; improvements are being upstreamed to avoid an
  internal fork.
- Next steps: distributed builds, shallow builds ("builds without the bytes") and a cached
  build graph, with a team now of 12 across New York, London and Singapore.

## Relevance to us

- **Build and deploy:** the post's headline gain comes from cache hits, while each of our CI
  runs rebuilds everything after pinning siblings. **Action:** set `dune-cache: true` on the
  `ocaml/setup-ocaml@v3` step in [order-book](../../../repos/order-book.md)'s CI, compare the
  second run's build time, then roll it out to the other repositories.
- **Build and deploy:** locally, parallel agents already share one dune workspace with
  per-agent build directories; dune's shared cache would let those directories reuse each
  other's artifacts. **Action:** confirm the shared cache is enabled in the local
  `dune-workspace` setup and record the setting in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md).

Tags: `build`, `ocaml-practice`, `performance`
