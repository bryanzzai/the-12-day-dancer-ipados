#!/bin/bash
set -euo pipefail
/usr/bin/python3 "$SRCROOT/Scripts/apply_ui_fixes.py"
/usr/bin/python3 "$SRCROOT/Scripts/simplify_video_ui.py"
