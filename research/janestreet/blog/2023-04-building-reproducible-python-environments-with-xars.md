# Building reproducible Python environments with XARs

- Source: <https://blog.janestreet.com/building-reproducible-python-environments-with-xars/>
- Published: 2023-04-14
- Kind: blog post

## Summary

- Notebooks live outside the monorepo but depend on libraries inside it, so Python
  environments are the release boundary; the firm wanted them declarative, reproducible and
  centrally built, and could use neither Pipenv/Poetry (OCaml in the build) nor Docker (host
  privileges).
- A shared Conda environment from 2018 on NFS took minutes to start because imports read tens
  of thousands of files, and it could not be rebuilt reliably, so people feared changing it.
- XAR files (a squashfs image with Zstd compression, mounted as a tree) look like one file to
  NFS, which fixed startup; Conda's fixed layout did not relocate well, so they built a
  virtualenv-like layout called js-python with isolation set up by the XAR entry point.
- Internal Python libraries and OCaml bindings were still deployed separately, making
  cross-component changes and rollbacks painful; they moved to static bundling, with
  Python build rules that declare dependencies on Python and OCaml libraries.
- Environments are now exactly one code revision: a continuously rolled "nightly" tag plus
  immutable "stable" tags on a schedule, both exposed as notebook kernels.
- Cost: a hotfix needs a rebuild (10-20 minutes), so code is split into immutable "core"
  inside the environment and editable "leaf" notebooks and scripts outside it.

## Relevance to us

- We have no Python layer; the transferable idea is "a deployment is one revision": our
  service images in [infra](../../../repos/infra.md) pin siblings from GitHub `main` at
  build time, so the exact set of repository commits inside a running image is not recorded.
- **Action:** make `infra/images/service/build.sh` write the commit of the built repository
  and of every pinned sibling into an image label (and a file under `/usr/share`), and print
  it from `make ps`, so any deployed container maps to one set of revisions.

Tags: `deployment`, `build`, `python-interop`, `research-tooling`
