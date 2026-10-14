#!/bin/bash
# Собирает Release, подписывает Developer ID, нотаризует и степлит.
# Запуск из корня: NOTARY_PROFILE=<профиль notarytool> scripts/release.sh
# Профиль создаётся один раз: xcrun notarytool store-credentials <профиль> --apple-id … --team-id 2C2N587UW8
set -euo pipefail

IDENTITY="Developer ID Application: Artem Pisarev (2C2N587UW8)"
OUT=build/release
APP="$OUT/Build/Products/Release/Siply.app"

xcodegen generate >/dev/null
rm -rf "$OUT"
xcodebuild build -scheme Siply -configuration Release -destination 'generic/platform=macOS' \
  -derivedDataPath "$OUT" \
  CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM=2C2N587UW8 \
  ENABLE_HARDENED_RUNTIME=YES OTHER_CODE_SIGN_FLAGS=--timestamp \
  | grep -E "error:|BUILD (SUCCEEDED|FAILED)"

codesign --verify --strict --deep "$APP"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
ZIP="$OUT/Siply-$VERSION.zip"

if [ -z "${NOTARY_PROFILE:-}" ]; then
  echo "NOTARY_PROFILE не задан — сборка подписана, нотаризация пропущена" >&2
  exit 1
fi

ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
rm "$ZIP" && ditto -c -k --keepParent "$APP" "$ZIP"
spctl --assess --type execute -v "$APP"
echo "$ZIP"
