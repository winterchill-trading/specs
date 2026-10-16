# sanctions-screening

Name screening against public sanctions lists for banks and payment firms. It parses the
OFAC SDN list (legacy CSV and advanced XML), the EU consolidated list (XML), the UK
Sanctions List (XML, the FCDO list that replaced OFSI's on 28 January 2026) and the
archived OFSI consolidated list (CSV), normalises names across scripts, scores
them with explainable integer components, indexes every list name for millisecond
screening, decides `Clear`, `Potential_match` or `Confirmed`, rescreens a population on a
list update, and runs a small case lifecycle with optional four eyes. Provider-neutral
and deterministic: the same inputs give the same result id and scores on every platform.

| | |
| --- | --- |
| Repository | `winterchill-trading/sanctions-screening` |
| opam packages | `sanctions-screening`, `sanctions-screening-pg` |
| Libraries | `sanctions-screening` (module `Sanctions_screening`), `sanctions-screening-pg` (module `Sanctions_screening_pg`) |
| Binary | `sanctions-screening` (`screen`, `rescreen`, `stats`) |
| Status | 0.1.1 (2026-10-16); UN parser open |

## Key modules

| Module | Purpose |
| --- | --- |
| `Unicode_fold`, `Translit`, `Normalize` | NFKD, marks and invisible code points removed, lowercase; Cyrillic (ICAO 9303), Greek (ELOT 743) and Arabic (BGN/PCGN) to Latin; honorifics, legal forms and vessel prefixes; a visual reading for look-alike letters; sorted, compact and skeleton keys |
| `Match` | Jaro-Winkler, Damerau-Levenshtein, token alignment (initials, patronymics), Soundex, consonant skeletons; per-mille integer scores; primitives `[@zero_alloc]` |
| `Ofac_csv`, `Ofac_xml`, `Eu_xml`, `Uk_xml`, `Uk_csv`, `Fixture`, `List_source` | Parsers into `Entry.t`; directory loading with format detection, lists held in memory (`load_files`) and the bundled fixture lists (`load_fixtures`) |
| `Entry`, `Dob`, `List_id`, `List_version`, `Snapshot` | Normalised entries, list versions with digests, list diffs |
| `Index`, `Lists` | Trigram inverted index with a Dice prefilter and skeleton trigrams |
| `Policy`, `Subject`, `Hit`, `Decision`, `Screening` | Thresholds and adjustments, subjects and payment counterparties, explained hits, decisions, `screen` and `rescreen` |
| `Case` | Case state machine with events and replay; four eyes on false positives by default |
| `Store`, `Store_memory`, `Store_conformance`, `Store_pg` | Persistence as `Store.S`, memory and PostgreSQL implementations, one conformance transcript |

## Design

- Scores are integers per mille. The name score is the maximum of edit similarity on
  sorted tokens, edit similarity on the separator-free form, a token score
  (`0.6 * token_set + 0.4 * token_cover` from a Monge-Elkan style alignment), Soundex
  overlap capped at 880 and a consonant-skeleton score capped at 930 for Arabic script.
  Hits start at 850 (870 for payments); date of birth, nationality, party type and weak
  aliases adjust the total and priority but never remove a hit by default.
- Normalisation never deletes a letter: invisible code points are dropped, unmapped
  scripts kept, and words that mix scripts or digits get a second, visual reading that is
  screened too. `test/adversarial.ml` lists the disguises that must hit.
- `Screening.Result.t` carries an id derived from the subject, context, list digests,
  policy digest and time, plus the list versions and the policy digest, so a decision can
  be replayed. `Decision.customer_view` hides alerts from customers (tipping-off).
- `rescreen` diffs the lists, screens the population against the delta's index only, and
  screens in full only subjects the delta can affect.
- Storage follows [ADR 0009](../adr/0009-postgres-replaceable-store.md): `Store.S` in
  domain types, idempotency keys on every write, expected versions on case events, SQL
  only in the `-pg` package and `migrations/`. The core package does not depend on
  pg-async.
- The `-pg` store owns one PostgreSQL schema (default `sanctions_screening`, configurable)
  with its own `schema_migrations` inside it, so it shares a database with the host
  application and transaction-monitoring without clashing; 0.1.0 installs (tables in
  `public`) are moved into the schema on connect.
- kyc-core keys hits by entry id within a screening; `Hit.to_kyc` uses the
  list-qualified key (`ofac-sdn:9001`) because ids repeat across lists.
- The fixture lists (invented parties) are embedded in the library and installed under
  `share/`, so applications can run demos and tests without files.
- The OFAC advanced XML is streamed from disk a megabyte at a time and each party is
  reduced to the fields used as it is read: 158 MB peak for the 128 MB file (883 MB in
  0.1.0; the legacy CSV takes 114 MB).

## Numbers

On a labelled set of 84 spellings of fixture entries and 44 other names, the default
policy finds every listed query (entry recall 97.5%), raises one false alert (2.3%) and
has 98.7% hit precision. Screening one name takes 0.2 to 2.6 ms against a synthetic list
of 20 000 entries and 0.3 to 0.7 ms against the real OFAC, EU and UK lists (30 826
entries); `Match.score` is 1.5 us with no allocation.

## Dependencies

- Depends on: [kyc-core](kyc-core.md) (hits and screen reasons as kyc-core records them);
  `sanctions-screening-pg` on [pg-async](pg-async.md). External: `core`, `core_unix`,
  `async_kernel`, `ppx_jane`; `async` and `core_bench` for tests and benchmarks.
- Used by: none yet. Onboarding and payee creation call `Screening.screen`; list
  publication calls `Screening.rescreen` (see the README's wiring section).

## CI pin order

`kyc-core`, `pg-async`. CI installs `libpq-dev` and `postgresql`, then runs shellcheck,
`dune build`, `dune test` (including the PostgreSQL conformance run on a throwaway
cluster) and the odoc build with warnings as errors.

## Known gaps

- No parser yet for the UN consolidated list.
- The prefilter can miss a truncated or reversed Latin spelling of an Arabic-script list
  name that the consonant skeleton scores at 850 or more.
- Soundex only (no Double Metaphone); addresses and identity documents not compared.
- Weights tuned on a small invented set; thresholds need tuning on real alert data.
