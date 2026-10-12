# ADR 0004: Tardis-compatible raw format

Status: accepted

## Context

Tardis (tardis.dev) is the reference archive of crypto market data. Its raw data is
exchange-native messages, one per line, prefixed with the local receive timestamp, in
one-minute slices, with an empty line marking a disconnect. Tools and habits exist
around that shape, and a future replay server modelled on `tardis-machine` would serve
it.

## Decision

The recorder writes the same line shape: `<recv_ts> <frame>\n`, `recv_ts` in ISO 8601
UTC with microseconds, the frame byte for byte (newlines replaced by spaces), an empty
line for a disconnect, one file per venue, stream, symbol and UTC minute, zstd
compressed.

## Consequences

- Raw files are greppable and readable with `zstd -dc | head`.
- A replay server or a Tardis-style client can read them with little adaptation.
- Files are split per stream and symbol, unlike Tardis's per-exchange slices; a reader
  wanting an exchange-wide minute merges files by `recv_ts`.
- Text frames cost more space than a binary encoding before compression; zstd recovers
  most of it.
- Timestamp precision and the exact Tardis framing are not verified byte for byte
  against Tardis output.
