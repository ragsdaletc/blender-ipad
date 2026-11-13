#!/usr/bin/env bash
# Turn a built Blender.app into an .ipa for sideloading.
# Usage: package_ipa.sh <Blender.app> <blender source> <output dir> [site-packages to leave out...]
set -euo pipefail

APP_IN=$1
SRC=$2
mkdir -p "$3"
OUT=$(cd "$3" && pwd)
shift 3

WORK=$(mktemp -d)
cp -R "$APP_IN" "$WORK/Blender.app"
APP="$WORK/Blender.app"

# Python packages whose native modules can't be packaged yet (see README).
for pkg in "$@"; do
  for path in "$APP"/Assets/*/python/lib/python3.*/site-packages/"$pkg" \
              "$APP"/Assets/*/python/lib/python3.*/site-packages/"$pkg"-*.dist-info; do
    if [ -e "$path" ]; then
      echo "Leaving out $path"
      rm -rf "$path"
    fi
  done
done

# Turns native libraries into frameworks and fixes Python's layout for iOS.
mkdir -p "$WORK/stage/Payload" "$WORK/replacements"
python3 "$SRC/release/ios/prepare_testflight.py" "$APP" "$WORK/stage/Payload/Blender.app" \
  --replacement-directory "$WORK/replacements"

(cd "$WORK/stage" && zip -qry "$OUT/Blender-iPad.ipa" Payload)
ls -lh "$OUT"
