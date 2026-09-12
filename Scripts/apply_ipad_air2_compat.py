#!/usr/bin/env python3
from pathlib import Path

path = Path("App/Sources/The12DayDancerApp.swift")
text = path.read_text(encoding="utf-8")

replacements = [
    ("NavigationStack {", "NavigationView {", 1),
    ("\n                    .fontDesign(.serif)", "", 1),
    ("\n                        .fontDesign(.serif)", "", 2),
    ("\n                            .fontDesign(.serif)", "", 1),
    ("\n                                    .fontDesign(.serif)", "", 1),
    ("\n                                                .fontDesign(.serif)", "", 1),
]

for old, new, minimum in replacements:
    count = text.count(old)
    if count < minimum:
        raise SystemExit(f"Expected at least {minimum} occurrence(s) of {old!r}, found {count}")
    text = text.replace(old, new)

path.write_text(text, encoding="utf-8")
print("Applied iPad Air 2 / iPadOS 15 SwiftUI compatibility patch.")
