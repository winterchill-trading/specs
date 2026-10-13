# hl-sim parity with Hyperliquid

Kind: reference.

Endpoint-by-endpoint comparison of [hl-sim](../repos/hl-sim.md) with the real Hyperliquid API,
as documented on 2026-10-13. The simulator was read at `hl-sim` `e34ed9e` and `hl-protocol`
`5a3ef7c` (their `main` branches at the time), with the engine semantics from the
`exchange-core` and `order-book` READMEs. Every Hyperliquid claim links the documentation page
it comes from (link list at the end); claims the docs do not state are marked **(unverified)**,
and claims backed by the recorded mainnet samples in `hl-protocol`
(`test/fixtures/mainnet-info-ws-2026-10-12/`) are marked **(recorded)**.

Rows were updated for `hl-sim` `2d67986` (copy-trading support and the parity round of
2026-10-13: fees, `orderUpdates` statuses, `orderStatus`, `scheduleCancel`,
`updateLeverage`, `batchModify`, builder codes, modify `a`, `expiresAfter`, nonces and
agent signatures, the websocket idle timeout and the `l2Book` cadence).

Status values:

- **same**: the wire shape and the behaviour a client can observe match.
- **partial**: the request is accepted and the shape matches, but fields or behaviour differ.
- **missing**: the simulator does not accept it (`/info` and `/exchange` answer 400; the
  websocket answers `{"channel": "error", ...}`).
- **sim-only**: exists in the simulator, not on Hyperliquid.

Consumers named in the impact column: `hl-mm` (and through its `Hl_venue`, `market-maker
-venue hyperliquid`), `hl-copy-engine` (planned; its needs come from
[design/copytrading.md](../design/copytrading.md)), and `market-recorder` (records the real
venue; runs against the simulators in `scripts/e2e-sims.sh`). "None" means no current or
planned consumer depends on it.

## Transport and request handling

| Item | Status | Difference | Impact |
| --- | --- | --- | --- |
| `POST /info`, `POST /exchange`, websocket `/ws` | same | Same paths; the simulator also upgrades `/` to a websocket | None |
| Unknown action, info or subscription type, malformed body | partial | Simulator: HTTP 400 `{"error": "<decoder message>"}`. Hyperliquid answers 422 with "Failed to deserialize the JSON body into the target type" ([ccxt #27081][ccxt-422], [SDK #55][sdk-55]; **unverified** for every case) | Clients that branch on the status code see a different one |
| Unknown fields (`builder`, cancel `f`, modify `a`, `expiresAfter`, `dex`, `aggregateByTime`) | partial | `builder`, modify `a` and `expiresAfter` are honoured (rows below); cancel `f` is accepted and moot (no trigger orders); `dex` and `aggregateByTime` are ignored | None |
| Number formatting | partial | Simulator prints `"100000"`; Hyperliquid prints `"100000.0"` for whole prices (**recorded**) | `market-recorder`: raw lines recorded from the simulator differ textually from mainnet; parsers accept both |
| Signatures | partial | `approveAgent` and `approveBuilderFee` act for their EIP-712 signer; orders, cancels and modifies whose L1 signature recovers (testnet or mainnet domain) to an approved agent act for its account. Other requests keep the `X-Address` fallback unless `-strict-signatures`, which requires a valid signature on every request and ignores `X-Address` (error texts are the simulator's) | `hl-copy-engine` agent keys are exercised; `hl-mm` signed runs can opt into strict mode |
| `X-Address` header, initial balance on first sight | sim-only | Any address is credited `-initial-balance` USD | All: no deposit flow is exercised |
| Nonces | partial | Checked per signer (100 highest kept, above the smallest, within `(T - 2 days, T + 1 day)`) for approvals, agent-signed actions and every request under `-strict-signatures`; unsigned requests are not checked ([nonces][nonces]) | `hl-mm` unsigned runs still accept any nonce |
| `expiresAfter` | partial | An action past its `expiresAfter` is rejected (simulator's text); no rate-limit penalty ([exchange][exchange]) | None |
| `vaultAddress` for subaccounts and vaults | partial | Treated as the acting address with no ownership check; Hyperliquid requires the master account's signature ([exchange][exchange]) | None today |
| IP rate limits (1200 weight/min, info weights 2/20/60, exchange `1 + floor(n/40)`) | missing | No limits, no 429 ([rate limits][rate]) | `hl-copy-engine` back-off path untested; `hl-mm` batching untested under limits |
| Address limits (1 request per 1 USDC traded, 10,000 buffer, cancel allowance) | missing | No limits ([rate limits][rate]) | `hl-copy-engine` small-account budget warning untested |
| Open order cap (1000 + 1 per 5M USDC volume, max 5000) | missing | No cap ([rate limits][rate]) | `hl-mm` with many levels |
| `GET /status`, `-response-delay-ms`, journals, `-anchor` | sim-only | Simulator operations | None |

## Info endpoint

| Request | Status | Difference | Impact |
| --- | --- | --- | --- |
| `l2Book` | partial | 20 levels a side as on Hyperliquid ([info][info]); `nSigFigs` and `mantissa` are ignored; an unknown coin returns `null` (Hyperliquid **unverified**) | `market-recorder` aggregation runs untestable |
| `allMids` | partial | Perps only, universe order; `dex` ignored; no spot mids | None |
| `meta` | partial | Three coins (BTC, ETH, SOL at 0, 1, 2) with mainnet's tier-0 max leverage (40, 25, 20); no `marginTableId`, `marginTables`, `isDelisted`, `marginMode` ([perpetuals][perps]). On mainnet SOL is not index 2 (**recorded**) | Clients must look indices up from `meta` (all do) |
| `clearinghouseState` | partial | No `cumFunding`, `returnOnEquity`; leverage always `cross`; `marginSummary` equals `crossMarginSummary` ([perpetuals][perps], **recorded**) | `hl-copy-engine` resync (leverage copying needs real leverage) |
| `openOrders` | same | Fields match the recorded sample including `origSz` and `cloid` (**recorded**) | None |
| `userFills` | partial | Every fill, newest first; Hyperliquid returns at most 2000 ([info][info]); `aggregateByTime` ignored; `hash` is a placeholder per trade (Hyperliquid: L1 transaction hash shared by a transaction's fills); no `twapId`, `builderFee`, `liquidation` | `hl-copy-engine` (liquidation detection) |
| `orderStatus` (by oid or cloid) | partial | Any order the server reported, with its latest status; the order object has limit-order trigger fields fixed (`isTrigger` false, `tif` null); `unknownOid` otherwise ([info][info]) | None |
| `frontendOpenOrders`, `historicalOrders` | missing | Trigger and TP/SL fields, history | None today |
| `userFillsByTime` | partial | Oldest first, at most 2000, both bounds inclusive; `aggregateByTime` ignored; no 10,000-fill cap ([info][info]) | None |
| `userRateLimit` | missing | | `hl-copy-engine` |
| `candleSnapshot` | missing | | None (candles come from `market-data`) |
| `metaAndAssetCtxs`, `predictedFundings`, `fundingHistory`, `perpsAtOpenInterestCap` | missing | Context snapshot for all coins; the simulator has the data (see `activeAssetCtx`) | `market-recorder` funding snapshot at start |
| `userFunding`, `userNonFundingLedgerUpdates` | missing | The engine pays funding but does not expose per-user history | `hl-copy-engine` PnL accounting |
| `activeAssetData` | missing | Leverage, `maxTradeSzs`, `availableToTrade` per user and coin ([perpetuals][perps]) | `hl-copy-engine` sizing |
| `userFees`, `portfolio`, `userRole`, `maxBuilderFee`, `approvedBuilders`, `referral` | partial | `maxBuilderFee` returns the approved cap in tenths of a bp, and `extraAgents` the account's agents; the others are missing | `hl-leaderboard` (`portfolio`, `userRole`) |
| `subAccounts`, `vaultDetails`, `userVaultEquities` | missing | | None today |
| `perpDexs`, `allPerpMetas`, `perpDexLimits`, `perpDexStatus` (HIP-3) | missing | Builder-deployed perps use asset `100000 + dex * 10000 + index` ([asset ids][assets]) | None |
| `spotMeta`, `spotMetaAndAssetCtxs`, `spotClearinghouseState`, `tokenDetails` | missing | No spot market ([spot][spot]) | None |
| Staking, borrow/lend, outcomes, deploy auctions | missing | | None |

## Exchange endpoint

| Action | Status | Difference | Impact |
| --- | --- | --- | --- |
| `order`, limit `Gtc`/`Ioc`/`Alo` | partial | Statuses `resting`, `filled`, `error` as documented ([exchange][exchange]); rule differences in [Order semantics](#order-semantics) | `hl-mm`, `hl-copy-engine` (IOC) |
| `order`, trigger (`tp`/`sl`, `isMarket`) | missing | Rejected per order with "Trigger orders are not supported."; Hyperliquid triggers on the mark price ([order types][order-types]) | `hl-copy-engine` (leaders' TP/SL arrive only as fills, so low); protective stops in any strategy |
| `grouping` `normalTpsl`, `positionTpsl` | missing | Decoded and ignored; no parent-child orders, no `siblingFilledCanceled` | Same as trigger orders |
| `builder` `{b, f}` on `order` | same | The approval must cover `f`, `f` at most 100 (0.1%), the builder at least $100 of account value; the fee moves from user to builder on every fill of those orders. Fills have no `builderFee` field ([exchange][exchange], [builder codes][builder]) | None |
| `cancel` | same | `"success"` or "Order was never placed, already canceled, or filled." plus the `asset=N` suffix; `f` ignored (Hyperliquid: rejects `f: true` on trigger orders) | `hl-mm` |
| `cancelByCloid` | same | As `cancel` | `hl-mm` |
| `modify` | partial | Replaces with a new order id (loses priority). With `a: false` a GTC replacement becomes ALO and an IOC one is refused, per the docs ([exchange][exchange]); a failed replacement leaves the target cancelled. Errors come back as `{"status": "err"}` (Hyperliquid **unverified**) | `hl-mm` requote path |
| `batchModify` | same | Answers with `order` statuses, one per modify ([exchange][exchange]) | None |
| `scheduleCancel` (dead man's switch) | same | At least 5 s ahead, no `time` unschedules, 10 triggers per UTC day; the cancelled orders' `orderUpdates` status is `scheduledCancel` (error texts are the simulator's) ([exchange][exchange]) | None |
| `updateLeverage` | partial | Cross leverage 1 to `maxLeverage`, reported in `clearinghouseState`; `isCross: false` is refused (cross margin only) | `hl-copy-engine` mirrors cross leverage |
| `updateIsolatedMargin`, `topUpIsolatedOnlyMargin` | missing | The engine is cross margin only | None today |
| `twapOrder`, `twapCancel` | missing | 30 s suborders, 3% slippage cap, 5 min to 7 days ([order types][order-types]) | None today |
| `trailingStop` | missing | Mark-based retracement trigger ([exchange][exchange]) | None |
| `approveAgent`, `approveBuilderFee` | same | User-signed EIP-712, verified; one unnamed and three named agents, a reused name or a new unnamed agent replaces the old one, `valid_until` expiry; builder approvals up to 1%, 10 builders, 0 revokes; an agent cannot sign them ([exchange][exchange], [nonces][nonces]) | None |
| `usdSend`, `spotSend`, `sendAsset`, `withdraw3`, `usdClassTransfer`, `vaultTransfer`, `subAccountTransfer`, `createSubAccount` | missing | No transfers; balance comes from `-initial-balance` | None today |
| `noop`, `reserveRequestWeight` | missing | Nonce invalidation and paid rate-limit room | None |
| Staking (`cDeposit`, `cWithdraw`, `tokenDelegate`), HIP-3 and abstraction actions | missing | | None |

## Websocket

| Message or subscription | Status | Difference | Impact |
| --- | --- | --- | --- |
| `subscribe`, `unsubscribe`, `subscriptionResponse` | partial | The echo is the re-encoded request, so unmodelled fields (`nSigFigs`, `dex`) are dropped; Hyperliquid echoes the subscription ([websocket][ws]) | Clients matching echoes by text |
| `ping` / `pong` | same | ([heartbeats][hb]) | None |
| Idle timeout | same | A connection the server has sent nothing to for 60 s is closed; pings keep it open ([heartbeats][hb]) | None |
| Server-side disconnects | missing | Hyperliquid disconnects "periodically and without announcement" ([websocket][ws]); the simulator only drops slow consumers | Reconnect paths: covered by `market-maker`'s fault phase restarting the simulator |
| Error message | partial | Simulator: `"Invalid message: <text>"`; Hyperliquid: `"Error parsing JSON into valid websocket request: <text>"` (**recorded**) | None |
| `post` (info and actions over the socket) | missing | `{"method": "post", "id", "request": {"type": "info" or "action"}}` answered on channel `post` ([post requests][post]) | `hl-mm` latency (one round trip saved per order) |
| `l2Book` | partial | Snapshot on subscribe, then pushes at least 500 ms apart (`-l2-interval-ms`), the first change after a quiet spell one 50 ms block later, as Hyperliquid's per-block pushes "at least 0.5" s apart ([subscriptions][subs]); `nSigFigs`, `mantissa`, `fast` (5 levels) ignored | None |
| `trades` | partial | Shape matches, `users` is `[buyer, seller]` as documented; `tid` is a counter, Hyperliquid's is a 50-bit hash of the two order ids; `hash` per trade | `market-recorder` dedup keys behave differently on simulator data |
| `allMids` | partial | Snapshot, then every 1 s; Hyperliquid's cadence is per block (**unverified**); `dex` ignored | None |
| `orderUpdates` | partial | Emits `open`, `filled`, `canceled`, `selfTradeCanceled`, `liquidatedCanceled` (liquidation cancels), `scheduledCancel`, and for orders rejected through `/exchange` `badAloPxRejected`, `iocCancelRejected`, `minTradeNtlRejected`, `perpMarginRejected`, `reduceOnlyRejected`, `tickRejected` or `rejected`. Missing: `triggered`, `reduceOnlyCanceled`, `marginCanceled` for insufficient margin, and rejections of leader or noise-trader orders ([info][info]) | None |
| `userFills` | partial | `isSnapshot: true` first, then streaming, as documented; snapshot holds every fill (Hyperliquid's snapshot size **unverified**); no `liquidation`, `builderFee`, `twapId`; `aggregateByTime` ignored | `hl-copy-engine` leader feed: liquidations look like ordinary closes |
| `activeAssetCtx` | partial | Sent on subscribe and every 1 s; `oraclePx` equals `markPx`; day volumes cover the UTC day, not a rolling 24 h; `impactPxs` is the best bid and ask, not the impact notional's average fill price ([funding][funding]) | `market-recorder` funding stream against the simulator |
| User subscriptions for any address | same | `userFills`, `orderUpdates`, `webData2`, `userEvents` for any address; at most 10 distinct users per connection across them (Hyperliquid's limit is per IP), refused with an `error` message in the simulator's words ([rate limits][rate]) | None |
| Connection limits (10 connections, 30 new per minute, 1000 subscriptions, 2000 messages per minute) | missing | ([rate limits][rate]) | `market-recorder` with many coins |
| `userEvents` (channel `user`: fills, funding, liquidation, nonUserCancel) | partial | Fills only ([subscriptions][subs]) | `hl-copy-engine` liquidation and funding events |
| `clearinghouseState`, `openOrders`, `activeAssetData`, `webData3` | missing | Pushed account state ([subscriptions][subs]); the simulator has a `webData2` subset (`clearinghouseState`, `openOrders`, `serverTime`, `user`) every second | `hl-copy-engine` resync without polling (saves weight 2 per poll) |
| `userFundings`, `userNonFundingLedgerUpdates` | missing | | `hl-copy-engine` PnL |
| `bbo` | missing | Sent only when the BBO changes on a block | `market-recorder` (derives BBO from `l2Book` today) |
| `candle` | missing | | None |
| `notification`, `twapStates`, `userTwapSliceFills`, `userTwapHistory`, `spotState`, `allDexs*`, `fastAssetCtxs`, `outcomeMetaUpdates` | missing | | None |

## Order semantics

| Rule | Status | Difference | Impact |
| --- | --- | --- | --- |
| Price tick and significant figures | same | 5 significant figures, at most `6 - szDecimals` decimals, integers always allowed ([tick and lot][tick]) | None |
| Size step | same | `szDecimals` | None |
| Tick error text | partial | Simulator: "Order has invalid price."; the documented string is "Price must be divisible by tick size." ([errors][errors]); Hyperliquid's text for sig-fig violations is **unverified** | `hl-mm` maps "Price must be divisible..." to `Unsupported` |
| Minimum order value | same | $10, reduce-only exempt; same text ([errors][errors]) | None |
| `asset=N` suffix on order errors | partial | Appended to every order error; on Hyperliquid **unverified** (not in the docs' strings) | `hl-mm` strips it either way |
| Self-trade prevention | partial | Simulator (order-book): matching stops at the taker's own resting order, the taker's remainder is cancelled, the resting order stays; with nothing filled the order fails with "Order would have matched against own resting order." Hyperliquid: the **resting** order is cancelled ("expire maker"), no fee, not in the trade feed, and the taker keeps matching behind it ([self-trade][stp]). The simulator's error text has no Hyperliquid equivalent | `hl-mm`, `market-maker`: a crossing requote behaves the opposite way; `hl-mm` maps a string that mainnet never sends |
| ALO crossing | same | "Post only order would have immediately matched, bbo was {bbo}." ([errors][errors]) | None |
| IOC with no match | same | "Order could not immediately match against any resting orders." ([errors][errors]) | None |
| Market orders | same | Hyperliquid has no market type on the API; SDKs send IOC 5% through, as the simulator's `market_order` does | None |
| Max order value ($30M market / 10x limit for 25x+ coins) | missing | ([contract specs][specs]) | None at simulator sizes |
| Oracle band ("Order price too far from oracle"), open interest caps | missing | ([errors][errors]) | Anchored runs with large factors |
| Reduce-only | partial | Clipped to the position, rejected if nothing to reduce; resting reduce-only orders are not cancelled when the position shrinks (`reduceOnlyCanceled` on Hyperliquid, [info][info]) | `hl-mm` closing orders |
| Duplicate cloid | partial | "Duplicate cloid." (Hyperliquid text **unverified**) | `hl-mm` maps it |
| Order ids | sim-only | Counter from 1; mainnet ids are about `5.7e11` (**recorded**) | None |

## Margin, funding, mark and liquidation

| Rule | Status | Difference | Impact |
| --- | --- | --- | --- |
| Initial margin | same | `size * mark / leverage`, leverage 1 to `maxLeverage` ([margining][margining]) | None |
| Maintenance margin | partial | Half the initial margin at max leverage, as documented; no margin tiers (`maintenance_margin_rate - maintenance_deduction` per tier, for example BTC 40x to 150M then 20x, [margin tiers][tiers]) | None at simulator sizes |
| Isolated and strict-isolated margin | missing | Cross only, one-way ([margining][margining]) | `hl-copy-engine` when a leader trades isolated |
| Mark price | partial | Last `set_mark` (market simulation reference or anchor), else last trade, else mid. Hyperliquid: median of oracle plus 150 s EMA of mid minus oracle, the median of BBO and last trade, and a weighted CEX perp mid; updated about every 3 s ([price indices][indices]) | Liquidation timing and unrealised PnL in `hl-mm` runs |
| Oracle price | partial | Equals the mark; Hyperliquid: stake-weighted median of validators' weighted CEX spot medians, every 3 s ([oracle][oracle]) | `activeAssetCtx` consumers |
| Funding interval | same | Hourly ([funding][funding]) | None |
| Funding rate | partial | Per-instrument constant, default 0.00125% per hour (Hyperliquid's interest component), or the anchor's rate; Hyperliquid adds the premium (sampled every 5 s, impact notional 20,000 USDC for BTC and ETH, 6,000 otherwise), clamp, 4% per hour cap ([funding][funding], [contract specs][specs]) | `market-maker` funding PnL; `market-recorder` funding stream from the simulator |
| Funding notional | partial | `size * mark * rate`; Hyperliquid uses the oracle price ([funding][funding]) | Differs only when mark and oracle differ, which they never do in the simulator |
| Liquidation trigger | same | Equity below maintenance margin at mark ([liquidations][liq]) | None |
| Liquidation execution | partial | The engine closes every position at the mark with no order on the book and can leave a negative balance. Hyperliquid sends market orders to the book (20% slices above 100k USDC, 30 s cooldown), then a backstop by the liquidator vault below 2/3 of maintenance ([liquidations][liq]); fills carry `liquidation` | `hl-copy-engine` liquidation detection; book impact of liquidations absent |
| Fees | same | Hyperliquid's base perps tier, taker 4.5 bp and maker 1.5 bp, configurable with `-taker-fee-bps` and `-maker-fee-bps`; no volume tiers, rebates, staking or referral discounts ([fees][fees]) | None |
| Builder fees | same | See `builder` on `order` | None |

## Ranked gaps

Ordered by value to the consumers above per unit of effort. Effort: S under a day, M one to
three days, L a week or more, for one agent including tests.

| # | Gap | Repos | Effort | Why |
| ---: | --- | --- | --- | --- |
| 1 | Self-trade prevention as "expire maker": cancel the resting order (`selfTradeCanceled` on its owner), keep matching the taker, drop the invented error | `order-book` (policy option), `exchange-core`, `hl-sim` | M | The one rule where the simulator does the opposite of Hyperliquid; it changes every crossing requote of `hl-mm` and `market-maker` |
| 2 | Fees at the base tier (4.5 / 1.5 bp), with a flag for other tiers | `hl-sim` `Adapt.instrument` | S | Every PnL number from simulator runs is optimistic |
| 3 | `orderUpdates` for rejected orders (`badAloPxRejected`, `iocCancelRejected`, ...) and `liquidatedCanceled` instead of `marginCanceled` for liquidation cancels | `hl-sim` `Adapt.order_update` | S | Recorded mainnet behaviour; `hl-mm` already maps these statuses |
| 4 | `orderStatus` info request by oid and cloid | `hl-protocol`, `hl-sim` (engine keeps orders' final states) | S-M | Reconciliation after a lost ack in `hl-mm` and `hl-copy-engine` |
| 5 | `scheduleCancel` dead man's switch | `hl-protocol`, `hl-sim`, `hl-client` | S | Safety feature both trading binaries should use and test |
| 6 | `updateLeverage` (cross) and `activeAssetData` | `hl-protocol`, `hl-sim` (engine has `set_leverage`) | S | `hl-copy-engine` mirrors leader leverage; margin realism |
| 7 | Copy-trading set already on the roadmap: `approveAgent`, `approveBuilderFee`, builder fee charging, `maxBuilderFee`, `userRole`, `userFillsByTime`, `portfolio`, fill `liquidation` field | `hl-protocol`, `hl-client`, `hl-sim` | L | Planned under the copy-trading platform; listed here so the parity items are not done twice |
| 8 | Optional signature and nonce checking (`-verify-signatures`): recover the signer, map agents to masters, keep the 100-highest nonce set and the time window | `hl-sim` (uses `hl-client` signing) | M | Catches signing and nonce bugs before testnet; needed for agent semantics in item 7 |
| 9 | `batchModify` and the `a` (`always_place`) flag on modify; check the modify error shape on testnet | `hl-protocol`, `hl-sim` | S | One-request ladder requotes for `hl-mm` |
| 10 | Websocket idle timeout (60 s) and a `-ws-drop-every` fault option | `hl-sim` | S | Exercises heartbeat and reconnect code continuously |
| 11 | `l2Book` cadence option matching mainnet (0.5 s minimum between pushes) and `nSigFigs`/`mantissa` aggregation | `hl-sim`, `order-book` (aggregation) | S-M | Realistic message rates for `hl-mm` and the recorder |
| 12 | Push account channels: `clearinghouseState`, `openOrders`, `userEvents`, `userFundings` | `hl-protocol`, `hl-sim` | M | `hl-copy-engine` resync without polling; liquidation and funding events |
| 13 | Rate limits behind a flag: IP weights with 429, address budget, 1000 open orders, websocket limits including 10 unique users | `hl-sim` | M | `hl-copy-engine` back-off and leader-sharing paths |
| 14 | Separate oracle and mark (oracle from the anchor's reference or the random walk, mark by the documented median), funding from premium with the clamp, paid on oracle notional | `exchange-core` (oracle input), `price-anchor`, `hl-sim` | M-L | Funding and liquidation realism; `activeAssetCtx` fields become meaningful |
| 15 | Book liquidations: market orders through the book, 20% slices, backstop account, `liquidation` on fills | `exchange-core`, `hl-sim` | L | Liquidation flow visible to other traders and to `hl-copy-engine` |
| 16 | Trigger orders (TP/SL, `normalTpsl`/`positionTpsl` grouping) on the mark price | `exchange-core` (trigger book), `hl-sim` | L | Protective stops for any strategy; copy of leaders' stops if wanted |
| 17 | `metaAndAssetCtxs`, `fundingHistory`, `predictedFundings`, `candleSnapshot`, `bbo` channel | `hl-protocol`, `hl-sim` | M | Recorder and research tooling against the simulator |
| 18 | `meta` margin tables and margin tiers | `hl-protocol`, `exchange-core`, `hl-sim` | M | Large-position realism only |
| 19 | Websocket `post` method | `hl-sim`, then `hl-client` | M | Lower-latency order path for `hl-mm` |
| 20 | Wire cosmetics: `"x.0"` prices, Hyperliquid's websocket error text, 422 on undecodable bodies, `twapId: null` in fills | `hl-protocol`, `hl-sim` | S | Textual fidelity of recorded simulator frames |
| 21 | Isolated margin, spot, TWAP, trailing stops, transfers, subaccounts and vaults | `exchange-core`, `hl-protocol`, `hl-sim` | L each | No consumer needs them yet |

## Sources

Hyperliquid documentation pages, read on 2026-10-13 (each page is also served as Markdown by
appending `.md`):

- API: [exchange endpoint][exchange], [info endpoint][info], [perpetuals][perps],
  [spot][spot], [websocket][ws], [subscriptions][subs], [post requests][post],
  [timeouts and heartbeats][hb], [error responses][errors],
  [rate limits and user limits][rate], [nonces and API wallets][nonces], [signing][signing],
  [tick and lot size][tick], [asset ids][assets].
- Trading: [order types][order-types], [self-trade prevention][stp],
  [margining][margining], [margin tiers][tiers], [liquidations][liq], [funding][funding],
  [fees][fees], [contract specifications][specs], [robust price indices][indices],
  [oracle][oracle].
- HTTP 422 on undecodable bodies: [ccxt issue 27081][ccxt-422],
  [Python SDK issue 55][sdk-55].

[exchange]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint
[info]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint
[perps]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/perpetuals
[spot]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/spot
[ws]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket
[subs]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions
[post]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/post-requests
[hb]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/timeouts-and-heartbeats
[errors]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/error-responses
[rate]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/rate-limits-and-user-limits
[nonces]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/nonces-and-api-wallets
[signing]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/signing
[tick]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/tick-and-lot-size
[assets]: https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/asset-ids
[order-types]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/order-types
[stp]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/self-trade-prevention
[margining]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/margining
[tiers]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/margin-tiers
[liq]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/liquidations
[funding]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/funding
[fees]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/fees
[builder]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/builder-codes
[specs]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/contract-specifications
[indices]: https://hyperliquid.gitbook.io/hyperliquid-docs/trading/robust-price-indices
[oracle]: https://hyperliquid.gitbook.io/hyperliquid-docs/hypercore/oracle
[ccxt-422]: https://github.com/ccxt/ccxt/issues/27081
[sdk-55]: https://github.com/hyperliquid-dex/hyperliquid-python-sdk/issues/55
