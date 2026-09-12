#!/usr/bin/env python3
from pathlib import Path

source_root = Path("App/Sources")
files = sorted(source_root.glob("*.swift"))
if not files:
    raise SystemExit("No Swift source files found")

nav_count = 0
font_design_count = 0
for path in files:
    text = path.read_text(encoding="utf-8")
    nav_here = text.count("NavigationStack {")
    font_here = text.count(".fontDesign(.serif)")
    if nav_here:
        text = text.replace("NavigationStack {", "NavigationView {")
        nav_count += nav_here
    if font_here:
        text = text.replace(".fontDesign(.serif)", "")
        font_design_count += font_here
    path.write_text(text, encoding="utf-8")

if nav_count < 1:
    raise SystemExit("Expected at least one NavigationStack")
if font_design_count < 1:
    raise SystemExit("Expected at least one .fontDesign(.serif) occurrence")

print(f"Applied iPad Air 2 / iPadOS 15 compatibility patch across Swift sources: replaced {nav_count} NavigationStack(s), removed {font_design_count} fontDesign call(s).")
