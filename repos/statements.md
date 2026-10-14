# statements

OCaml customer-facing account statements over the [ledger](ledger.md) journal: one account in
one currency over a calendar month or up to twelve months of whole UTC days, with running
balances, two ways of presenting card and payment holds (netted or posting basis), checked
identities, and rendering as RFC 4180 CSV and as PDF in six languages. It is pure: it reads
journal records and returns values and bytes. It does not store anything, does not post to
the books, and does not cover multi-account or multi-currency packs.

| | |
| --- | --- |
| Repository | `winterchill-trading/statements` |
| opam package | `statements` |
| Library | `statements` (module `Statements`) |
| Binary | `statements` (`demo`, `journal`) |
| Status | done: library, CLI, example and property tests are in place |

## Key modules

| Module | Purpose |
| --- | --- |
| `Period` | Calendar months and UTC day ranges of at most 12 months; request validation with per-field problem codes |
| `Basis` | Netted (customer view, open holds listed as pending) or posting (every posting, nothing pending) |
| `Annotation` | Caller-supplied description, counterparty and category for each entry |
| `Statement` | The statement: opening, closing, lines with running balances; `Builder` for streaming, `check`, file names, `Stable.V1` form |
| `Locale`, `Catalogue` | English, German, French, Spanish, Russian and Kyrgyz labels, number and date formats, with checked overrides |
| `Csv` | RFC 4180 rendering, byte order mark, English headers, formula guard, optional localised preamble |
| `Pdf` | The statement document: A4, PDF 1.4, paging, repeated headers, footer mark |
| `Pdf_writer`, `Pdf_font`, `Truetype`, `Win_ansi` | The PDF toolkit underneath: objects, fonts, TrueType subsetting, WinAnsi encoding |

Rules enforced by the library:

- `Statement.create` checks `opening + money in - money out = closing` and the running
  balances against the ledger's own balances, and fails rather than return a disagreeing
  statement. Decoding a stable statement runs `check` again.
- Entries are selected by ledger business date, so consecutive periods split a journal exactly.
- Stable types (`Locale`, `Basis`, `Period`, `Annotation`, `Statement.Totals`, `Statement`)
  have `Stable.V1` bin_io with pinned digests.
- PDF output is deterministic. Standard Helvetica fonts are used when every string fits
  WinAnsiEncoding; otherwise a subset of the bundled Noto Sans Regular is embedded. The font is
  under the SIL Open Font License 1.1, committed unmodified, and nothing is fetched at build time.

## Tests

- `dune test`: expect tests for every module, including a month with every kind of line on both
  bases, statements streamed from a real journal file, all six languages, CSV and PDF structure;
  a cram test for the CLI.
- Quickcheck properties over random journals: netted lines equal the ledger's own camt.053
  entries, consecutive months chain, both bases end on the same available balance, `check`
  rejects a tampered statement, and CSV fields round-trip through an RFC 4180 reader.
- CI also renders the demo in every language on both bases and runs `qpdf --check` and
  `pdftotext` on each file (`scripts/check-pdf.sh`), and runs the quickstart example.

## Dependencies

- Depends on: [money](money.md), [ledger](ledger.md) (and through money,
  [fixed-decimal](fixed-decimal.md)). External: `core`, `zarith`, `ppx_jane`; `core_unix` for
  the command only.
- Used by: none yet.

## CI pin order

`fixed-decimal`, then `money`, then `ledger`. CI pins each from GitHub through the shared
`ox-setup` action, then runs `dune build`, `dune test`, the quickstart example, the PDF check
with `qpdf` and `poppler-utils`, an odoc build in which any warning fails, and the shared
`obj-magic` workflow.

## Known gaps

- Streams are stored uncompressed; a Latin statement is a few KB, one with the embedded font
  about 80 KB.
- The embedded font has no bold face (bold is drawn with an outline). Scripts other than Latin,
  Greek and Cyrillic, right-to-left text and kerning are not supported.
- The non-English texts should be reviewed by native speakers; `Catalogue.with_text` replaces
  any of them.
- One account and one currency per statement; a multi-currency or multi-account pack is several
  statements.
- No tagged PDF (accessibility) or PDF/A.
