#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "App" / "Sources" / "The12DayDancerApp.swift"
THUMB = ROOT / "App" / "Sources" / "FilmThumbnailView.swift"

# Main concert-resource resolver -------------------------------------------------
text = SOURCE.read_text(encoding="utf-8")
marker = "SIDESTORE-LITE-RESOURCE-ROOT"

if marker not in text:
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
    SOURCE.write_text(text.replace(old, new, 1), encoding="utf-8")
    print("Applied SideStore Lite external-first resource resolver.")
else:
    print("SideStore Lite main resource resolver already applied.")

# Akita poster-frame resolver ---------------------------------------------------
# This is deliberately patched here, in the LAST pre-build refinement script.
# It prevents any earlier UI-generation step from leaving FilmThumbnailView with
# a Bundle-only MP4 lookup while normal playback uses Documents/ConcertResources.
thumb = THUMB.read_text(encoding="utf-8")
thumb_marker = "SIDESTORE-LITE-THUMBNAIL-RESOURCE-ROOT"

if thumb_marker not in thumb:
    helper = "private func thumbnailResourceURL(_ name: String) -> URL? {"

    # If the source already has the correct Documents-first resolver, stamp it so
    # CI can prove the final pre-build source is the Lite version.
    if "manager.urls(for: .documentDirectory, in: .userDomainMask).first" in thumb:
        if helper not in thumb:
            raise SystemExit("Akita thumbnail helper not found; refusing to patch.")
        thumb = thumb.replace(
            helper,
            "// SIDESTORE-LITE-THUMBNAIL-RESOURCE-ROOT\n" + helper,
            1,
        )
    else:
        old_thumb = '''private func thumbnailResourceURL(_ name: String) -> URL? {
    guard !name.isEmpty else { return nil }
    let url = Bundle.main.bundleURL
        .appendingPathComponent("ConcertResources", isDirectory: true)
        .appendingPathComponent(name, isDirectory: false)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
}
'''
        new_thumb = '''// SIDESTORE-LITE-THUMBNAIL-RESOURCE-ROOT
private func thumbnailResourceURL(_ name: String) -> URL? {
    guard !name.isEmpty else { return nil }
    let manager = FileManager.default

    if let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first {
        let externalURL = documents
            .appendingPathComponent("ConcertResources", isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
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
        if old_thumb not in thumb:
            raise SystemExit("Expected Akita Bundle-only thumbnail resolver not found; refusing to patch.")
        thumb = thumb.replace(old_thumb, new_thumb, 1)

    THUMB.write_text(thumb, encoding="utf-8")
    print("Applied SideStore Lite external-first Akita poster-frame resolver.")
else:
    print("SideStore Lite Akita poster-frame resolver already applied.")
