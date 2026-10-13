# hl-sim

Hyperliquid exchange simulator: an HTTP and websocket server speaking Hyperliquid's
public API over `exchange-core-engine`, with the engine's market simulation.

| | |
| --- | --- |
| Repository | `winterchill-trading/hl-sim` |
| opam package | `hl-sim` |
| Library | `hl-sim` (module `Hl_sim`) |
| Binary | `hl-sim` (`-port` 3000, `-seed`, `-vol-bps`, `-coins`, `-noise-traders`, `-initial-balance`, `-response-delay-ms`, `-journal`, `-input-journal`, `-log-level`; price anchor: `-anchor VENUE:SYMBOL=COIN` (repeatable), `-anchor-raw DIR` / `-anchor-norm DIR` with `-anchor-from`, `-anchor-to`, `-anchor-speed`, `-anchor-base-url`, `-anchor-levels`, `-anchor-mark-interval-ms`, `-anchor-max-staleness-ms`, `-anchor-noise`, `-anchor-price-factor`, `-anchor-size-factor`, `-anchor-status-interval-s`; copy trading: `-leaders N`, `-leaders-seed`, `-leader-balance`, `-leader-edge-s` 60, `-strict-signatures`, `-mainnet-signatures`; `-taker-fee-bps` 4.5, `-maker-fee-bps` 1.5, `-l2-interval-ms` 500) |
| Status | done |

## Key modules

- `Adapt`: the Hyperliquid view of the engine: universe (BTC, ETH, SOL at asset indices
  0, 1, 2), price and size rules, asset index mapping, both endpoints in `hl-protocol`
  types, error wording, `User_fill` `dir` labels, `Trade`, `Order_update`,
  `Clearinghouse_state`.
- `Active_asset_ctx`: the `activeAssetCtx` channel (funding, mark, oracle, mid, impact
  prices, premium, open interest, day volumes) built from the engine; `oraclePx` equals
  `markPx`, and day volumes cover the current UTC day of the exchange clock.
- `Journal`: JSON-lines journal of accepted `/exchange` requests (`-journal FILE`);
  `Server.replay` applies one to a fresh exchange and reproduces responses, fills and
  account state when nothing else trades (`-noise-traders 0`).
- `Anchoring`: price anchors over `price-anchor`. Parses `-anchor` specs, builds the
  reference source (the `Live_feed` of `hl-client` or `binance-client`, raw minute files
  through their `Raw_normalizer`, or event logs), creates the anchor inside
  `Server.mutate`, runs its `step` from `Server.on_clock_step` and publishes the events
  of each reference item to websocket subscribers; `status` for `GET /status`.
- `Eip712`, `User_action`: EIP-712 digests of user-signed actions and recovery of the
  signer of `approveAgent` and `approveBuilderFee` (hl-protocol's `User_signed_action`).
- `Agents`: agent to account mapping (one unnamed and three named agents per account,
  `valid_until` expiry), per-signer nonce sets (100 highest, `(now - 2 days, now + 1
  day)`), builder approvals (up to 1%, 10 builders).
- `Builder`: the order `builder` field (hl-protocol's `Builder_fee`), its fee and
  `maxFeeRate` parsing; fees move from user to builder on every fill.
- `Extra_action`: `updateLeverage`, `scheduleCancel`, `batchModify`.
- `User_channels`: `webData2` (lite) and `userEvents` websocket channels for any address.
- `Rankings`: leaderboard rows (`day`, `week`, `month`, `allTime` pnl, roi, vlm) from
  sampled account values, deposits and volume.
- `Leaders`: `-leaders N` accounts with trend, mean-reversion and random strategies,
  reproducible from the seed. With an edge, trend and mean reversion trade on the
  reference price seen ahead of the market and end positive after fees; random ones lose.
- `Foresight`: the leaders' edge. Draws the market simulation's reference walk
  `-leader-edge-s` ahead and pins the market to its current point (not on anchored coins).
- `Server`: cohttp-async server for `POST /info`, `POST /exchange`, `GET /status` and the `/ws`
  websocket on the same port; owns the engine and its timers. `-response-delay-ms`
  delays every `/exchange` response while the order and its websocket events take effect
  at once, for double-placement tests. Each connection may queue at most 10,000 messages
  (`Config.max_ws_queue`); a subscriber that stops reading is disconnected and counted,
  without delaying other clients' acks.

## Dependencies

- Depends on: `fixed-decimal`, `exchange-core`, `exchange-core-engine`, `hl-protocol`,
  `order-book`, `market-data`, `price-anchor`, `hl-client`, `binance-client`.
- Used by: `hl-mm` (tests); built as an image by `infra`; target of `market-maker
  -venue hyperliquid -network local`.

## CI pin order

`fixed-decimal`, `exchange-core`, `order-book`, `exchange-core-engine`, `hl-protocol`,
`parquet`, `market-data`, `price-anchor`, `venue-net`, `hl-client`, `binance-protocol`,
`mm-core`, `binance-client` (through the shared `ox-setup` action).

## Behaviour

Described in [design/simulators.md](../design/simulators.md). In short: approvals act
for the address that signed them (EIP-712), orders signed by an approved agent act for
its account (agent nonce checked), and anything else acts for the `X-Address` header,
else `vaultAddress`, else `0x...01`, its signature unchecked; `-strict-signatures`
requires a valid signature on every request and ignores `X-Address`. Every address seen
is credited `-initial-balance` USD. Copy-trading support (agents, builder fees,
`maxBuilderFee`, `extraAgents`, `userFillsByTime`, `orderStatus`, the `leaderboard` info
request and `GET /leaderboard`, `webData2`, `userEvents`, 10 users per websocket
connection, leaders) is described in the hl-sim README; the parity with Hyperliquid is
tracked in [research/hl-sim-parity.md](../research/hl-sim-parity.md). The JSON journal
records approvals and extra actions too, and the engine input journal replays runs with
leaders and builder fees bit for bit.

## Known gaps

- `activeAssetCtx` is decoded by hl-sim's own module, not yet by `hl-protocol`.
- Trigger orders are rejected; `nSigFigs` and `mantissa` on `l2Book` are ignored.
- Fills carry no `builderFee` field (`User_fill` has none); `webData2` is a subset; only
  fills are sent on `userEvents`.
- Rejected orders reach `orderUpdates` only when they come through `/exchange` (not from
  leaders or noise traders).
- A scheduled cancel replayed from the JSON journal fires at the next journaled request
  rather than on the periodic clock step; the engine input journal is exact.
- Fill hashes are placeholders derived from the trade id.
- Without `-anchor`, prices are the market simulation's random walk; with leaders and
  `-leader-edge-s` above 0 that walk is drawn by `Foresight` instead of `Market_sim`. Live references
  exist for Hyperliquid and Binance only (the clients linked in); a Bybit or feed-repo
  reference needs its client added. `Server.replay` of the JSON `-journal` does not
  cover anchored runs; the binary `-input-journal` does.
