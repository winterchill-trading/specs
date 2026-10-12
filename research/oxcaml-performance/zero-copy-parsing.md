# Zero-copy parsing: hand scanners, Bigstring and Iobuf

Kind: reference.

## What it is

Reading the fields a hot path needs directly from the receive buffer, by position, into
integers or a caller-owned mutable record: no JSON tree, no substrings, no boxed numbers.
For binary data, `Bigstring` getters and `Iobuf` cursors read fixed-width fields without
allocating. Combined with `let mutable` and `[@zero_alloc]`, the parser becomes a proven
zero-allocation function.

## When it pays

Venue normalizers. Every org normalizer builds a full `Yojson.Safe.t` tree per frame and
then decodes it with `ppx_yojson_conv`; JSON decoding is about 60% of the recorder's
per-frame cost and Binance depth diffs decode at about 6 minor words per byte (GOTCHAS.md).
A hand scanner pays for the high-rate streams (trades, BBO, depth diffs) of venues whose
field order is stable. Rare messages (subscription acks, errors) keep the Yojson path as a
fallback.

## Syntax on 5.2.0+ox (verified)

```ocaml
type trade = { mutable px : int; mutable qty : int; mutable ts : int; mutable buyer_maker : bool }

(* position just after [key] at or after [from], or -1 *)
let[@zero_alloc] find_key s ~from key =
  let n = String.length s and k = String.length key in
  let first = String.unsafe_get key 0 in
  let mutable i = from in
  let mutable found = -1 in
  while found < 0 && i + k <= n do
    if not (Char.equal (String.unsafe_get s i) first) then i <- i + 1
    else begin
      let mutable j = 1 in
      while j < k && Char.equal (String.unsafe_get s (i + j)) (String.unsafe_get key j) do
        j <- j + 1
      done;
      if j = k then found <- i + k else i <- i + 1
    end
  done;
  found

(* decimal at [pos], quoted or bare, as an int scaled by 10^8 *)
let[@zero_alloc] decimal s pos = ...
let[@zero_alloc] scan_trade s (t : trade) = ...   (* p, q, T, m searched in order *)
```

Binary fields from a buffer:

```ocaml
let[@zero_alloc] read_header (b : Bigstring.t) ~pos =
  Bigstring.get_int32_le b ~pos + Bigstring.get_int64_le_trunc b ~pos:(pos + 4)

let iobuf_sum (buf : (read, Iobuf.seek, Iobuf.global) Iobuf.t) =
  let mutable acc = 0 in
  while Iobuf.length buf >= 8 do acc <- acc + Iobuf.Consume.int64_le_trunc buf done;
  acc
```

`Iobuf` is library `core_kernel.iobuf`.

## Measured

One Binance `aggTrade` frame (205 bytes) from `binance-client/test/fixtures/trades.jsonl`,
extracting price, quantity, trade time and the maker flag:

| Path | Words per frame | Time dev | Time release `-O3` |
| --- | ---: | ---: | ---: |
| `Yojson.Safe.from_string`, `Util.member`, same decimal parser | 298 | 2417 ns | 2406 ns |
| hand scanner, `[@zero_alloc]` | 0 | 261 ns | 262 ns |

The first scanner version, which restarted every key search from the start of `"data"`
and compared every byte, took 883 ns; searching in the venue's field order with a
first-byte test cut it to 261 ns. A third-party zero-allocation HTTP parser in OxCaml
reports 154 ns for a 35-byte request and 0 heap words, about twice the throughput of a
conventional parser.

## Pitfalls

- A hand scanner is a protocol commitment: test it against every recorded fixture and
  fall back to the Yojson decoder when a key is missing (the scanner returns `false`).
- JSON escapes (`\"`, `\u...`) inside string values break naive key search; restrict
  scanners to fields whose values cannot contain them (numbers, booleans, fixed
  enumerations) and keep a slow path.
- `Iobuf`'s type carries read/write, seek and locality parameters; the third parameter
  (`Iobuf.global` above) must be spelled out in signatures on v0.18.
- Async delivers each websocket message as a fresh `string` (venue-net uses
  `async_websocket`), so zero-copy stops at the frame; the frame itself is still one
  allocation per message.

## Sources

- Iobuf: <https://ocaml.janestreet.com/ocaml-core/v0.11/doc/core/Core/Iobuf/Expert>
  (older version; signatures differ on v0.18).
- <https://anil.recoil.org/notes/oxcaml-httpz> (third-party).
- Our note [2026-10 FUSE server](../janestreet/blog/2026-10-linux-engineering-depot-fuse.md)
  (string round trips between I/O buffers dominate allocation).
