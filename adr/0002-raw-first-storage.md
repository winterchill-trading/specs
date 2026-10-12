# ADR 0002: Raw-first storage

Status: accepted

## Context

Recorded market data feeds research and backtests for years. Normalizers have bugs, venue
formats change, and new fields become interesting after the fact. Data recorded only in a
normalized form loses whatever the normalizer dropped or got wrong, and that loss cannot
be repaired later.

## Decision

The system of record is the raw frame stream: every frame exactly as the venue sent it,
with the local receive time, in minute files
(`raw/<venue>/<stream>/<symbol>/<YYYY>/<MM>/<DD>/<HH>-<MM>.ndjson.zst`). Normalized
`bin_prot` event logs (`Market_data.Event_log`) and Parquet tables are derived products,
written alongside for convenience and rebuilt by idempotent jobs (`market-data
day-close`).

## Consequences

- A normalizer fix or a new table is a re-run, not a data loss.
- Storage holds the raw form (zstd-compressed) plus derived forms.
- Normalized types need stable binary versions (`Stable.V1`, shapes pinned by tests) so
  old event logs stay readable.
- The raw-to-norm regeneration tool does not exist yet; until it does, the event logs
  written live are the only normalized copy.
- See [design/data-platform.md](../design/data-platform.md).
