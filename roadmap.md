# Roadmap

Status as of the repositories' current `main` branches. Move items between sections in
the same change that finishes or starts them.

## Done

- Primitives: `fixed-decimal`, `exchange-core` (types and engine), `order-book`.
- Protocols for Hyperliquid, Binance USD-M and Bybit v5 linear.
- Simulators: `hl-sim`, `binance-sim`, `bybit-sim` over one engine, with seeded noise
  traders.
- Transport and clients: `venue-net`, `hl-client`, `binance-client`, `bybit-client`,
  each with a normalized `Live_feed`.
- Market making: `mm-core`, the three `Venue.S` adapters, `hl-mm`, the multi-venue
  `market-maker` binary and per-venue end-to-end scripts.
- Data: `parquet` writer, `market-data` (event logs, Parquet sink, day close, DuckDB
  views, replay feed, candles).
- Agent tooling: `oxcaml-claude-skills` (skills and gotchas log).

## In progress

- `market-recorder`: raw minute files, event logs, uploader, `/healthz` and `/metrics`,
  `market-recorder run -config`. See [repos/market-recorder.md](repos/market-recorder.md).
- `infra`: base and service images, compose stack, Helm chart, local and AWS notes. See
  [repos/infra.md](repos/infra.md).
- `specs`: this repository.
- CI pins: `hl-mm` and `market-maker` do not pin `parquet` and `market-data`, which
  their client dependencies now need.

## Next

- **price-anchor**: anchor simulator markets to real venues: mark price via `set_mark`,
  shadow top-N levels, trade-replay fills. See
  [design/simulators.md](design/simulators.md#planned-price-anchor).
- **Replay server**: a `tardis-machine` style server that replays recorded raw minute
  files over HTTP and websocket in each venue's native format, so clients and the market
  maker can run against history.
- **Raw-to-norm tool**: drive the venue normalizers over stored raw files to rebuild
  `norm/` (the missing half of [ADR 0002](adr/0002-raw-first-storage.md)).
- **More exchanges** as `*-feed` repositories (read-only market data: protocol types,
  `Live_feed`, no trading): OKX, Coinbase, Kraken, Deribit, Bitget.
- **Native cloud sinks** when the conditions in
  [design/cloud-sinks-and-replication.md](design/cloud-sinks-and-replication.md#when-a-native-sink-is-justified)
  hold.
- **Replication**: two collectors per exchange in two regions, cross-region
  replication, merge by earliest `recv_ts` with gap fill.
- **AWS deployment**: k3s on EC2 in ap-northeast-1 (Binance, Hyperliquid) and
  ap-southeast-1 (Bybit). See [design/deployment.md](design/deployment.md).
- **Hyperliquid signing**: EIP-712 signing in `hl-client` so the market maker can trade
  on Hyperliquid testnet and mainnet.
- **specs upkeep**: every new repository and architecture change updates these pages
  (see [CLAUDE.md](CLAUDE.md)); refresh the `oxcaml-claude-skills` ecosystem map from
  [overview.md](overview.md).
