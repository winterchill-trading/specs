# venue-net

Reconnecting websocket and one-shot HTTP clients for Async: a general client layer with
nothing exchange-specific in it. Venue clients build their typed APIs on it; message
types, subscriptions, de-duplication and signing stay in the venue libraries. Opam
readiness: [research/opam-readiness/venue-net.md](../research/opam-readiness/venue-net.md).

| | |
| --- | --- |
| Repository | `winterchill-trading/venue-net` |
| opam package | `venue-net` |
| Library | `venue-net` (module `Venue_net`, sources in `src/`) |
| Binaries | none |
| Status | done |

## Key modules

- `Venue_net.Http`: `request`, `get`, `delete`, `put`, `post_json`, `post_form`,
  `decode_json`, `is_success`. Transport failures are `Error`; every HTTP status is `Ok`
  so venue error bodies can be decoded. Every call takes an optional `timeout` that
  closes the socket on expiry: the library opens its own conduit-async connection and
  uses cohttp's `Private.Make` functors only to write and parse messages.
- `Venue_net.Http.Record`: record mode (`VENUE_NET_HTTP_RECORD=<dir>` or
  `Record.set_dir`). Every completed request becomes one JSON fixture
  (`<METHOD>-<host and path>-<n>.json`: method, URI, request headers and body, status,
  response body) that `Record.load` reads back for decode tests. Header and query values
  whose names contain `key`, `sign`, `auth`, `token`, `passphrase` or `cookie` are
  redacted; request bodies are not.
- `Venue_net.Ws_client`: `connect ?headers ?ping ?max_silent_intervals
  ?initial_backoff ?max_backoff ?backoff_jitter ?handshake_timeout ?on_connect
  ?on_message ?max_buffered_messages ?log_name ?time_source ~url ()`, `messages`,
  `send`, `send_or_error`, `is_connected`, `reconnects`, `overflows`, `close`.
  Hand-written RFC 6455 handshake over Conduit, OpenSSL with SNI for `wss://`, exponential
  backoff (0.5 s to 30 s) spread by `backoff_jitter` (default 0.2) with the
  chosen delay logged, a `handshake_timeout` (default 10 s) that closes the attempt's
  socket, keepalive as text ping, ping frame or none, and a silence watchdog that
  replaces the socket. `time_source` drives keepalive, watchdog, handshake timeout and
  reconnect delay, so tests step them on a synthetic clock. `on_connect` runs after every
  handshake (resubscribe there). `max_buffered_messages` bounds unread `messages`: on
  overflow the connection is closed and the next one opens once the reader catches up.

The README records an audit of every `with_timeout`: the handshake timeout and the `Http`
timeout close their sockets, and the reconnect sleep and keepalive stop with the
connection. Tests cover the backoff schedule (1 s, 2 s, 4 s) and a stalled
handshake on a synthetic clock, the latter checking that the open descriptor count
returns to where it started, plus a jitter band property, record-mode redaction, an
`Http` timeout against a stalled server (descriptor count checked), chunked and `HEAD`
responses, and the `max_buffered_messages` bound on loopback.

## Dependencies

- Depends on: no org package (async, async_ssl, async_websocket, cohttp, conduit-async,
  ipaddr, yojson, uri; cohttp-async for tests only).
- Used by: `hl-client`, `binance-client`, `bybit-client`, the five feeds
  (`okx-feed`, `coinbase-feed`, `kraken-feed`, `deribit-feed`, `bitget-feed`),
  `hl-leaderboard` and `hl-copy-api` tests.

## CI pin order

None; `opam install . --deps-only --with-test`.

## Known gaps

- `https://` and `wss://` need `async_ssl` built against OpenSSL 3; without it
  conduit-async has no TLS. External build constraint; the README has the macOS
  `openssl@3` recipe.
- No HTTP connection reuse; a pool needs decisions on idle timeouts, per-host limits and
  what a timeout does to a pooled connection.
- `send` and `send_or_error` cannot tell whether the server received a frame; a frame
  queued just before a disconnect is lost. Delivery guarantees need application-level
  acknowledgements.
- The Jane Street `v0.18~preview` dependencies exist only on the OxCaml opam repository.

Fixed in the opam-readiness pass (2026-10-14): `Http` calls can be cancelled (`timeout`
closes the socket), `messages` can be bounded (`max_buffered_messages`), and a dropped
send can be detected (`send_or_error`).
