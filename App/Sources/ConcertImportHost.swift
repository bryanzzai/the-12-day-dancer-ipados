import SwiftUI
import UniformTypeIdentifiers

// IPAD-PRO-12-9-CONCERT-IMPORTER
// iPadOS 17.7.x may show a folder-only picker whose Open button does not
// actually return the current folder. This edition therefore imports selected
// ConcertResources ITEMS instead: enter ConcertResources, Select All, then Open.
struct ConcertImportHost<Content: View>: View {
    private let content: Content

    @State private var showImporter = false
    @State private var isImporting = false
    @State private var statusText: String? = nil

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            content

            VStack(alignment: .leading, spacing: 7) {
                if let status = statusText {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.74))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.68))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                Button {
                    showImporter = true
                } label: {
                    HStack(spacing: 7) {
                        if isImporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                                .scaleEffect(0.78)
                        } else {
                            Image(systemName: "folder.badge.plus")
                        }
                        Text(isImporting ? "IMPORTING…" : "IMPORT")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(red: 0.96, green: 0.91, blue: 0.78))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.black.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.83, green: 0.68, blue: 0.33).opacity(0.78), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(isImporting)
            }
            .padding(.leading, 18)
            .padding(.bottom, 14)
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                guard !urls.isEmpty else {
                    statusText = "No files selected"
                    return
                }
                importConcertResources(items: urls)
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError {
                    statusText = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func importConcertResources(items: [URL]) {
        guard !isImporting else { return }
        isImporting = true
        statusText = "Preparing \(items.count) selected items…"

        DispatchQueue.global(qos: .userInitiated).async {
            let manager = FileManager.default

            do {
                guard let documents = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    throw NSError(
                        domain: "The12DayDancer.Import",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Documents folder unavailable"]
                    )
                }

                let destinationRoot = documents.appendingPathComponent("ConcertResources", isDirectory: true)
                try manager.createDirectory(at: destinationRoot, withIntermediateDirectories: true)

                var copiedFiles = 0

                for selectedURL in items {
                    let scoped = selectedURL.startAccessingSecurityScopedResource()
                    defer {
                        if scoped {
                            selectedURL.stopAccessingSecurityScopedResource()
                        }
                    }

                    let values = try selectedURL.resourceValues(forKeys: [.isDirectoryKey])
                    if values.isDirectory == true {
                        copiedFiles += try copyDirectoryContents(
                            from: selectedURL,
                            to: destinationRoot,
                            manager: manager,
                            startingCount: copiedFiles
                        )
                    } else {
                        let destination = destinationRoot.appendingPathComponent(selectedURL.lastPathComponent)
                        try replaceCopy(from: selectedURL, to: destination, manager: manager)
                        copiedFiles += 1
                        publishProgress(copiedFiles)
                    }
                }

                DispatchQueue.main.async {
                    isImporting = false
                    statusText = "ConcertResources ready · \(copiedFiles) files"
                }
            } catch {
                DispatchQueue.main.async {
                    isImporting = false
                    statusText = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func copyDirectoryContents(
        from sourceRoot: URL,
        to destinationRoot: URL,
        manager: FileManager,
        startingCount: Int
    ) throws -> Int {
        guard let enumerator = manager.enumerator(
            at: sourceRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        let prefix = sourceRoot.path.hasSuffix("/") ? sourceRoot.path : sourceRoot.path + "/"
        var copied = 0

        for case let itemURL as URL in enumerator {
            guard itemURL.path.hasPrefix(prefix) else { continue }
            let relative = String(itemURL.path.dropFirst(prefix.count))
            guard !relative.isEmpty else { continue }

            let destination = destinationRoot.appendingPathComponent(relative)
            let values = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            if values.isDirectory == true {
                try manager.createDirectory(at: destination, withIntermediateDirectories: true)
            } else {
                try replaceCopy(from: itemURL, to: destination, manager: manager)
                copied += 1
                publishProgress(startingCount + copied)
            }
        }

        return copied
    }

    private func replaceCopy(from source: URL, to destination: URL, manager: FileManager) throws {
        try manager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if manager.fileExists(atPath: destination.path) {
            try manager.removeItem(at: destination)
        }
        try manager.copyItem(at: source, to: destination)
    }

    private func publishProgress(_ copiedFiles: Int) {
        if copiedFiles % 25 == 0 {
            DispatchQueue.main.async {
                statusText = "Imported \(copiedFiles) files…"
            }
        }
    }
}
