#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "App" / "Sources" / "iPhone12ProMaxUI.swift"

text = SOURCE.read_text(encoding="utf-8")
marker = "IPHONE12-PORTRAIT-FACADE-OFFSET"

if marker in text:
    print("iPhone 12 Pro Max portrait facade offset already applied.")
    raise SystemExit(0)

old = "                            Spacer(minLength: max(270, proxy.size.height * 0.39))\n"
new = "                            Spacer(minLength: max(270, proxy.size.height * (proxy.size.height >= proxy.size.width ? 0.89 : 0.39))) // IPHONE12-PORTRAIT-FACADE-OFFSET\n"

if old not in text:
    raise SystemExit("Expected iPhone facade spacer not found; refusing to patch.")

SOURCE.write_text(text.replace(old, new, 1), encoding="utf-8")
print("Moved Bulgarian console down by half a screen height in portrait; landscape unchanged.")
