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
stack_style_count = 0
host_wrap_count = 0

for path in files:
    text = path.read_text(encoding="utf-8")

    nav_here = text.count("NavigationStack {")
    if nav_here:
        text = text.replace("NavigationStack {", "NavigationView {")
        nav_count += nav_here

    # On iPadOS 15, NavigationView defaults to split/sidebar navigation on iPad.
    # The Dancer facade is a full-screen composition, so force single-column stack
    # navigation to match the other editions.
    if path.name == "The12DayDancerApp.swift" and ".navigationViewStyle(StackNavigationViewStyle())" not in text:
        needle = "            .preferredColorScheme(.dark)\n        }\n    }\n\n    private var mast"
        replacement = "            .preferredColorScheme(.dark)\n        }\n        .navigationViewStyle(StackNavigationViewStyle())\n    }\n\n    private var mast"
        if needle not in text:
            raise SystemExit("Could not locate ContentView NavigationView closing block for Air 2 stack-style patch")
        text = text.replace(needle, replacement, 1)
        stack_style_count += 1

    # Wrap the root content in a dedicated Air 2 import host. Keeping the importer
    # in its own Swift file prevents the normal native-UI refinement phase from
    # rewriting it away. This replacement is idempotent and safe to run both
    # before and during the Xcode build.
    if path.name == "The12DayDancerApp.swift" and "Air2ConcertImportHost {" not in text:
        app_needle = "        WindowGroup {\n            ContentView()\n        }"
        app_replacement = "        WindowGroup {\n            Air2ConcertImportHost { ContentView() }\n        }"
        if app_needle not in text:
            raise SystemExit("Could not locate WindowGroup ContentView root for Air 2 import host")
        text = text.replace(app_needle, app_replacement, 1)
        host_wrap_count += 1

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
    f"NavigationStack={nav_count}, stackStyle={stack_style_count}, hostWrap={host_wrap_count}, "
    f"fontDesign={font_design_count}, letterSpacing={letter_spacing_count}."
)
