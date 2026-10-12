# What the interns have wrought, 2019 edition

- Source: <https://blog.janestreet.com/what-the-interns-have-wrought-2019/>
- Published: 2019-08-30
- Kind: blog post

## Summary

- 54 interns across New York, London and Hong Kong; three projects are highlighted.
- latviz: latencies are measured by hardware that captures and timestamps network traffic,
  then summarized after the fact in ASCII tables that hide when problems happened. latviz
  plots latency over the day as a per-time-bucket histogram plus a median line, since
  latency trouble is often localized in time (rate spikes, network changes).
- latviz parts: a typed OCaml wrapper over the Highcharts JavaScript library (using GADTs to
  rule out misuse), an Incr_dom web client, a back end on a commercial column store with
  carefully designed tables and queries, and a loader that down-samples huge capture data
  with reservoir sampling. Re-bucketing or changing percentiles is near-instant, and it
  already caught one real performance regression.
- vcaml: OCaml bindings for extending Neovim, mirroring ecaml for Emacs. Bindings are
  generated from Neovim's API metadata over its MessagePack RPC (with Angstrom parsers and
  Faraday printers).
- Because separate RPCs can interleave with user actions, Neovim offers `call_atomic`; vcaml
  exposes it as an Applicative with `let%map ... and ...` syntax, so several typed calls
  combine into one atomic round trip that still returns each result.
- jane-ldap: a replacement for the ocamldap library, which relied on Unix alarms instead of
  Async, carried its own SSL, used exceptions heavily and was barely developed. The new one
  builds LDAP's ASN.1/BER encoding on the Mirage asn1 combinators (recursive search filters
  need a fixpoint combinator).
- Testing was differential: expect tests encode the same message with both libraries and
  print both as hex; differing bytes revealed bugs in both the new code and ocamldap.
- The client was being built as natively Async, multiplexing concurrent requests by LDAP
  message id rather than wrapping blocking calls in threads.

## Relevance to us

- **Data platform:** latency is most useful as a distribution over time of day, not one
  summary number, and we already store both `exch_ts` and `recv_ts` on every row.
  **Action:** add a DuckDB view to `Market_data.Parquet_views` in
  [market-data](../../../repos/market-data.md) giving per-minute p50 and p99 of
  `recv_ts - exch_ts` per venue and stream.
- **Testing and simulation:** encoding the same message with an independent reference
  implementation and diffing bytes in an expect test finds bugs on both sides.
  **Action:** when Hyperliquid EIP-712 signing lands in
  [hl-client](../../../repos/hl-client.md) (see [roadmap](../../../roadmap.md)), add an
  expect test that checks a fixed order's signature against a vector produced by the
  official Hyperliquid Python SDK.
- **Market making and trading systems:** an Applicative builder lets several typed requests
  go out as one atomic batch while keeping each typed result, which matches batch order
  endpoints on our venues. **Action:** none yet; revisit if the
  [mm-core](../../../repos/mm-core.md) reconciler moves to batch place and cancel.
- Reservoir sampling is a cheap way to down-sample raw minute files for quick plots, but no
  current tool needs it.

Tags: `observability`, `latency`, `testing`, `async`, `research-tooling`
