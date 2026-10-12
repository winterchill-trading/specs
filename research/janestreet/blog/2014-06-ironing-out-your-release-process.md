# Iron out your release process

- Source: <https://blog.janestreet.com/ironing-out-your-release-process/>
- Published: 2014-06-24
- Kind: blog post

## Summary

- Third post on Iron, the in-house code review and release tool, over a mostly single
  Mercurial repository.
- Defends the single repository: one hash identifies the whole system, there is no
  dependency version solving, and cross-cutting changes are atomic.
- A purely linear release process struggles with large changes: one big patch is hard to
  review, while small pieces may leave the tip unrollable; feature toggles are rejected as
  too risky for production code.
- Hierarchical features: every feature has a parent; `release` moves a child's changes into
  its parent once it is based on the parent tip, fully reviewed and free of open issues;
  `rebase` pulls parent changes down (implemented as a merge).
- Patterns enabled: chains of dependent features, project-local release features with
  their own owners, and continuous release where the build bot rebases, builds, tests and
  releases automatically, retrying on new changes.

## Relevance to us

- **Build and deploy:** No single hash describes our multi-repository system, so end-to-end results
  cannot be tied to exact code. **Action:** make `scripts/e2e-all.sh` in
  [market-maker](../../../repos/market-maker.md) print the `git rev-parse HEAD` of every sibling
  repository at the start of a run.
- **Build and deploy:** Deployed images should also say exactly which commits they contain.
  **Action:** set an `org.opencontainers.image.revision` label (and one label per pinned sibling
  commit) on the service images built in [infra](../../../repos/infra.md).

Tags: `build`, `deployment`, `culture`
