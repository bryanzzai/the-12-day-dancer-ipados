#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "App" / "Sources" / "The12DayDancerApp.swift"

text = SOURCE.read_text(encoding="utf-8")
marker = "IPHONE12-PRO-MAX-ROOT"

if marker in text:
    print("iPhone 12 Pro Max root view already applied.")
    raise SystemExit(0)

old = '''        WindowGroup {
            ContentView()
        }
'''
new = '''        WindowGroup {
            // IPHONE12-PRO-MAX-ROOT
            iPhone12ProMaxRootView()
        }
'''

if old not in text:
    raise SystemExit("Expected native app root not found; refusing to patch iPhone branch.")

SOURCE.write_text(text.replace(old, new, 1), encoding="utf-8")
print("Applied dedicated iPhone 12 Pro Max root view.")
