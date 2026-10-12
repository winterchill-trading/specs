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
| `Live_feed` | `create ?on_raw ?time_source config ~symbols ~streams`: one reconnecting `Venue_net.Ws_client` per stream; `start` keeps a handle whose `stats` count frames, parse errors (and OKX `error` events) and reconnects; `time_source` (default the wall clock) stamps `recv_ts` and drives keepalive and backoff |
| `Md_normalizer` | `Normalizer` as a `Market_data.Normalizer.S`, for `Market_data.Rebuild_norm` over recorded raw minutes |

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

## Tests and benchmark

`test/fixtures/raw/okx/<stream>/BTC-USDT-SWAP/2026/10/12/16-53.ndjson` is the start of a
recorded mainnet minute per stream in the `market-recorder` raw layout (257 KB). Tests
normalize every frame (149 trades, 249 BBOs, 1 snapshot and 58 deltas, 82 funding
records, no errors), run `Rebuild_norm` over the minute and read the event logs back,
pin minor words per message within 2%, and drive `Live_feed` against a scripted local
websocket server (a malformed frame shows in `stats`; a dropped connection reconnects on a
synthetic clock). `bench/main.exe` (core_bench of `Normalizer.frame`, M-series laptop):
trades 2.4 us and 431 words per frame, bbo 2.5 us, funding 2.1 us, a 60-frame book replay
from a 400-level snapshot 2.7 ms.

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
