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

# Версия X.Y
dd if=/dev/zero of="$TMP/Siply-9.9.dmg" bs=1048576 count=2 2>/dev/null
"$ROOT/scripts/sync-site.sh" "$TMP/Siply-9.9.dmg" >/dev/null
grep -q 'releases/download/v9.9/Siply-9.9.dmg"' "$SITE_DIR/index.html" || fail "href X.Y"
grep -q '>Версия 9.9 · 2,0 МБ<' "$SITE_DIR/index.html" || fail "строка X.Y"
"$ROOT/scripts/sync-site.sh" "$TMP/Siply-9.9.9.dmg" >/dev/null

# Идемпотентность
cp -R "$SITE_DIR" "$TMP/after1"
"$ROOT/scripts/sync-site.sh" "$TMP/Siply-9.9.9.dmg" >/dev/null
diff -r "$TMP/after1" "$SITE_DIR" >/dev/null || fail "не идемпотентно"

# Неверное имя
cp "$TMP/Siply-9.9.9.dmg" "$TMP/foo.dmg"
if "$ROOT/scripts/sync-site.sh" "$TMP/foo.dmg" 2>/dev/null; then fail "foo.dmg принят"; fi

# Шаблон не совпал (нет #release / #download) -> ненулевой код
for id in release download; do
  for page in index.html en/index.html; do
    rm -rf "$TMP/neg"; cp -R "$ROOT/site" "$TMP/neg"
    sed -i '' "s/id=\"$id\"/id=\"x$id\"/" "$TMP/neg/$page"
    if SITE_DIR="$TMP/neg" "$ROOT/scripts/sync-site.sh" "$TMP/Siply-9.9.9.dmg" 2>/dev/null; then
      fail "не упал без id=$id в $page"
    fi
  done
done

# Идемпотентность на нетронутом site/ с DMG того же размера, что настоящий
REAL="$ROOT/build/release/Siply-1.2.1.dmg"
if [ -f "$REAL" ]; then
  head -c "$(stat -f%z "$REAL")" /dev/zero > "$TMP/Siply-1.2.1.dmg"
  rm -rf "$TMP/real"; cp -R "$ROOT/site" "$TMP/real"
  SITE_DIR="$TMP/real" "$ROOT/scripts/sync-site.sh" "$TMP/Siply-1.2.1.dmg" >/dev/null
  diff -r "$ROOT/site" "$TMP/real" >/dev/null || fail "реальный site/ изменился"
fi

echo OK
