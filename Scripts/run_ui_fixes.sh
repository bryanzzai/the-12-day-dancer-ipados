#!/bin/bash
set -euo pipefail
/usr/bin/python3 "$SRCROOT/Scripts/apply_ui_fixes.py"
/usr/bin/python3 "$SRCROOT/Scripts/simplify_video_ui.py"
/usr/bin/python3 "$SRCROOT/Scripts/apply_ui_fixes_v5.py"
/usr/bin/python3 "$SRCROOT/Scripts/apply_sidestore_lite.py"
/usr/bin/python3 "$SRCROOT/Scripts/apply_iphone12_ui.py"
/usr/bin/python3 "$SRCROOT/Scripts/apply_iphone12_facade_offset.py"
