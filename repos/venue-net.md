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
- `Venue_net.Ws_client`: `connect ?headers ?ping ?max_silent_intervals
  ?initial_backoff ?max_backoff ?on_connect ?log_name ~url ()`, `messages`, `send`,
  `is_connected`, `reconnects`, `close`. Hand-written RFC 6455 handshake over Conduit,
  OpenSSL with SNI for `wss://`, exponential backoff (0.5 s to 30 s), keepalive as text
  ping, ping frame or none, and a silence watchdog that replaces the socket.
  `on_connect` runs after every handshake (resubscribe there).

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
