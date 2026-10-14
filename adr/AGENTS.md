# Architecture decision records (AGENTS.md)

Files are named `NNNN-short-title.md` with the next free four-digit number. Numbers are never reused
or renumbered, and a file is never deleted.

Each record has a title line (`# ADR NNNN: title`), a `Status:` line (`proposed`, `accepted` or
`superseded`), and the sections Context, Decision and Consequences.

- Write the context as the constraints at the time, with the numbers that drove the choice.
- A reversed decision gets a new record that supersedes the old one. The old record gets a
  `Superseded by` line; its other text stays as it was.
- Link the design page or repository page the decision affects, rather than repeating them.
- An ADR is needed for a choice that a later reader would otherwise reopen: a language or runtime
  choice, a storage format, a trust boundary, a deployment shape.
