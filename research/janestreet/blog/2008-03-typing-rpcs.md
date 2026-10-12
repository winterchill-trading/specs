# Typing RPCs

- Source: <https://blog.janestreet.com/typing-rpcs/>
- Published: 2008-03-15
- Kind: blog post

## Summary

- The usual design for a request/response protocol is one `Request.t` variant and one
  `Response.t` variant with sexp converters, which is easy but nothing ties a request to
  its allowed responses, so mismatches surface only at runtime.
- Instead, define an embedding (an inject/project pair into `Sexp.t`) and an RPC value
  holding a string tag plus a query embedding and a response embedding, typed
  `('a, 'b) RPC.t` to mirror a function `'a -> 'b`.
- The server builds handlers with `implement : ('a, 'b) RPC.t -> ('a -> 'b) -> t` and
  dispatches on the tag; the client derives each call from the same RPC value, so its
  signature matches the original functions exactly.
- Limitations noted: duplicate tags and missing server implementations are not caught
  statically, error handling is weak and versioning is not addressed.
- This design is the ancestor of Async_rpc's typed `Rpc.Rpc.t`.

## Relevance to us

- Our venue clients ([hl-client](../../../repos/hl-client.md),
  [binance-client](../../../repos/binance-client.md),
  [bybit-client](../../../repos/bybit-client.md)) talk to fixed external APIs, so we do not design
  protocols of our own today; the planned replay server on the [roadmap](../../../roadmap.md) would
  reuse each venue's native format as well.
- **Action:** none.

Tags: `ocaml-practice`, `architecture`, `networking`
