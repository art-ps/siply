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
    grep -oE 'href="[^"]*releases/download/[^"]*"' "$f"
    grep -E 'id="release"' "$f" | sed -E 's/^ +//'
  done
  exit 0
fi

DMG="$1"
NAME="$(basename "$DMG")"
if ! [[ "$NAME" =~ ^Siply-([0-9]+\.[0-9]+\.[0-9]+)\.dmg$ ]]; then
  echo "Ошибка: имя файла должно быть Siply-X.Y.Z.dmg, получено: $NAME" >&2
  exit 1
fi
[ -f "$DMG" ] || { echo "Ошибка: нет файла $DMG" >&2; exit 1; }
VER="${BASH_REMATCH[1]}"

# Размер в МБ (bytes/1048576), один знак после запятой
SIZE_EN="$(stat -f%z "$DMG" | awk '{printf "%.1f", $1 / 1048576}')"
SIZE_RU="${SIZE_EN/./,}"

HREF="https://github.com/art-ps/siply/releases/download/v$VER/$NAME"

# BSD sed (macOS)
sed -E -i '' \
  -e "s#(id=\"download\"[^>]*href=\")[^\"]*(\")#\1$HREF\2#" \
  -e "s#(id=\"release\">)[^<]*(<)#\1Версия $VER · $SIZE_RU МБ\2#" "$RU"
sed -E -i '' \
  -e "s#(id=\"download\"[^>]*href=\")[^\"]*(\")#\1$HREF\2#" \
  -e "s#(id=\"release\">)[^<]*(<)#\1Version $VER · $SIZE_EN MB\2#" "$EN"

echo "Сайт: v$VER, ${SIZE_RU} МБ"
