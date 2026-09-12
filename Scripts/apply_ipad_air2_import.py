#!/usr/bin/env python3
from pathlib import Path

source = Path("App/Sources/The12DayDancerApp.swift")
text = source.read_text(encoding="utf-8")
marker = "AIR2-CONCERT-IMPORTER"

if marker in text:
    print("Air 2 ConcertResources importer already applied.")
    raise SystemExit(0)

if "import UniformTypeIdentifiers" not in text:
    needle = "import UIKit\n"
    if needle not in text:
        raise SystemExit("UIKit import not found; refusing to patch.")
    text = text.replace(needle, needle + "import UniformTypeIdentifiers\n", 1)

state_needle = "struct ContentView: View {\n    var body: some View {"
state_replacement = """struct ContentView: View {
    // AIR2-CONCERT-IMPORTER
    @State private var showConcertImporter = false
    @State private var isImportingConcert = false
    @State private var concertImportStatus: String? = nil

    var body: some View {"""
if state_needle not in text:
    raise SystemExit("ContentView state insertion point not found; refusing to patch.")
text = text.replace(state_needle, state_replacement, 1)

ui_needle = """                            HStack {
                                Spacer(minLength: 10)
                                ConcertConsole(albums: concertAlbums)
                                    .frame(maxWidth: 700)
                            }

                            Text(\"Bryan MacKayne · The 12 Day Dancer\")"""
ui_replacement = """                            HStack {
                                Spacer(minLength: 10)
                                ConcertConsole(albums: concertAlbums)
                                    .frame(maxWidth: 700)
                            }

                            HStack(spacing: 12) {
                                Spacer(minLength: 10)

                                if isImportingConcert {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: gold))
                                    Text(\"IMPORTING CONCERTRESOURCES…\")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(cream.opacity(0.86))
                                } else {
                                    Button {
                                        showConcertImporter = true
                                    } label: {
                                        Label(\"IMPORT CONCERTRESOURCES\", systemImage: \"folder.badge.plus\")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(cream)
                                            .padding(.horizontal, 13)
                                            .padding(.vertical, 9)
                                            .background(Color.black.opacity(0.68))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 7)
                                                    .stroke(gold.opacity(0.72), lineWidth: 1)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 7))
                                    }
                                    .buttonStyle(.plain)
                                }

                                if let concertImportStatus {
                                    Text(concertImportStatus)
                                        .font(.caption2)
                                        .foregroundStyle(Color.white.opacity(0.68))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            .frame(maxWidth: 700, alignment: .trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            Text(\"Bryan MacKayne · The 12 Day Dancer\")"""
if ui_needle not in text:
    raise SystemExit("ConcertConsole insertion point not found; refusing to patch.")
text = text.replace(ui_needle, ui_replacement, 1)

modifier_needle = """        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var mast"""
modifier_replacement = """        .navigationViewStyle(StackNavigationViewStyle())
        .fileImporter(
            isPresented: $showConcertImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let selected = urls.first else {
                    concertImportStatus = \"No folder selected\"
                    return
                }
                importConcertResources(from: selected)
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError {
                    concertImportStatus = \"Import failed: \\(error.localizedDescription)\"
                }
            }
        }
    }

    private func importConcertResources(from selectedURL: URL) {
        guard !isImportingConcert else { return }
        isImportingConcert = true
        concertImportStatus = \"Preparing import…\"

        DispatchQueue.global(qos: .userInitiated).async {
            let manager = FileManager.default
            let scoped = selectedURL.startAccessingSecurityScopedResource()
            defer {
                if scoped {
                    selectedURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                guard let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    throw NSError(
                        domain: \"The12DayDancer.Import\",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: \"Documents folder unavailable\"]
                    )
                }

                var sourceRoot = selectedURL
                let nested = selectedURL.appendingPathComponent(\"ConcertResources\", isDirectory: true)
                var isDirectory: ObjCBool = false
                if selectedURL.lastPathComponent != \"ConcertResources\",
                   manager.fileExists(atPath: nested.path, isDirectory: &isDirectory),
                   isDirectory.boolValue {
                    sourceRoot = nested
                }

                let destinationRoot = documents.appendingPathComponent(\"ConcertResources\", isDirectory: true)
                try manager.createDirectory(at: destinationRoot, withIntermediateDirectories: true)

                let sourcePath = sourceRoot.standardizedFileURL.resolvingSymlinksInPath().path
                let destinationPath = destinationRoot.standardizedFileURL.resolvingSymlinksInPath().path
                guard sourcePath != destinationPath else {
                    throw NSError(
                        domain: \"The12DayDancer.Import\",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: \"That is already the Dancer ConcertResources folder\"]
                    )
                }

                guard let enumerator = manager.enumerator(
                    at: sourceRoot,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    throw NSError(
                        domain: \"The12DayDancer.Import\",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: \"Could not read selected folder\"]
                    )
                }

                var copiedFiles = 0
                let prefix = sourceRoot.path.hasSuffix(\"/\") ? sourceRoot.path : sourceRoot.path + \"/\"

                for case let itemURL as URL in enumerator {
                    guard itemURL.path.hasPrefix(prefix) else { continue }
                    let relative = String(itemURL.path.dropFirst(prefix.count))
                    guard !relative.isEmpty else { continue }

                    let destination = destinationRoot.appendingPathComponent(relative)
                    let values = try itemURL.resourceValues(forKeys: [.isDirectoryKey])

                    if values.isDirectory == true {
                        try manager.createDirectory(at: destination, withIntermediateDirectories: true)
                    } else {
                        try manager.createDirectory(
                            at: destination.deletingLastPathComponent(),
                            withIntermediateDirectories: true
                        )
                        if manager.fileExists(atPath: destination.path) {
                            try manager.removeItem(at: destination)
                        }
                        try manager.copyItem(at: itemURL, to: destination)
                        copiedFiles += 1

                        if copiedFiles % 25 == 0 {
                            let progress = copiedFiles
                            DispatchQueue.main.async {
                                concertImportStatus = \"Imported \\(progress) files…\"
                            }
                        }
                    }
                }

                DispatchQueue.main.async {
                    isImportingConcert = false
                    concertImportStatus = \"ConcertResources ready · \\(copiedFiles) files\"
                }
            } catch {
                DispatchQueue.main.async {
                    isImportingConcert = false
                    concertImportStatus = \"Import failed: \\(error.localizedDescription)\"
                }
            }
        }
    }

    private var mast"""
if modifier_needle not in text:
    raise SystemExit("NavigationView modifier insertion point not found; run compatibility patch first.")
text = text.replace(modifier_needle, modifier_replacement, 1)

source.write_text(text, encoding="utf-8")
print("Applied Air 2 in-app ConcertResources folder importer.")
