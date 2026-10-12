# Hot-path audit against the OxCaml techniques

Kind: reference.

Each hot path below names the code by `repo/path:line` (lines at the time of writing), its
current per-call cost where a bench or allocation test exists, the technique from this
directory that applies, an estimated win and the risk. Estimates are reasoned from the
measurements in the technique notes, not measured on the repository; each action's first
step is to add or rerun the repository's bench. Numbers quoted as "bench" come from the
repository pages under [repos/](../../repos/) and the allocation expect tests.

## Summary, ordered by expected win per effort

| # | Repo | Path | Technique | Estimated win | Effort | Risk |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | binance-client, bybit-client, hl-client, okx-feed | normalizer decode | [Zero-copy parsing](zero-copy-parsing.md) | 5-10x per trade/BBO frame, about 300-480 to 0 words | M per venue | M |
| 2 | market-recorder | `on_raw`, `Raw_writer.write` | Precomputed keys, [or_null](or-null.md), buffer reuse | 30-50% of non-JSON recorder cost (estimate) | S | L |
| 3 | order-book | `best_bid`, `mid`, `cancel` | [or_null](or-null.md), array of levels | 2 words to 0 per lookup; cancel O(level) to O(1) | S | L |
| 4 | mm-core | `Market_state`, `Quoter` | [Mixed blocks](mixed-blocks.md), [unboxed numbers](unboxed-numbers.md), [or_null](or-null.md) | 357 to under 150 words per quote (estimate) | M | M |
| 5 | fixed-decimal | `to_string`, `of_string` | [Zero-copy parsing](zero-copy-parsing.md), [`[@zero_alloc]`](zero-alloc-checker.md) | 3-5x on decimal parse in every normalizer | S | L |
| 6 | all hot libraries | build | [Flambda 2 `-O3`](flambda2-and-o3.md) in release images | order-book showed 66 to 37 ns per match | S | L |
| 7 | market-data | `Merge.sorted`, `Raw_minute` | Batch per pipe read, unboxed heap entries | 2-3x on replay and `merge` (estimate) | M | M |
| 8 | exchange-core | `step`, `submit` | Avoid per-step sort, [stack allocation](stack-allocation.md) of fill context | O(accounts log accounts) to O(changed) per step | M | M |
| 9 | price-anchor | `apply` | Follows 3 and 8; [or_null](or-null.md) in `set_mark` | 36 us to under 10 us per event at 500 orders (estimate) | M | M |
| 10 | parquet | `Chunk.add`, `finish` | Typed column buffers, [unboxed numbers](unboxed-numbers.md), one copy less | 1.5-2x rows/s (estimate) | M | L |
| 11 | venue-net | `serve` | One pipe hop less | Small; one closure and a pipe write per frame | S | L |
| 12 | fixed-decimal, order-book, scanners | API | [`[@zero_alloc]`](zero-alloc-checker.md) annotations | Regression guard, no speed change | S | L |

Effort: S under a day, M a few days. Risk: L local change with tests, M changes a
protocol-facing or state-shape contract.

## Venue normalizers (largest win)

Every normalizer parses the full frame into a `Yojson.Safe.t` tree and then decodes it
with `ppx_yojson_conv`:

- `binance-client/lib/feed_normalizer.ml:113` (`decode`, `Yojson.Safe.from_string` at
  `:115`); bench about 2.5 us and 472-478 words per trade, BBO or funding frame
  (`binance-client/test/test_allocation.ml`), L2 diffs about 27,000 words.
- `bybit-client/lib/ws_stream.ml:6`; bench 5.3 us per trade frame, 2.7 us BBO, 6.5 us L2.
  `bybit-client/lib/live_feed.ml:114` also formats the topic with `sprintf`
  (`bybit-protocol/lib/topic.ml:24`) on every order-book push only to use it as a table key.
- `hl-client/lib/normalizer.ml:131`, after a `String.sub` of the channel name at `:7`.
- `okx-feed/lib/wire.ml:182`; 431 words per trade frame. `okx-feed/lib/normalizer.ml:208`
  sorts all swaps per index-ticker message.
- Every normalizer calls `Instrument.create` (`market-data/lib/instrument.ml:25`), a fresh
  record per event.

**Technique.** A `[@zero_alloc]` hand scanner per high-rate stream (trades, BBO, depth
diffs) that writes into a reused mutable record and parses decimals straight to
fixed-point units, with the Yojson path kept as a fallback when a key is missing. Measured
on a Binance trade frame: 2417 ns and 298 words to 261 ns and 0 words (the remaining
normalizer work, building `Market_data` events, still allocates). Cache one
`Instrument.t` per subscribed symbol and the Bybit topic string per subscription.

**Win.** The recorder spends about 60% of its per-frame cost in JSON decoding
(`specs/repos/market-recorder.md`), so recorder throughput could roughly double; quoting
latency from book update to order drops by the decode time (2-6 us per frame).

**Risk.** Medium. Field order and escaping assumptions per venue; mitigated by running
every recorded fixture through both paths in a test and comparing outputs.

## market-recorder per-frame path

- `market-recorder/lib/recorder.ml:245` (`on_raw`) builds a `Metrics.Key` record per frame
  and hashes it three times: `Metrics.clamp_recv_ts` (`lib/metrics.ml:93`),
  `Hash_set.add` (`recorder.ml:256`) and `Metrics.frame` (`metrics.ml:86`), each through
  `Hashtbl.find_or_add` with a closure (`metrics.ml:69`); `last_frame <- Some recv_ts`
  (`metrics.ml:90`) allocates.
- `lib/raw_writer.ml:205` (`write`) formats the timestamp with `Date.to_string` and
  `sprintf` (`:11`), copies the frame into a new line with `String.concat` (`:210`),
  hashes a second key in `file_for` (`:178`), copies into a `Buffer` (`append`, `:189`)
  and again with `Buffer.contents` in `write_out` (`:118`). Bench: about 250k frames/s
  including normalization.

**Technique.** Resolve the counters record and the output file once per subscription and
pass them to `on_raw`; store `last_frame` as `Time_ns.t` with a sentinel or as
`Time_ns.t or_null`; format the timestamp into a reused `Bytes` buffer, recomputing the
date part only when the minute changes; blit the frame into the writer's buffer instead of
concatenating.

**Win.** Several hundred words and three hash lookups per frame removed (estimate 30-50%
of the non-JSON cost). **Risk.** Low; the raw line format is pinned by tests.

## order-book

- `order-book/lib/order_book.ml:113`: `best_bid`/`best_ask` return `Price.t option`
  (2 words each, `test/test_alloc.ml`); `mid` at `:119` builds a tuple match and a `Some`.
- `:362` (`cancel`): `Queue.filter_inplace` with a closure, O(orders in the level).
- Levels are an immutable `Price.Map` per side, so adding or removing a level rebuilds a
  path of the tree; `remove_level_if_empty` (`:151`) refreshes the cached top with
  `Map.max_elt`/`min_elt`, which return a tuple option.
- `sweep` (`:204`) already uses a `local_` taker and `exclave_`; each fill allocates a
  12-field `Fill.t` and a cons cell, which are results and must stay on the heap.

**Technique.** Return `Price.t or_null` (or add `best_bid_or_null` beside the option
version); measured 2 to 0 words. For cancel, keep orders in a doubly linked list per level
with the node in the order-id table, so removal is O(1). A sorted array or ladder of levels
indexed by tick for the near-touch range removes the `Map` rebuilds; that is a larger
change to benchmark first. Build release images with `-O3` (66 to 37 ns per one-fill
match on the existing bench).

**Risk.** Low for `or_null` (additive API). Medium for the level structure (covered by the
bisimulation test against the reference book).

## mm-core quoting

- `mm-core/lib/market_state.ml:47` (`on_book`) copies a 7-field record per book update;
  `var` and `alpha` are boxed `float` fields and `mid`/`microprice` are `Price.t option`;
  `mid_and_micro` (`:30`) returns a tuple of options.
- `mm-core/lib/strategy.ml:54` and `:163` copy the 15-field `Strategy.t` with
  `{ t with ... }` several times per tick.
- `mm-core/lib/quoter.ml:201` (`quote`): `Model.t` with three `float` fields (`:4`),
  `side_ladder` (`:146`) building lists with `List.rev`, `rungs` (`:98`) with
  `List.folding_mapi`, a 7-field `Rung.t` per level, `Some` and closures. Bench 362 ns and
  357 words per quote; quote plus reconcile 1125 ns and 748 words.

**Technique.** Make the per-update state a mutable record with `Float_u.t` fields
(measured 8 to 0 words for a two-float update) and `Price.t or_null` for `mid` and
`microprice`; keep the immutable `Strategy.t` interface for tests by snapshotting on
demand. In the quoter, compute `Model` into unboxed locals and build rungs into a
preallocated array per side rather than lists.

**Win.** Estimate 357 to under 150 words per quote; quoting is about 1 us against 2-6 us of
decode, so do this after the normalizers. **Risk.** Medium: `Strategy` is pure today and
its quickcheck properties rely on that; keep the pure version as the reference in a
bisimulation test.

## fixed-decimal

- `fixed-decimal/lib/fixed_decimal.ml:65` (`units_of_string`): `chop_prefix`, `lsplit2`,
  substrings, padding with `^` and two `Int.of_string` calls per parse; every normalizer
  calls it for every price and size.
- `:45` (`units_to_string`): `sprintf "%08d"` and three concatenations.
- `mul`, `div` and `Product` are already allocation-free (`test/test_fixed_decimal.ml`),
  5-8 ns and 26-31 ns.

**Technique.** A single-pass `[@zero_alloc]` parser over the string and a position range
(the `decimal` function in [zero-copy parsing](zero-copy-parsing.md)), exposed as
`of_substring_exn s ~pos ~len` so scanners can parse in place; `to_string` writing into a
caller's `Bytes`. Annotate `mul`, `div` and comparisons `[@zero_alloc]` in the signature so
regressions fail the build.

**Win.** Estimate 3-5x on parse; it is on every venue's path. **Risk.** Low; quickcheck
round-trip tests exist.

## market-data replay and logs

- `market-data/lib/merge.ml:4` (`sorted`): a `Pairing_heap` of `(v, i)` tuples, one
  `Pipe.read`, one `Pipe.write_if_open` and a Deferred bind per element. README: 600k lines
  in 0.9-1.2 s; "the per-line pipe merge, not timestamp parsing, is the bulk of it".
- `market-data/lib/raw_minute.ml:96` reads a whole file, decompresses, then `String.split`
  into a list; `:14` (`Line.parse`) copies the payload with `lsplit2`.
- `market-data/lib/framed.ml:94` allocates a `ref` per frame on read; reads stay under 310
  words per frame. `framed.ml:320` (`append`) calls `Time_ns.to_date` per frame
  (`store.ml:24`).
- `market-data/lib/event_log.ml:84` (`append`) builds a tuple key and calls
  `Hashtbl.find_or_add` with a closure per event (`:73`).
- `market-data/lib/candle_agg.ml:58` allocates a new 9-field candle per trade.

**Technique.** Merge in batches (`Pipe.read'` per input, merge the queues synchronously,
one write per batch); heap entries as a record with an immediate timestamp key rather than
a tuple compared through a closure; split lines by index into the decompressed buffer;
cache the date per minute; resolve the writer per stream once; make the open candle
mutable.

**Win.** Estimate 2-3x on `merge` and replay (0.36-0.42 M lines/s today). **Risk.** Medium;
ordering semantics are tested, keep the tests.

## exchange-core engine

- `exchange-core/engine/exchange.ml:649` (`step`) runs `liquidate`, which calls
  `Clearinghouse.mark_to_market` (`clearinghouse.ml:218`); that lists and sorts all
  accounts every step (`accounts`, `:65`).
- `exchange.ml:262` (`submit`): a `next_tid` closure, per-fill tuples from `settle_fill`,
  `Hashtbl.add_multi` cons cells, closures `order`, `filled`, `cancelled` per call.
- `exchange.ml:94` (`emit`) allocates a numbered event per event, and `:105` drains with
  `Queue.to_list`.

**Technique.** Keep accounts in a stable sorted array updated on account creation instead
of sorting per step, and mark only accounts with positions in the stepped symbol; pass the
fill context `local_` as order-book does; unboxed tuples for `settle_fill`'s pair.

**Win.** Per-step cost from O(accounts log accounts) to O(accounts with positions); matters
for the simulators and price-anchor at scale. No bench exists yet: add one first.
**Risk.** Medium; the input-journal replay test pins determinism.

## price-anchor

- `price-anchor/lib/anchor.ml:541` (`apply`) advances the sim clock, which calls
  `Exchange.step` (above). L2 events go through `Ref_book.apply_l2` into immutable maps,
  `Queue_ahead.refresh` (`queue_ahead.ml:18`) walks every resting order, and
  `eligible_size` (`anchor.ml:374`) sorts with a lexicographic closure list.
- `anchor.ml:304` (`set_mark`) allocates `Some px` per event to compare marks;
  `ref_book.ml:45` (`mid`) uses `Map.max_elt`/`min_elt`.
- Bench: 6.5 us per event with an empty book, 36 us with 500 resting orders.

**Technique.** Mostly structural (incremental queue-ahead, no per-trade sort); `or_null`
for marks and the reference mid. **Win.** Estimate under 10 us at 500 orders. **Risk.**
Medium.

## parquet writer

- `parquet/lib/writer.ml:46` (`Chunk.add`): an indirect closure call per cell; for doubles
  the accessor returns a boxed `float` unless inlined; byte-array min/max as
  `string option` (`:68`).
- `writer.ml:246` (`Writer.add`): `Array.iter` with a closure per row.
- `finish` copies each column with `Buffer.contents` (`:86`-`:126`), then
  `Zstd.compress` (`:179`) copies again.
- Bench: 9.4 M rows/s with zstd.

**Technique.** Typed column builders fed directly by the caller (no per-cell closure),
`float#` accumulation for min/max, compress from the buffer's underlying bytes. Dictionary
and RLE encodings are format work, outside this audit. **Win.** Estimate 1.5-2x rows/s;
the writer runs off the hot path (day close), so low priority. **Risk.** Low; DuckDB
oracle tests.

## venue-net

- `venue-net/src/ws_client.ml:293` (`serve`): each message passes through two pipes and a
  `Bus` subscriber closure. Framing and masking are in `async_websocket`, not ours.

**Technique.** Deliver frames to the consumer callback directly from the first pipe.
**Win.** Small. **Risk.** Low.

## Not worth doing now

- SIMD byte scanning: gated (no `ocaml_simd` on the switch, arm64 development).
- Domains for day close: the `parallel` library is not installed; measure per-table time
  first (theme action 19).
- Uniqueness-based in-place updates: no allocation saving until overwriting lands.
