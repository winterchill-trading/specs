# CI configuration (AGENTS.md)

`workflows/ci.yml`: two jobs, `lint` (`markdownlint-cli2-action` on `**/*.md`) and `mermaid`
(Node 22, then `scripts/check-mermaid.sh`).

- Both jobs must pass before a documentation change is merged. Run the same commands locally first
  (see the root AGENTS.md).
- The lint configuration lives in `.markdownlint-cli2.jsonc`, not here; change it there.
- Check runs with `gh run list --limit 1`; at most one `gh run watch <id> --exit-status`. No loops.
