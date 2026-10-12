# Commas in big numbers everywhere: An OpenType adventure

- Source: <https://blog.janestreet.com/commas-in-big-numbers-everywhere/>
- Published: 2019-10-14
- Kind: blog post

## Summary

- The author, a performance engineer, kept counting digits of nanosecond latencies in the
  editor, terminal and Jupyter, and solved it once for all tools with a font, Numderline,
  that groups digits through OpenType shaping.
- Shaping pipeline: `cmap` maps characters to glyphs, `GSUB` substitutes glyphs, `GPOS`
  positions them, and `glyf` holds outlines.
- Counting digits from the right needs the rarely used "reverse chaining contextual single
  substitution" lookup (built for Arabic); rules written in Adobe feature files compile to
  OpenType tables.
- State can only be carried by swapping glyphs, so the font holds several copies of each
  digit (one per position modulo 6, plus an extra for comma placement) and rules rewrite one
  class into the next.
- Tooling: a FontForge-based patcher derived from the Powerline patcher generates the copies
  and feature file; FontForge crashed compiling `reversesub`, so fontTools was used instead;
  a web page loading the font as a web font avoided font cache trouble while testing.
- Variants: underline alternating groups of three, skip numbers under four digits, group
  decimals left to right, insert visual commas, or squash groups together in monospace.
- Used with injected CSS in Jupyter (right-aligned pandas tables) and in the Kitty terminal;
  Emacs and Sublime Text could not use it.
- Broader lesson: knowing roughly what every layer of a system can do lets you put a fix in
  the right place.

## Relevance to us

- We read many nanosecond values (`recv_ts`, `exch_ts`, latencies), but this is a personal
  display tweak, not a change to any repo; Core's `Int.to_string_hum` covers digit grouping
  wherever we need it in output. **Action:** none.

Tags: `ui`, `research-tooling`
