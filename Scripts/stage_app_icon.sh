#!/bin/bash
set -euo pipefail

DEST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/ConcertResources"
ICON_SOURCE="$DEST/facade__background__bulgarian-ballerina.png"
APP_BUNDLE="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [[ ! -s "$ICON_SOURCE" ]]; then
  echo "Ballerina app icon source missing: $ICON_SOURCE" >&2
  exit 1
fi
if [[ ! -f "$PLIST" ]]; then
  echo "Built Info.plist missing: $PLIST" >&2
  exit 1
fi

make_icon() {
  local size="$1"
  local name="$2"
  /usr/bin/sips -s format png -z "$size" "$size" "$ICON_SOURCE" --out "$APP_BUNDLE/$name" >/dev/null
}

make_icon 20   "Icon-20.png"
make_icon 40   "Icon-20@2x.png"
make_icon 29   "Icon-29.png"
make_icon 58   "Icon-29@2x.png"
make_icon 40   "Icon-40.png"
make_icon 80   "Icon-40@2x.png"
make_icon 76   "Icon-76.png"
make_icon 152  "Icon-76@2x.png"
make_icon 84   "Icon-83.5.png"
make_icon 167  "Icon-83.5@2x.png"

PB=/usr/libexec/PlistBuddy
"$PB" -c "Delete :CFBundleIconFiles" "$PLIST" >/dev/null 2>&1 || true
"$PB" -c "Add :CFBundleIconFiles array" "$PLIST"
i=0
for icon in Icon-20 Icon-29 Icon-40 Icon-76 Icon-83.5; do
  "$PB" -c "Add :CFBundleIconFiles:$i string $icon" "$PLIST"
  i=$((i + 1))
done

"$PB" -c "Delete :CFBundleIcons~ipad" "$PLIST" >/dev/null 2>&1 || true
"$PB" -c "Add :CFBundleIcons~ipad dict" "$PLIST"
"$PB" -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon dict" "$PLIST"
"$PB" -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles array" "$PLIST"
i=0
for icon in Icon-20 Icon-29 Icon-40 Icon-76 Icon-83.5; do
  "$PB" -c "Add :CFBundleIcons~ipad:CFBundlePrimaryIcon:CFBundleIconFiles:$i string $icon" "$PLIST"
  i=$((i + 1))
done

echo "Ballerina app icon staged from the exact pinned landing-page artwork."
