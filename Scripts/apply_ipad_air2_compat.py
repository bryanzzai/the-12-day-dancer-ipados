#!/usr/bin/env python3
from pathlib import Path

path = Path("App/Sources/The12DayDancerApp.swift")
text = path.read_text(encoding="utf-8")

nav_count = text.count("NavigationStack {")
if nav_count != 1:
    raise SystemExit(f"Expected exactly one NavigationStack, found {nav_count}")
text = text.replace("NavigationStack {", "NavigationView {")

font_design_count = text.count(".fontDesign(.serif)")
if font_design_count < 1:
    raise SystemExit("Expected at least one .fontDesign(.serif) occurrence")
text = text.replace(".fontDesign(.serif)", "")

path.write_text(text, encoding="utf-8")
print(f"Applied iPad Air 2 / iPadOS 15 compatibility patch: NavigationStack->NavigationView; removed {font_design_count} fontDesign calls.")
