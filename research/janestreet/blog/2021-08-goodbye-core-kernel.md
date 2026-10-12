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

- Every OCaml repo opens `Core`; binaries such as [market-maker](../../../repos/market-maker.md),
  [market-recorder](../../../repos/market-recorder.md) and the simulators need the `*_unix`
  libraries (`Command_unix.run`, `Core_unix`) on top of it.
- This is background for the split we already live with, not a new technique.
- **Action:** add a short entry to the `oxcaml-claude-skills` gotchas log listing the
  `Core.X` to `X_unix` renames, so agents stop reaching for `Core.Unix` or `Command.run`.

Tags: `ocaml-practice`, `build`
