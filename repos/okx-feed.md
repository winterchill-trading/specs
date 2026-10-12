# okx-feed

Read-only public market data from OKX (trades, best bid and offer, L2 book, funding) as a
`Market_data.Feed.t`. No API keys, no order entry.

| | |
| --- | --- |
| Repository | `winterchill-trading/okx-feed` |
| opam package | `okx-feed` |
| Library | `okx-feed` (module `Okx_feed`) |
| Binary | `okx-feed feed -symbol SYM -streams ... [-count N] [-raw] [-url URL]` |
| Status | done |

## Key modules

| Module | Purpose |
| --- | --- |
| `Config` | Public websocket endpoint (`wss://ws.okx.com:8443/ws/v5/public` by default) |
| `Wire` | JSON shapes of the public channels |
| `Normalizer` | Pure frame to `Market_data.Event.t` conversion, per-book sequencing, funding merge |
| `Live_feed` | `create ?on_raw config ~symbols ~streams`: one reconnecting `Venue_net.Ws_client` per stream |

| Stream | OKX channels |
| --- | --- |
| `trades` | `trades` (aggregated prints; `trade_id` is the last id of the aggregate) |
| `bbo` | `bbo-tbt` |
| `l2` | `books`: 400-level snapshot, then 100 ms deltas chained by `seqId`/`prevSeqId` |
| `funding` | `funding-rate`, `mark-price` and the index's `index-tickers`, merged; perpetual swaps (`-SWAP`) only |

Symbols are OKX `instId`s used unchanged (`okx:BTC-USDT-SWAP`). The wire reference is
`docs/okx-ws-spec.md` in the repository.

## Sequencing

Deltas before the first snapshot are dropped. A delta whose `prevSeqId` is not the last
`seqId` drops the book and resubscribes the channel, which brings a new snapshot;
heartbeats (`seqId = prevSeqId`, no levels) emit nothing; a sequence reset after
maintenance is accepted. Every reconnect resubscribes and resets the books. Tests:
`test/test_normalizer.ml` ("books: snapshot, deltas, heartbeat, sequence reset", "books:
a gap resubscribes and waits for a new snapshot", "bad frames are errors, not
exceptions").

## Dependencies

- Depends on: `market-data`, `venue-net`.
- Used by: `market-recorder`.

## CI pin order

`fixed-decimal`, `exchange-core`, `parquet`, `market-data`, `venue-net`.

## Known gaps

- Sizes are venue units: contracts for swaps and futures (one `BTC-USDT-SWAP` contract is
  0.01 BTC); `market-data` has no contract multiplier.
- `Funding` has no field for the funding interval or the settled previous rate.
- The tick-by-tick book channels need a VIP tier; the public `books` channel is 100 ms.
- The gap resubscription path is tested but was not observed live.
