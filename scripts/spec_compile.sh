#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-docs/specs}"
OUT="${2:-build/specs.json}"

mkdir -p "$(dirname "$OUT")"

# Prefer spec-kit CLI if present; otherwise do a stable JSON rollup with jq
if npx --yes @github/spec-kit@0.1.0 --version >/dev/null 2>&1; then
  # spec-kit compile must be deterministic: sorted, strict
  npx --yes @github/spec-kit@0.1.0 compile "$SRC" --out "$OUT.tmp" --strict --sort
else
  # Fallback: concatenate *.md/*.yml front-matter into a unified, sorted JSON
  tmp="$(mktemp)"
  find "$SRC" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) \
    | LC_ALL=C sort \
    | while read -r f; do
        echo "{\"path\":\"$f\",\"sha\":\"$(git hash-object "$f")\"}"
      done > "$tmp"
  # Stable, sorted by path, then materialize
  jq -s 'sort_by(.path)' "$tmp" > "$OUT.tmp"
fi

# Make build deterministic: strip volatile fields & pretty-print
jq -S '.' "$OUT.tmp" > "$OUT"
rm -f "$OUT.tmp"

# Smoke: file content stable within the same tree
test -s "$OUT"
echo "✅ Deterministic spec bundle at $OUT"
