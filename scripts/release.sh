#!/bin/bash
# Собирает Release, подписывает Developer ID, нотаризует и степлит.
# Запуск из корня: scripts/release.sh
# Нотаризация — ключом App Store Connect API, как в LangFlip: профиль notarytool в
# keychain теряется при блокировке экрана, .p8 на диске — нет. Креды аккаунта лежат вне репо:
#   NOTARY_KEY=$HOME/private_keys/AuthKey_XXXXXXXXXX.p8
#   NOTARY_KEY_ID=XXXXXXXXXX
#   NOTARY_ISSUER=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
set -euo pipefail

IDENTITY="Developer ID Application: Artem Pisarev (2C2N587UW8)"
OUT=build/release
APP="$OUT/Build/Products/Release/Siply.app"

xcodegen generate >/dev/null
rm -rf "$OUT"
xcodebuild build -scheme Siply -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "$OUT" \
  CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM=2C2N587UW8 \
  ENABLE_HARDENED_RUNTIME=YES OTHER_CODE_SIGN_FLAGS=--timestamp CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  | grep -E "error:|BUILD (SUCCEEDED|FAILED)"

codesign --verify --strict --deep "$APP"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
DMG="$OUT/Siply-$VERSION.dmg"

NOTARY_ENV="${NOTARY_ENV:-$HOME/.config/langflip/notary.env}"   # ponytail: общий с LangFlip, ключ аккаунта
# shellcheck source=/dev/null
[ -f "$NOTARY_ENV" ] && source "$NOTARY_ENV"
if [ -z "${NOTARY_KEY:-}" ] || [ -z "${NOTARY_KEY_ID:-}" ] || [ -z "${NOTARY_ISSUER:-}" ] || [ ! -f "$NOTARY_KEY" ]; then
  echo "нет ключа App Store Connect API в $NOTARY_ENV — сборка подписана, нотаризация пропущена" >&2
  exit 1
fi

# DMG: приложение + ссылка на «Программы» для перетаскивания
STAGE="$OUT/dmg"
mkdir -p "$STAGE" && cp -R "$APP" "$STAGE/" && ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Siply" -srcfolder "$STAGE" -format UDZO -ov "$DMG" >/dev/null
codesign --sign "$IDENTITY" --timestamp "$DMG"

RESULT=$(xcrun notarytool submit "$DMG" --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" \
  --issuer "$NOTARY_ISSUER" --wait --output-format json)
STATUS=$(plutil -extract status raw -o - - <<<"$RESULT")
if [ "$STATUS" != "Accepted" ]; then
  echo "нотаризация: $STATUS, лог: xcrun notarytool log $(plutil -extract id raw -o - - <<<"$RESULT") --key …" >&2
  exit 1
fi
xcrun stapler staple "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG"
echo "$DMG"
