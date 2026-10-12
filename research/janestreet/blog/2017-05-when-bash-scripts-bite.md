# When Bash Scripts Bite

- Source: <https://blog.janestreet.com/when-bash-scripts-bite/>
- Published: 2017-05-11
- Kind: blog post

## Summary

- Common advice is to start scripts with `set -euo pipefail`, and popular guides describe
  `-e` as exiting whenever any command fails; the real rules are subtler.
- Incident: a production script that builds the list of valid users and pushes it to the
  inbound mail servers failed silently and deployed an empty list, because the directory
  query inside a command substitution failed without stopping the script.
- `set -e` reacts to the status of simple commands. After expansion, if a command remains,
  its status counts; if none remains, the status of the last command substitution counts.
- So `echo`, `local` and `export` around a failing substitution all succeed, and in an
  assignment with two substitutions only the last one's status matters.
- Without `--posix`, `set -e` is not inherited by subshells running command substitutions:
  a function called through one keeps executing after a failing command (under `sh` or
  `--posix` it stops), yet the script still exits 0 either way.
- Takeaway: keep the strict flags but do not let them give false confidence; reason about
  every failure path like any production code, remember peers will not know these
  subtleties, and prefer a better tool than bash for production work.

## Relevance to us

- **Testing and simulation:** an end-to-end script that only prints its evidence passes
  even when nothing happened; `market-recorder/scripts/e2e-sims.sh` loops over
  `$(find ... | head -3)` raw files and exits 0 if none were written. **Action:** in
  [market-recorder](../../../repos/market-recorder.md), count `*.zst` files under
  `data/raw` in a standalone assignment and exit non-zero when the count is zero.
- **Build and deploy:** the masking cases (`local`/`export` with a substitution) are
  exactly what shellcheck flags, and no repository runs shellcheck in CI. **Action:** add a
  shellcheck step to the CI workflow of [infra](../../../repos/infra.md) covering
  `images/service/build.sh`, then copy it to `market-maker`, `hl-mm` and `market-recorder`
  for their `scripts/*.sh`.

Tags: `ops`, `testing`, `build`
