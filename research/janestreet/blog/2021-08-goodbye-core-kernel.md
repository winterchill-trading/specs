# Goodbye Core_kernel

- Source: <https://blog.janestreet.com/goodbye-Core_kernel/>
- Published: 2021-08-26
- Kind: blog post

## Summary

- Jane Street collapsed its three-tier standard library (Base, Core_kernel, Core) into two by
  moving the Unix-dependent pieces of Core into standalone libraries and renaming
  Core_kernel to Core.
- Motivation: a simpler story and better portability, since the old Unix-bound Core kept many
  libraries from running under JavaScript or on Windows.
- Base is positioned as the light, fast-compiling, more stable layer; Core as the richer one
  with bin_prot and Base_quickcheck integrated throughout. Both are now portable.
- Migration recipe: swap Core_kernel for Core, build with deprecation alerts as errors, and
  follow the `@@deprecated` hints that point at the new homes.
- Moved modules include `Command_unix`, `Core_unix`, `Time_unix`, `Time_ns_unix`,
  `Date_unix`, `Filename_unix`, `Signal_unix`, `Sys_unix` and `Core_thread`.
- The change was not backward compatible, so the opam release needed a separate
  transition plan.

## Relevance to us

- **OCaml practice:** the Unix-dependent parts of Core live in separate libraries
  (`Command_unix`, `Core_unix`, `Time_ns_unix` and so on), and agents keep reaching for the
  old `Core.Unix` or `Command.run` names. **Action:** add a gotchas-log entry in
  [oxcaml-claude-skills](../../../repos/oxcaml-claude-skills.md) listing the `Core.X` to
  `X_unix` renames and the matching dune library names.
- **Build and deploy:** keeping portable code on plain `Core` and Unix code at the edge is
  what lets libraries compile without Unix. **Action:** none; our pure libraries
  ([fixed-decimal](../../../repos/fixed-decimal.md),
  [exchange-core](../../../repos/exchange-core.md), [mm-core](../../../repos/mm-core.md))
  already avoid `core_unix`, and nothing targets JavaScript.

Tags: `ocaml-practice`, `build`
