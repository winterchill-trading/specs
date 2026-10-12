# ADR 0006: Append-only compatible digest list for Event_log headers

Status: accepted

## Context

Every `norm/` event log file starts with a header holding the `bin_shape` digest of
`Event.Stable.V1.t`, and readers refused any file whose digest differed from the one the
code computes. That is strict on purpose: decoding bytes of another shape returns garbage
rather than an error. But the digest covers every type inside the event, including the
`Venue` variant, so growing `Venue` from three to eleven constructors changed it and made
every file written before unreadable, although appending a constructor at the end of a
variant leaves the encoding of the old values unchanged (the tag of an existing
constructor keeps its number, and `bin_prot` writes one tag byte up to 256
constructors). Each new venue would have repeated this.

The options were to drop the check (and lose the protection), to keep the old digest by
moving `Venue` out of the stable event (a breaking type change), to bump to
`Event.Stable.V2` with a converter for every additive change (a new type for a change
that does not alter old bytes), or to record which older shapes today's reader decodes
correctly.

## Decision

`Market_data.Event_log.compatible_digests` is a list of the digests today's reader
accepts, newest first, its head being `Event_log.digest`. `Framed` readers and writers
take such a list; a reader raises on any other digest, naming the accepted ones, and a
writer refuses to append to such a file. The list follows the Stable discipline:

- Only a change that keeps old bytes decoding the same (appending a variant constructor
  at the end) gets an entry. Anything else is `Event.Stable.V2` with a reader for the
  old files.
- The list is append-only: an entry is added at the head with a comment naming the
  change, and entries are never removed or reordered.
- Each entry comes with a fixture written by the code before the change (a scratch
  `git worktree` at the previous commit running `Event_log.Writer`), checked in under
  `test/fixtures/` and never regenerated, and a test that reads it with today's code;
  the tests pin the digest list.

The list holds `2f7f1bcb...` (eleven venues) and `4cf56dfb...` (Hyperliquid, Binance and
Bybit), with `test/fixtures/event-log-pre-venues` for the latter.

## Consequences

- Files from before the venue extension are readable again, and adding a venue costs a
  list entry, a fixture and a test instead of a new stable version.
- The check still catches real shape changes: a changed record or a reordered variant
  produces a digest that is not in the list.
- Correctness of an entry rests on review: the digest cannot tell an appended
  constructor from an incompatible change, which is why every entry needs a fixture
  that a test decodes.
- Day-close manifests include the event digest in their code version, so an entry
  change rebuilds Parquet tables once.
- See [design/data-platform.md](../design/data-platform.md) and
  [repos/market-data.md](../repos/market-data.md).
