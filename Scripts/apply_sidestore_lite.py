#!/usr/bin/env python3
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "App" / "Sources" / "The12DayDancerApp.swift"
text = path.read_text(encoding="utf-8")

marker = "SIDESTORE-LITE-RESOURCE-ROOT"
if marker in text:
    print("SideStore Lite resource resolver already applied.")
    raise SystemExit(0)

old = '''private func concertResourceURL(_ name: String) -> URL? {
    guard !name.isEmpty else { return nil }
    let url = Bundle.main.bundleURL
        .appendingPathComponent("ConcertResources", isDirectory: true)
        .appendingPathComponent(name, isDirectory: false)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
}
'''

new = '''// SIDESTORE-LITE-RESOURCE-ROOT
// The SideStore build keeps the signed app small. The full concert library lives in
// Documents/ConcertResources and survives ordinary re-sign/refresh cycles. A bundled
// fallback remains for tiny bootstrap resources such as the ballerina facade.
private func externalConcertResourcesDirectory() -> URL? {
    let manager = FileManager.default
    guard let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    let directory = documents.appendingPathComponent("ConcertResources", isDirectory: true)
    try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

private func concertResourceURL(_ name: String) -> URL? {
    guard !name.isEmpty else { return nil }
    let manager = FileManager.default

    if let directory = externalConcertResourcesDirectory() {
        let externalURL = directory.appendingPathComponent(name, isDirectory: false)
        if manager.fileExists(atPath: externalURL.path) {
            return externalURL
        }
    }

    let bundledURL = Bundle.main.bundleURL
        .appendingPathComponent("ConcertResources", isDirectory: true)
        .appendingPathComponent(name, isDirectory: false)
    return manager.fileExists(atPath: bundledURL.path) ? bundledURL : nil
}
'''

if old not in text:
    raise SystemExit("Expected V5 concertResourceURL block not found; refusing to patch.")

path.write_text(text.replace(old, new, 1), encoding="utf-8")
print("Applied SideStore Lite external-first resource resolver.")
