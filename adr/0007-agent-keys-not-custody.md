# ADR 0007: Agent keys instead of custody of user keys

Status: accepted

## Context

The copy-trading platform ([design/copytrading.md](../design/copytrading.md)) places
orders in its users' Hyperliquid accounts around the clock, while the users are not
online. Something on the server must sign those orders.

The options were:

- holding the user's wallet private key (custody): the platform could do anything the
  user can, including withdrawals, and a breach loses user funds;
- asking the user to sign each order in the browser: impossible for unattended
  mirroring;
- a Hyperliquid vault the leader manages: changes the product (users deposit into the
  leader's vault, no per-user caps or scaling) and needs the leader's participation;
- an agent ("API wallet") the user approves with `approveAgent`: a separate key that
  signs for the user's account, which Hyperliquid documents as "only used to sign"
  ([nonces and API wallets](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/nonces-and-api-wallets)).

## Decision

The platform generates a fresh secp256k1 agent key per follower in `hl-copy-api`,
stores it encrypted at rest under a master key taken from the environment, and returns
only the agent address plus the `approveAgent` typed data. The user signs that typed
data with their own wallet in the browser; the API submits it. The user's private key
never reaches the platform.

- The agent is approved under a fixed name with a `valid_until` expiry (at most 180
  days, per the
  [exchange endpoint](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint)
  page), so it does not displace the user's own unnamed API wallet and lapses on its
  own.
- Rotation re-approves the same name with a newly generated key; agent addresses are
  never reused, because a deregistered agent's nonce state may be pruned and old
  signatures could replay.
- The optional builder fee is approved by the user's wallet as well, since Hyperliquid
  requires `approveBuilderFee` to come from the main wallet, not an agent.

## Consequences

- A leaked agent key can trade the user's account, within what the account's margin
  allows; it is assumed not to withdraw (not stated in the documentation; to verify on
  testnet). The user can revoke it at any time by approving another agent under the
  same name.
- The platform holds secrets anyway: the encrypted agent keys and the master key.
  Losing the master key means every user re-approves; leaking both is the worst case
  and is bounded by the point above.
- Users can see and revoke the platform's agent in Hyperliquid's own interface,
  independent of the platform.
- Each follower uses its own agent, so nonces (tracked per signer) never collide
  between followers.
