# When Bash Scripts Bite

- Source: <https://blog.janestreet.com/when-bash-scripts-bite/>
- Published: 2017-05-11
- Kind: blog post

## Summary

- A production bash script that publishes the list of valid users to Jane Street's inbound
  mail servers failed silently and pushed an empty list, despite `set -euo pipefail`.
- Cause: `set -e` only reacts to the exit status of simple commands. When a command
  substitution sits inside `echo`, `local` or `export`, the builtin's zero status wins and
  the inner failure is ignored.
- With several substitutions in one assignment, only the last one's status counts.
- Without `--posix`, `set -e` is not inherited by subshells running command substitutions,
  so a function invoked through one keeps going after a failure.
- Takeaway: keep the strict flags but do not trust them; reason about every failure path,
  and prefer a real language for production scripts.

## Relevance to us

- Our e2e and build scripts all use `set -euo pipefail` and many command substitutions.
  `market-recorder/scripts/e2e-sims.sh` loops over `$(find ... | head -3)` on raw minute
  files and only prints them, so a run that wrote no raw files still exits 0
  ([market-recorder](../../../repos/market-recorder.md)).
- **Action:** make `market-recorder/scripts/e2e-sims.sh` count `*.zst` files under
  `data/raw` into a variable on its own line and exit non-zero when the count is zero.

Tags: `ops`, `testing`
