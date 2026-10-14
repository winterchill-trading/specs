# Scripts (AGENTS.md)

`check-mermaid.sh`: renders every fenced `mermaid` block in the repository with a pinned mermaid-cli
through `npx`. A block that fails to render fails the script and the CI `mermaid` job.

- Run it from the repository root: `scripts/check-mermaid.sh`. It needs Node and network access on the
  first run.
- Keep the pinned version in step with the CI workflow when either changes.
- The script writes to a temporary directory it removes itself. Do not add a script that writes into the repository.
