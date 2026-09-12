import SwiftUI
import UniformTypeIdentifiers
import UIKit

// IPAD-PRO-12-9-CONCERT-IMPORTER
// iPadOS 17.7.x does not reliably return the current directory through SwiftUI's
// fileImporter(.folder). Use UIKit's documented directory picker instead. We
// deliberately enable selection mode so the Files UI exposes Select/Done and
// returns one security-scoped folder URL with recursive access to its contents.
struct ConcertFolderPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [.folder],
            asCopy: false
        )
        picker.delegate = context.coordinator
        // On iPadOS 17 this forces the Files picker into explicit selection mode,
        // which exposes Select/Done instead of the inert single-folder Open path.
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL) -> Void
        private let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            guard let folder = urls.first else {
                onCancel()
                return
            }
            onPick(folder)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}

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
        .sheet(isPresented: $showImporter) {
            ConcertFolderPicker(
                onPick: { selectedFolder in
                    showImporter = false
                    importConcertResources(from: selectedFolder)
                },
                onCancel: {
                    showImporter = false
                }
            )
        }
    }

    private func importConcertResources(from selectedURL: URL) {
        guard !isImporting else { return }
        isImporting = true
        statusText = "Preparing ConcertResources…"

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
                        domain: "The12DayDancer.Import",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Documents folder unavailable"]
                    )
                }

                // Bryan may select ConcertResources itself or its parent folder.
                var sourceRoot = selectedURL
                let nested = selectedURL.appendingPathComponent("ConcertResources", isDirectory: true)
                var nestedIsDirectory: ObjCBool = false
                if selectedURL.lastPathComponent != "ConcertResources",
                   manager.fileExists(atPath: nested.path, isDirectory: &nestedIsDirectory),
                   nestedIsDirectory.boolValue {
                    sourceRoot = nested
                }

                let destinationRoot = documents.appendingPathComponent("ConcertResources", isDirectory: true)
                try manager.createDirectory(at: destinationRoot, withIntermediateDirectories: true)

                let sourcePath = sourceRoot.standardizedFileURL.resolvingSymlinksInPath().path
                let destinationPath = destinationRoot.standardizedFileURL.resolvingSymlinksInPath().path
                guard sourcePath != destinationPath else {
                    throw NSError(
                        domain: "The12DayDancer.Import",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "That is already the Dancer ConcertResources folder"]
                    )
                }

                guard let enumerator = manager.enumerator(
                    at: sourceRoot,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    throw NSError(
                        domain: "The12DayDancer.Import",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Could not read selected folder"]
                    )
                }

                let prefix = sourceRoot.path.hasSuffix("/") ? sourceRoot.path : sourceRoot.path + "/"
                var copiedFiles = 0

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
                            let current = copiedFiles
                            DispatchQueue.main.async {
                                statusText = "Imported \(current) files…"
                            }
                        }
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
}
