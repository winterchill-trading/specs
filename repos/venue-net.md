# venue-net

Venue-independent HTTP and websocket client plumbing for Async. Venue clients build
their typed APIs on it; message types, subscriptions, de-duplication and signing stay in
the venue libraries.

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
  so venue error bodies can be decoded.
- `Venue_net.Http.Record`: record mode (`VENUE_NET_HTTP_RECORD=<dir>` or
  `Record.set_dir`). Every completed request becomes one JSON fixture
  (`<METHOD>-<host and path>-<n>.json`: method, URI, request headers and body, status,
  response body) that `Record.load` reads back for decode tests. Header and query values
  whose names contain `key`, `sign`, `auth`, `token`, `passphrase` or `cookie` are
  redacted; request bodies are not.
- `Venue_net.Ws_client`: `connect ?headers ?ping ?max_silent_intervals
  ?initial_backoff ?max_backoff ?backoff_jitter ?handshake_timeout ?on_connect
  ?log_name ?time_source ~url ()`, `messages`, `send`, `is_connected`, `reconnects`,
  `close`. Hand-written RFC 6455 handshake over Conduit, OpenSSL with SNI for `wss://`,
  exponential backoff (0.5 s to 30 s) spread by `backoff_jitter` (default 0.2) with the
  chosen delay logged, a `handshake_timeout` (default 10 s) that closes the attempt's
  socket, keepalive as text ping, ping frame or none, and a silence watchdog that
  replaces the socket. `time_source` drives keepalive, watchdog, handshake timeout and
  reconnect delay, so tests step them on a synthetic clock. `on_connect` runs after every
  handshake (resubscribe there).

The README records an audit of every `with_timeout`: the handshake timeout closes its
socket, the reconnect sleep and keepalive stop with the connection, and `Http` has no
timeout of its own. Tests cover the backoff schedule (1 s, 2 s, 4 s) and a stalled
handshake on a synthetic clock, the latter checking that the open descriptor count
returns to where it started, plus a jitter band property and record-mode redaction.

## Dependencies

- Depends on: no org package (async, async_ssl, cohttp-async, conduit-async,
  async_websocket, yojson, uri).
- Used by: `hl-client`, `binance-client`, `bybit-client`.

## CI pin order

None; `opam install . --deps-only --with-test`.

## Known gaps

- `https://` and `wss://` need `async_ssl` built against OpenSSL 3; without it
  conduit-async has no TLS. On macOS with Homebrew `openssl@4`, see hl-client's OpenSSL
  notes.
- `messages` has no pushback and `send` drops frames while disconnected; callers must
  keep reading and resync after reconnects.
- `Http` calls cannot be cancelled: cohttp-async's `?interrupt` only covers the TCP
  connect, so a caller wrapping a call in `with_timeout` abandons a socket that stays open
  until the server answers.
