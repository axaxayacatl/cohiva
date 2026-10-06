#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-$ROOT_DIR/pwa}"

if [[ ! -d "$TARGET" ]]; then
    echo "Directory not found: $TARGET"
    exit 1
fi

echo "Checking HTML accessibility in: $TARGET"
echo

errors=0

while IFS= read -r -d '' file; do
    # Check HTML documents for a language declaration.
    if grep -qi '<html' "$file" && ! grep -qi '<html[^>]*lang=' "$file"; then
        echo "Missing <html lang=\"...\">: ${file#$ROOT_DIR/}"
        errors=$((errors + 1))
    fi

    # Check images that appear without an alt attribute.
    if grep -qi '<img' "$file"; then
        while IFS= read -r line; do
            if ! grep -qi 'alt=' <<< "$line"; then
                echo "Possible missing alt attribute: ${file#$ROOT_DIR/}"
                errors=$((errors + 1))
                break
            fi
        done < <(grep -i '<img' "$file")
    fi
done < <(find "$TARGET" -type f \( -name '*.html' -o -name '*.htm' \) -print0)

echo
echo "Accessibility issues found: $errors"

if (( errors > 0 )); then
    exit 1
fi

echo "Accessibility check passed."
