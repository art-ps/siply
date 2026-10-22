#!/bin/bash
# Вписывает в HTML сайта ссылку на DMG и строку «Версия X.Y.Z · N МБ».
# Использование: scripts/sync-site.sh [path/to/Siply-X.Y.Z.dmg]
# Без аргумента — печатает, что сейчас на сайте.
# Вызывать после release.sh, до коммита версии.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE_DIR="${SITE_DIR:-$ROOT/site}"
RU="$SITE_DIR/index.html"
EN="$SITE_DIR/en/index.html"

if [ $# -eq 0 ]; then
  for f in "$RU" "$EN"; do
    echo "$f"
    grep -oE 'href="[^"]*releases/download/[^"]*"' "$f" || echo "(не найдено)"
    grep -E 'id="release"' "$f" | sed -E 's/^ +//' || true
    grep -qE 'id="release"' "$f" || echo "(не найдено)"
  done
  exit 0
fi

DMG="$1"
NAME="$(basename "$DMG")"
if ! [[ "$NAME" =~ ^Siply-([0-9]+(\.[0-9]+){1,2})\.dmg$ ]]; then
  echo "Ошибка: имя файла должно быть Siply-X.Y[.Z].dmg, получено: $NAME" >&2
  exit 1
fi
[ -f "$DMG" ] || { echo "Ошибка: нет файла $DMG" >&2; exit 1; }
VER="${BASH_REMATCH[1]}"

# Размер в МБ (bytes/1048576), один знак после запятой
SIZE_EN="$(stat -f%z "$DMG" | LC_ALL=C awk '{printf "%.1f", $1 / 1048576}')"
SIZE_RU="${SIZE_EN/./,}"

HREF="https://github.com/art-ps/siply/releases/download/v$VER/$NAME"

# Ровно по одному #download и #release в каждой странице
for f in "$RU" "$EN"; do
  for id in download release; do
    [ "$(grep -c "id=\"$id\"" "$f")" -eq 1 ] || { echo "Ошибка: шаблон не совпал в $f" >&2; exit 1; }
  done
done

TEXT_RU="Версия $VER · $SIZE_RU МБ"
TEXT_EN="Version $VER · $SIZE_EN MB"

# BSD sed (macOS)
sed -E -i '' \
  -e "s#(id=\"download\"[^>]*href=\")[^\"]*(\")#\1$HREF\2#" \
  -e "s#(id=\"release\">)[^<]*(<)#\1$TEXT_RU\2#" "$RU"
sed -E -i '' \
  -e "s#(id=\"download\"[^>]*href=\")[^\"]*(\")#\1$HREF\2#" \
  -e "s#(id=\"release\">)[^<]*(<)#\1$TEXT_EN\2#" "$EN"

# sed молча ничего не делает при несовпадении — проверяем результат
for pair in "$RU|$TEXT_RU" "$EN|$TEXT_EN"; do
  f="${pair%%|*}"; t="${pair#*|}"
  if ! grep -qF "href=\"$HREF\"" "$f" || ! grep -qF "id=\"release\">$t<" "$f"; then
    echo "Ошибка: шаблон не совпал в $f" >&2
    exit 1
  fi
done

echo "Сайт: v$VER, ${SIZE_RU} МБ"
