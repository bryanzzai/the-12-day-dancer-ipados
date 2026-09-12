#!/usr/bin/env python3
from pathlib import Path
import re

source_root = Path("App/Sources")
files = sorted(source_root.glob("*.swift"))
if not files:
    raise SystemExit("No Swift source files found")

nav_count = 0
font_design_count = 0
letter_spacing_count = 0

for path in files:
    text = path.read_text(encoding="utf-8")

    nav_here = text.count("NavigationStack {")
    if nav_here:
        text = text.replace("NavigationStack {", "NavigationView {")
        nav_count += nav_here

    font_here = text.count(".fontDesign(.serif)")
    if font_here:
        text = text.replace(".fontDesign(.serif)", "")
        font_design_count += font_here

    # The current SwiftUI SDK gates both tracking() and kerning() used here
    # above our iPadOS 15 target. Letter spacing is cosmetic, so drop it.
    text, tracking_here = re.subn(r"\s*\.tracking\([^\n()]*\)", "", text)
    text, kerning_here = re.subn(r"\s*\.kerning\([^\n()]*\)", "", text)
    letter_spacing_count += tracking_here + kerning_here

    path.write_text(text, encoding="utf-8")

print(
    "Applied iPad Air 2 / iPadOS 15 compatibility patch across Swift sources: "
    f"NavigationStack={nav_count}, fontDesign={font_design_count}, letterSpacing={letter_spacing_count}."
)
