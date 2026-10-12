# Lightweight versioning for lightweight protocols

- Source: <https://blog.janestreet.com/lightweight-versioning-for-lightweight-protocols/>
- Published: 2008-12-03
- Kind: blog post

## Summary

- Small protocols between OCaml programs are easy to build: share a module of message
  types and derive serializers with sexplib or bin_prot.
- The hard part is changing them when the whole system cannot be upgraded at once.
- Approach used: keep old protocol modules alongside explicit version numbers, write
  conversions between versions, and have peers negotiate the highest version both support.
- Two conversion styles were tried: chained upgrade and downgrade steps between adjacent
  versions, or conversion of every version to and from one internal model type.
- Both work; the conversion code is tedious and error-prone, and the author invites other
  approaches.

## Relevance to us

- This is the pattern behind our `Stable.V1` types in [market-data](../../../repos/market-data.md):
  bin shapes pinned by tests and a new `V2` with a converter instead of editing `V1`; we have no
  version negotiation because event logs are files, not live peers.
- **Action:** none.

Tags: `stable-types`, `ocaml-practice`, `architecture`
