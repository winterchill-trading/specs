# Example queries

Kind: how-to.

Worked DuckDB queries over the Parquet tables of the [data platform](data-platform.md),
with notes on the columns they rely on. Each query was run with DuckDB 1.5 against tables
of the same column names and types as the day-close output.

## Running them

`market-data query -dir <data_dir> "SQL"` creates one view per table (`trades`, `bbo`,
`l2`, `funding`, `candles`) over `<data_dir>/*/*/parquet/<table>/*.parquet` and runs the
SQL with the `duckdb` CLI; `market-data views -dir <data_dir>` prints the `CREATE VIEW`
statements for an interactive `duckdb` session. The sizing queries at the end read files
directly and are run with plain `duckdb` from inside `<data_dir>`.

## Column notes

- **`venue`** is the lower-case venue name (`hyperliquid`, `binance`, `bybit`, and the
  newer venues in `Market_data.Venue`); **`symbol`** is the venue's own name (`BTC`,
  `BTCUSDT`), so the same asset has different symbols on different venues.
- **`exch_ts`, `recv_ts`** are `TIMESTAMP_NS` in UTC. `recv_ts` is the recorder's clock
  and is what files are partitioned by; `exch_ts` is the venue's time, except Hyperliquid
  funding, where it is a copy of `recv_ts`. Use `epoch_ns` for differences.
- **Prices and sizes** are `DECIMAL(18,8)`, exact. Sums widen to `DECIMAL(38,8)`, but a
  product of two of them does not widen and can overflow: cast to `DOUBLE` (or
  `DECIMAL(38,16)`) before multiplying.
- **`trades.side`** is the taker side, `buy` or `sell`; **`l2.side`** is the book side,
  `bid` or `ask`. `trade_id` is a string.
- **`l2`** has one row per price level. `seq` numbers the update within its file, so
  `(venue, symbol, seq)` identifies an update only within one day; `is_snapshot` rows
  replace the book, delta rows with `size = 0` remove a level. `level` is the position
  within the update, not the depth in the book.
- **`funding.rate`** is a `DOUBLE` per funding interval (hourly on Hyperliquid, eight
  hours on Binance and Bybit).
- **`candles`** have no `exch_ts`/`recv_ts`; `open_time` is the interval start and
  `interval_ns` its length (day close writes one-minute candles).
- `level`, `open` and `close` are keywords in some positions: write `AS level` when
  aliasing.

## Volume and VWAP per hour

```sql
SELECT venue, symbol, date_trunc('hour', exch_ts) AS hour,
       count(*) AS trades,
       sum(size) AS volume,
       sum(price::DOUBLE * size::DOUBLE) / sum(size::DOUBLE) AS vwap,
       sum(size) FILTER (WHERE side = 'buy') AS taker_buy_volume
FROM trades
WHERE exch_ts >= TIMESTAMP '2026-10-11' AND exch_ts < TIMESTAMP '2026-10-12'
GROUP BY ALL
ORDER BY venue, symbol, hour;
```

`sum(size)` stays exact; the VWAP casts to `DOUBLE` because `price * size` would not
widen.

## Spread and crossed quotes

```sql
SELECT venue, symbol,
       median((ask_price - bid_price)::DOUBLE
              / ((ask_price + bid_price)::DOUBLE / 2) * 1e4) AS median_spread_bps,
       count(*) FILTER (WHERE ask_price <= bid_price) AS crossed_or_locked
FROM bbo
WHERE recv_ts >= TIMESTAMP '2026-10-11' AND recv_ts < TIMESTAMP '2026-10-12'
GROUP BY ALL
ORDER BY venue, symbol;
```

A non-zero `crossed_or_locked` on one venue is a data problem (or a locked market) worth
checking before using the day.

## Trades with the prevailing BBO

```sql
SELECT t.venue, t.symbol, t.exch_ts, t.price, t.size, t.side,
       b.bid_price, b.ask_price,
       CASE WHEN t.side = 'buy' THEN t.price >= b.ask_price
            ELSE t.price <= b.bid_price END AS at_or_through_touch
FROM trades t
ASOF LEFT JOIN bbo b
  ON t.venue = b.venue AND t.symbol = b.symbol AND t.recv_ts >= b.recv_ts
WHERE t.symbol = 'BTCUSDT'
ORDER BY t.recv_ts
LIMIT 20;
```

`ASOF JOIN` picks, for each trade, the last BBO received at or before it. Joining on
`recv_ts` uses one clock; joining on `exch_ts` compares venue times, which for Binance
`bookTicker` and `aggTrade` come from different engines and can disagree by milliseconds.

## Top of an L2 snapshot

```sql
WITH snap AS (
  SELECT venue, symbol, max(seq) AS seq
  FROM l2
  WHERE is_snapshot AND venue = 'binance' AND symbol = 'BTCUSDT'
    AND recv_ts <= TIMESTAMP '2026-10-11 09:00:30'
  GROUP BY ALL
)
SELECT l2.side, l2.level, l2.price, l2.size
FROM l2 JOIN snap USING (venue, symbol, seq)
WHERE l2.level < 5
ORDER BY l2.side, l2.level;
```

This reads the last snapshot only; building the book at an arbitrary time means applying
the delta rows after it in `seq` order, which `Market_data.Replay_feed` does in OCaml.

## Receive latency per venue and stream

```sql
SELECT venue, 'trades' AS stream,
       quantile_cont(epoch_ns(recv_ts) - epoch_ns(exch_ts), 0.5) / 1e6 AS p50_ms,
       quantile_cont(epoch_ns(recv_ts) - epoch_ns(exch_ts), 0.99) / 1e6 AS p99_ms,
       count(*) FILTER (WHERE recv_ts < exch_ts) AS negative
FROM trades GROUP BY venue
UNION ALL
SELECT venue, 'bbo',
       quantile_cont(epoch_ns(recv_ts) - epoch_ns(exch_ts), 0.5) / 1e6,
       quantile_cont(epoch_ns(recv_ts) - epoch_ns(exch_ts), 0.99) / 1e6,
       count(*) FILTER (WHERE recv_ts < exch_ts)
FROM bbo GROUP BY venue
ORDER BY venue, stream;
```

`recv_ts - exch_ts` is network delay plus the clock offset between the venue and the
recorder; negative values mean the recorder's clock is behind. Only meaningful while the
recorder's clock error is small (see
[cloud-sinks-and-replication.md](cloud-sinks-and-replication.md#clock-bound)).

## Empty minutes

```sql
WITH minutes AS (
  SELECT unnest(generate_series(TIMESTAMP '2026-10-11 00:00:00',
                                TIMESTAMP '2026-10-11 23:59:00',
                                INTERVAL 1 MINUTE)) AS minute
),
seen AS (
  SELECT DISTINCT date_trunc('minute', recv_ts) AS minute
  FROM bbo WHERE venue = 'binance' AND symbol = 'BTCUSDT'
)
SELECT count(*) AS empty_minutes, min(minute) AS first, max(minute) AS last
FROM minutes ANTI JOIN seen USING (minute);
```

On a liquid symbol an empty minute is a recording gap, not a quiet market.

## Latest funding

```sql
SELECT venue, symbol, arg_max(rate, recv_ts) AS rate,
       arg_max(next_funding_time, recv_ts) AS next_funding_time,
       arg_max(mark_price, recv_ts) AS mark_price,
       arg_max((mark_price - index_price)::DOUBLE / index_price::DOUBLE * 1e4, recv_ts)
         AS premium_bps
FROM funding
GROUP BY ALL
ORDER BY venue, symbol;
```

## Daily bars from one-minute candles

```sql
SELECT venue, symbol, date_trunc('day', open_time) AS day,
       arg_min(open, open_time) AS open, max(high) AS high, min(low) AS low,
       arg_max(close, open_time) AS close, sum(volume) AS volume,
       sum(trade_count) AS trades
FROM candles
WHERE interval_ns = 60_000_000_000
GROUP BY ALL
ORDER BY venue, symbol, day;
```

## Replay sizing

Bytes per venue, stream, symbol and day of the raw minute files, to size replay files
and transfers. Run with `duckdb` from inside `<data_dir>`:

```sql
WITH files AS (
  SELECT size, string_split(filename, '/') AS p
  FROM read_blob('raw/*/*/*/*/*/*/*.ndjson.zst')
)
SELECT p[-7] AS venue, p[-6] AS stream, p[-5] AS symbol,
       make_date(p[-4]::INT, p[-3]::INT, p[-2]::INT) AS day,
       count(*) AS minute_files,
       sum(size) AS bytes,
       sum(size) // count(*) AS mean_file_bytes,
       max(size) AS largest_file_bytes
FROM files
GROUP BY ALL
ORDER BY day, bytes DESC;
```

`read_blob` yields `filename`, `content`, `size` and `last_modified`; only `size` is
selected. The path parts follow
`raw/<venue>/<stream>/<symbol>/<YYYY>/<MM>/<DD>/<HH>-<MM>.ndjson.zst`. A day has at most
1440 files per stream and symbol; fewer means gaps or a part-day.

The same for the Parquet tables, to compare formats:

```sql
SELECT p[-5] AS venue, p[-4] AS symbol, p[-2] AS table_name,
       split_part(p[-1], '.', 1)::DATE AS day,
       count(*) AS files, sum(size) AS bytes
FROM (SELECT size, string_split(filename, '/') AS p
      FROM read_blob('*/*/parquet/*/*.parquet'))
GROUP BY ALL
ORDER BY day, bytes DESC;
```
