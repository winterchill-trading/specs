# Core Gems: Time

- Source: <https://blog.janestreet.com/core-gems-time/>
- Published: 2009-11-07
- Kind: blog post

## Summary

- Core models time with separate types: `Time.t` (absolute instant), `Time.Span.t`
  (duration), `Time.Ofday.t` (time of day), `Date.t`, `Weekday.t` and a time zone type.
- In 2009 the first three were all float seconds underneath, but distinct types make
  signatures such as `diff : Time.t -> Time.t -> Span.t` and
  `add : Time.t -> Span.t -> Time.t` rule out nonsense like adding two instants.
- Core reimplemented Unix time zone handling over the system zone database, because the
  libc API requires setting the `TZ` environment variable, which is unsafe with threads.
- At the time, time zones were not yet integrated into `Time` itself.

## Relevance to us

- **OCaml practice:** Separate types for instants and durations rule out unit mistakes that raw
  integers allow. **Action:** change the `*_ms` integer fields of `Params` in
  [mm-core](../../../repos/mm-core.md) (`requote_interval_ms`, `order_ttl_ms`, `max_data_age_ms`) to
  `Time_ns.Span.t`.
- Raw `int` nanosecond fields such as `recv_ts` and `exch_ts` in
  [market-data](../../../repos/market-data.md) are a deliberate trade for compact bin_io and Parquet
  columns and should stay.

Tags: `clocks`, `ocaml-practice`, `stable-types`
