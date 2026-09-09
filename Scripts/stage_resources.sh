#!/bin/bash
set -euo pipefail

MANIFEST="${SRCROOT}/App/Generated/ResourceManifest.tsv"
if [[ ! -f "$MANIFEST" ]]; then
  echo "Missing generated resource manifest: $MANIFEST" >&2
  exit 1
fi

SOURCE_COMMIT=$(awk -F '\t' '$1 == "# source-commit" {print $2; exit}' "$MANIFEST")
if [[ -z "$SOURCE_COMMIT" ]]; then
  echo "Resource manifest has no source commit." >&2
  exit 1
fi

BOOTSTRAP_NAME="facade__background__bulgarian-ballerina.png"
BOOTSTRAP_URL=$(awk -F '\t' -v name="$BOOTSTRAP_NAME" '$3 == name {print $4; exit}' "$MANIFEST")
if [[ -z "$BOOTSTRAP_URL" ]]; then
  echo "Bootstrap facade not found in resource manifest: $BOOTSTRAP_NAME" >&2
  exit 1
fi

DEST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/ConcertResources"
CACHE_ROOT="${HOME}/Library/Caches/The12DayDancer/${SOURCE_COMMIT}"
CACHE_FILE="$CACHE_ROOT/$BOOTSTRAP_NAME"
mkdir -p "$CACHE_ROOT"

# SideStore Lite must never inherit a previous full-resource build from DerivedData.
rm -rf "$DEST"
mkdir -p "$DEST"

if [[ -n "${THE12_PRESTAGED_RESOURCES:-}" ]]; then
  SOURCE="${THE12_PRESTAGED_RESOURCES}/$BOOTSTRAP_NAME"
  if [[ ! -s "$SOURCE" ]]; then
    echo "Missing CI prestaged bootstrap resource: $SOURCE" >&2
    exit 1
  fi
  cp "$SOURCE" "$DEST/$BOOTSTRAP_NAME"
else
  if [[ ! -s "$CACHE_FILE" ]]; then
    TMP="${CACHE_FILE}.download"
    rm -f "$TMP"
    echo "Downloading SideStore Lite bootstrap facade"
    /usr/bin/curl \
      --location \
      --fail \
      --silent \
      --show-error \
      --retry 4 \
      --retry-delay 2 \
      --connect-timeout 30 \
      --output "$TMP" \
      "$BOOTSTRAP_URL"
    test -s "$TMP"
    mv "$TMP" "$CACHE_FILE"
  else
    echo "Using cached SideStore Lite bootstrap facade"
  fi
  cp "$CACHE_FILE" "$DEST/$BOOTSTRAP_NAME"
fi

printf '%s\n' "$SOURCE_COMMIT" > "$DEST/SOURCE-SITE-COMMIT.txt"

audio_count=$(find "$DEST" -maxdepth 1 -type f -name '*.m4a' | wc -l | tr -d ' ')
video_count=$(find "$DEST" -maxdepth 1 -type f -name '*.mp4' | wc -l | tr -d ' ')
file_count=$(find "$DEST" -maxdepth 1 -type f | wc -l | tr -d ' ')

if [[ "$audio_count" != "0" || "$video_count" != "0" ]]; then
  echo "SideStore Lite accidentally staged media: audio=$audio_count video=$video_count" >&2
  exit 1
fi
if [[ "$file_count" != "2" ]]; then
  echo "SideStore Lite bootstrap should contain exactly facade + source marker; found $file_count files." >&2
  exit 1
fi

echo "SideStore Lite bootstrap staged: ballerina facade + source marker; 0 audio; 0 video."
