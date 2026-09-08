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

DEST="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/ConcertResources"
CACHE_ROOT="${HOME}/Library/Caches/The12DayDancer/${SOURCE_COMMIT}"
mkdir -p "$DEST" "$CACHE_ROOT"

TOTAL=$(grep -v '^#' "$MANIFEST" | grep -c $'\t' || true)
INDEX=0
AUDIO_EXPECTED=229
VIDEO_EXPECTED=9

copy_fast() {
  local source="$1"
  local target="$2"
  rm -f "$target"
  if cp -c "$source" "$target" 2>/dev/null; then
    return 0
  fi
  cp "$source" "$target"
}

while IFS=$'\t' read -r KIND ALBUM BUNDLE_NAME URL SOURCE_PATH; do
  [[ -z "${KIND:-}" ]] && continue
  [[ "$KIND" == \#* ]] && continue
  INDEX=$((INDEX + 1))
  TARGET="$DEST/$BUNDLE_NAME"

  if [[ -n "${THE12_PRESTAGED_RESOURCES:-}" ]]; then
    SOURCE="${THE12_PRESTAGED_RESOURCES}/$BUNDLE_NAME"
    if [[ ! -s "$SOURCE" ]]; then
      echo "Missing CI prestaged resource: $SOURCE" >&2
      exit 1
    fi
    echo "[$INDEX/$TOTAL] staging $KIND · $ALBUM · $BUNDLE_NAME"
    copy_fast "$SOURCE" "$TARGET"
    continue
  fi

  CACHE_FILE="$CACHE_ROOT/$BUNDLE_NAME"
  if [[ ! -s "$CACHE_FILE" ]]; then
    TMP="${CACHE_FILE}.download"
    rm -f "$TMP"
    echo "[$INDEX/$TOTAL] downloading $KIND · $ALBUM · $BUNDLE_NAME"
    /usr/bin/curl \
      --location \
      --fail \
      --silent \
      --show-error \
      --retry 4 \
      --retry-delay 2 \
      --connect-timeout 30 \
      --output "$TMP" \
      "$URL"
    if [[ ! -s "$TMP" ]]; then
      echo "Downloaded resource is empty: $URL" >&2
      exit 1
    fi
    mv "$TMP" "$CACHE_FILE"
  else
    echo "[$INDEX/$TOTAL] cached $KIND · $ALBUM · $BUNDLE_NAME"
  fi
  copy_fast "$CACHE_FILE" "$TARGET"
done < "$MANIFEST"

AUDIO_COUNT=$(find "$DEST" -maxdepth 1 -type f -name '*__audio__*.web.m4a' | wc -l | tr -d ' ')
VIDEO_COUNT=$(find "$DEST" -maxdepth 1 -type f -name '*__video__*.mp4' | wc -l | tr -d ' ')
ORIGINAL_COUNT=$(find "$DEST" -maxdepth 1 -type f -name '*.m4a' ! -name '*.web.m4a' | wc -l | tr -d ' ')
RESOURCE_COUNT=$(find "$DEST" -maxdepth 1 -type f | wc -l | tr -d ' ')

if [[ "$AUDIO_COUNT" != "$AUDIO_EXPECTED" ]]; then
  echo "Native bundle audio count is $AUDIO_COUNT; expected $AUDIO_EXPECTED." >&2
  exit 1
fi
if [[ "$VIDEO_COUNT" != "$VIDEO_EXPECTED" ]]; then
  echo "Native bundle video count is $VIDEO_COUNT; expected $VIDEO_EXPECTED." >&2
  exit 1
fi
if [[ "$ORIGINAL_COUNT" != "0" ]]; then
  echo "Original/non-web M4A slipped into native bundle: $ORIGINAL_COUNT" >&2
  exit 1
fi

printf '%s\n' "$SOURCE_COMMIT" > "$DEST/SOURCE-SITE-COMMIT.txt"
echo "Full local concert resources staged: $RESOURCE_COUNT files + source marker; $AUDIO_COUNT web M4A + $VIDEO_COUNT MP4; 0 original M4A."
