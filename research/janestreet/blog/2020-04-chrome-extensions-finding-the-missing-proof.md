# Chrome extensions: Finding the missing proof

- Source: <https://blog.janestreet.com/chrome-extensions-finding-the-missing-proof/>
- Published: 2020-04-17
- Kind: blog post

## Summary

- A walkthrough of self-hosting Chrome extensions on an internal web server for Linux
  desktops, after hitting the opaque `CRX_REQUIRED_PROOF_MISSING` error at every step.
- Packing: the CRX format moved from CRX2 to CRX3 in 2019, breaking older scripts; use
  Chrome's `--pack-extension` with a stable key file so the extension ID (derived from the
  public key) does not change; on headless servers it still needs an X display, so run Xvfb.
- Serving: an HTTPS server (nginx) with a certificate chained to a test CA imported into
  Chrome, and the right MIME types for `.crx` and `.xml`.
- The extension manifest needs an `update_url` pointing at an update XML file; contrary to
  the docs at the time, the XML namespace must be the plain http update2 URL.
- Enterprise policies: `ExtensionInstallSources` must include both the hosting site and the
  referring page (pasting the CRX URL never works), an allowlist entry is required when a
  wildcard blocklist is in place, and force-install entries point at the XML, not the CRX.
- Chrome on Linux has no per-user policies; the workaround is PAM polyinstantiated
  directories via `namespace.conf`, which can lock users out if misconfigured.

## Relevance to us

- Desktop browser administration; nothing in our stack ships browser extensions.
  **Action:** none.

Tags: `ops`, `deployment`
