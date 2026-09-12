#!/usr/bin/env python3
from pathlib import Path

source = Path("App/Sources/The12DayDancerApp.swift")
text = source.read_text(encoding="utf-8")

marker = "ConcertImportHost { ContentView() }"
if marker in text:
    print("iPad Pro 12.9 import host already applied.")
    raise SystemExit(0)

needle = "        WindowGroup {\n            ContentView()\n        }"
replacement = "        WindowGroup {\n            ConcertImportHost { ContentView() }\n        }"

if needle not in text:
    raise SystemExit("Could not locate WindowGroup ContentView root; refusing to patch.")

source.write_text(text.replace(needle, replacement, 1), encoding="utf-8")
print("Applied iPad Pro 12.9 ConcertResources import host.")
