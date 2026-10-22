#!/bin/bash
# Тест sync-site.sh на копии site/ и фиктивном DMG.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cp -R "$ROOT/site" "$TMP/site"
dd if=/dev/zero of="$TMP/Siply-9.9.9.dmg" bs=1048576 count=2 2>/dev/null
export SITE_DIR="$TMP/site"

fail() { echo "FAIL: $1" >&2; exit 1; }

"$ROOT/scripts/sync-site.sh" "$TMP/Siply-9.9.9.dmg" >/dev/null
HREF='releases/download/v9.9.9/Siply-9.9.9.dmg'
grep -q "id=\"download\"[^>]*$HREF\"" "$SITE_DIR/index.html" || fail "href ru"
grep -q "id=\"download\"[^>]*$HREF\"" "$SITE_DIR/en/index.html" || fail "href en"
grep -q '>Версия 9.9.9 · 2,0 МБ<' "$SITE_DIR/index.html" || fail "строка ru"
grep -q '>Version 9.9.9 · 2.0 MB<' "$SITE_DIR/en/index.html" || fail "строка en"

# Идемпотентность
cp -R "$SITE_DIR" "$TMP/after1"
"$ROOT/scripts/sync-site.sh" "$TMP/Siply-9.9.9.dmg" >/dev/null
diff -r "$TMP/after1" "$SITE_DIR" >/dev/null || fail "не идемпотентно"

# Неверное имя
cp "$TMP/Siply-9.9.9.dmg" "$TMP/foo.dmg"
if "$ROOT/scripts/sync-site.sh" "$TMP/foo.dmg" 2>/dev/null; then fail "foo.dmg принят"; fi

echo OK
