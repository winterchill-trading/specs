# webauthn

Pure-OCaml WebAuthn (Level 2 and 3) and FIDO2 passkey relying-party verification: random
challenges with an expiry, options JSON for `navigator.credentials.create` and `get`,
registration and assertion verification, and a credential store interface. Any service that
holds accounts needs the same checks. It persists nothing, calls no network service and reads
no environment variables; every check runs on responses passed in. It does not validate
attestation certificate chains and does not interpret extensions.

| | |
| --- | --- |
| Repository | `winterchill-trading/webauthn` |
| opam package | `webauthn` |
| Library | `webauthn` (module `Webauthn`), plus `webauthn.testing` (module `Webauthn_testing`) |
| Binary | `webauthn` (`challenge`, `cbor`, `inspect`, `verify-registration`, `verify-authentication`) |
| Status | done: library, CLI, test vectors and CI are in place (CHANGES lists it as Unreleased) |

## Key modules

| Module | Purpose |
| --- | --- |
| `Challenge` | CSPRNG challenge with an expiry, constant-time comparison, a stable form for a session |
| `Relying_party` | RP ID, allowed origins and top origins for cross-origin iframes |
| `Options` | Creation and request options in the Level 3 JSON form |
| `Response` | `RegistrationResponseJSON` and `AuthenticationResponseJSON` parsing |
| `Registration` | `verify`: the relying-party steps of section 7.1, producing a `Credential.t` |
| `Authentication` | `verify`: section 7.2, including sign-count regression, producing the updated record |
| `Credential` | The stored credential record, with a stable bin_prot and sexp form |
| `Verify_error` | Every refusal, each with a stable snake_case code |
| `Attestation` | Attestation objects; "none" and "packed" self attestation, and a policy for other formats |
| `Authenticator_data`, `Client_data` | Authenticator data (flags, counter, credential) and `CollectedClientData` |
| `Cose`, `Cbor` | COSE keys (ES256, RS256); RFC 8949 decoder with limits and deterministic encoder |
| `P256`, `Rsa` | ECDSA P-256 verification over zarith; RSASSA-PKCS1-v1_5 SHA-256 verification |
| `Base64url` | Unpadded base64url used for every byte string in JSON |
| `Store`, `Store_memory` | The credential store interface `Store.S` and an in-memory implementation |
| `Soft_authenticator`, `Store_conformance` | In `webauthn.testing`: a software authenticator and a store conformance suite |

Rules the caller owns:

- A challenge is single use: remove it from the session before verifying, whatever the outcome.
- `Store.S.add` refuses a credential ID that is already registered, and `Store.S.update` is a
  compare-and-set on the counter.
- A `sign_count_regressed` refusal may mean a cloned authenticator; the caller decides whether
  to lock the credential.

## Tests

- `dune test`: expect tests per module, Quickcheck properties, and a cram test (`test/cli.t`)
  that runs every CLI command.
- Test vectors keep their provenance in `test/vectors/`: W3C Level 3 section 16 vectors,
  Wycheproof ECDSA P-256 and RSA signature cases, fixtures generated here and checked by
  py_webauthn, and responses recorded from py_webauthn's test suite.
- Bin digests of the `Stable.V1` types (`Credential`, `Challenge`, `Cose`, `Aaguid`) are
  pinned; each refusal code has a test in `test/test_ceremonies.ml`.
- `dune build @examples/runtest` runs `examples/passkey_flow.ml` (sign-up and sign-in against
  `Store_memory` and the software authenticator) and checks its output.

## Dependencies

- Depends on: no org packages. External: `core`, `core_unix`, `async_kernel`, `yojson`,
  `zarith`, `cryptokit`, `ppx_jane` (`async` for tests only).
- Used by: none yet.

## CI pin order

None. The library has no sibling dependencies, so CI pins no repositories. It runs the
`ox-setup` action from `infra`, `dune build`, `dune test`, `dune build @examples/runtest`,
and the shared `obj-magic` workflow.

## Known gaps

- Attestation certificate chains (X.509 path validation, FIDO Metadata Service lookups) are not
  implemented. Formats other than "none" and "packed" self attestation are refused, or accepted
  unverified with `Attestation.Policy.Accept_unverified`.
- Only ES256 and RS256 keys; ES384, ES512 and EdDSA are refused as `unsupported_algorithm`.
- Extensions are passed through but not interpreted; `credProps` is only requested.
- Origins are compared as exact strings; there is no related-origin support.
- An unrelated package named `webauthn` exists in the public opam repository, so this one is
  installed by pinning its GitHub repository.
