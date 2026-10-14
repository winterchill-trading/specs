# Design pages (AGENTS.md)

Kind: reference.

This directory holds the cross-repository designs. Each page covers one topic that spans repositories,
and links to the `repos/` pages and ADRs it depends on rather than repeating them.

- Each page states its kind on the line after the H1 (`Kind: tutorial`, `how-to`, `reference` or
  `explanation`). Keep the line when editing; change it when the page changes kind.
- Read the page for the area you will change before editing code there (for example `price-anchor.md`
  before touching a simulator's anchor flags, `data-platform.md` before a storage format).
- A change to an on-disk format, file layout, wire protocol or venue adapter contract updates the page in
  the same change, and states the new shape in full.
- Decisions with a trade-off go to `../adr/` as a numbered record; the design page links to it.
- Open questions stay in the page under an explicit heading, so they can be found and closed.
- Present tense for what is built; "planned" for what is not. Each claim must match the code it names.
