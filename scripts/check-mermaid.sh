#!/usr/bin/env bash
# Render every Mermaid block in the repository; a syntax error fails the run.
set -euo pipefail
cd "$(dirname "$0")/.."
out=$(mktemp -d)
config="$out/puppeteer.json"
echo '{"args": ["--no-sandbox"]}' > "$config"
status=0
while IFS= read -r file; do
  echo "checking $file"
  mkdir -p "$out/$(dirname "$file")"
  if ! npx -y @mermaid-js/mermaid-cli@11.4.2 -q -p "$config" -i "$file" \
      -o "$out/$file" >"$out/log" 2>&1; then
    cat "$out/log"
    status=1
  fi
done < <(grep -rl --include='*.md' '^```mermaid' . | sort)
rm -rf "$out"
exit $status
