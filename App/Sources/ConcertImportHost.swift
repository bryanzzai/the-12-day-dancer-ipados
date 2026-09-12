import SwiftUI
import UniformTypeIdentifiers
import UIKit

// IPAD-PRO-12-9-CONCERT-IMPORTER
// iPadOS 17.7.x: follow Apple's documented directory-picker flow exactly.
// Present UIDocumentPickerViewController directly from UIKit, request only .folder,
// single selection, and coordinate reads from the returned security-scoped URL.
final class ConcertFolderPickerSession: NSObject, UIDocumentPickerDelegate {
    private let onPick: (URL) -> Void
    private let onCancel: () -> Void

    init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
        self.onPick = onPick
        self.onCancel = onCancel
    }

    @MainActor
    func present() {
        guard let presenter = Self.topViewController() else {
            onCancel()
            return
        }

        // Apple's directory-access documentation uses this exact initializer for folders.
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        picker.overrideUserInterfaceStyle = .light
        presenter.present(picker, animated: true)
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

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        let window = scenes
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })
            ?? scenes.flatMap(\.windows).first(where: { !$0.isHidden })

        guard var top = window?.rootViewController else { return nil }

        while true {
            if let presented = top.presentedViewController {
                top = presented
                continue
            }
            if let nav = top as? UINavigationController, let visible = nav.visibleViewController {
                top = visible
                continue
            }
            if let tab = top as? UITabBarController, let selected = tab.selectedViewController {
                top = selected
                continue
            }
            break
        }
        return top
    }
}

struct ConcertImportHost<Content: View>: View {
    private let content: Content

    @State private var pickerSession: ConcertFolderPickerSession? = nil
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
                    presentFolderPicker()
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
    }

    @MainActor
    private func presentFolderPicker() {
        let session = ConcertFolderPickerSession(
            onPick: { selectedFolder in
                pickerSession = nil
                importConcertResources(from: selectedFolder)
            },
            onCancel: {
                pickerSession = nil
            }
        )
        pickerSession = session // Retain the delegate for the lifetime of the picker.
        session.present()
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

                let destinationRoot = documents.appendingPathComponent("ConcertResources", isDirectory: true)
                try manager.createDirectory(at: destinationRoot, withIntermediateDirectories: true)

                var coordinationError: NSError?
                var importError: Error?

                let coordinator = NSFileCoordinator(filePresenter: nil)
                coordinator.coordinate(
                    readingItemAt: selectedURL,
                    options: [.withoutChanges],
                    error: &coordinationError
                ) { coordinatedURL in
                    do {
                        try copySelectedDirectory(
                            from: coordinatedURL,
                            to: destinationRoot,
                            manager: manager
                        )
                    } catch {
                        importError = error
                    }
                }

                if let error = coordinationError {
                    throw error
                }
                if let error = importError {
                    throw error
                }

                let copiedFiles = try countFiles(in: destinationRoot, manager: manager)
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

    private func copySelectedDirectory(
        from selectedURL: URL,
        to destinationRoot: URL,
        manager: FileManager
    ) throws {
        // Bryan may select ConcertResources itself or its parent folder.
        var sourceRoot = selectedURL
        let nested = selectedURL.appendingPathComponent("ConcertResources", isDirectory: true)
        var nestedIsDirectory: ObjCBool = false
        if selectedURL.lastPathComponent != "ConcertResources",
           manager.fileExists(atPath: nested.path, isDirectory: &nestedIsDirectory),
           nestedIsDirectory.boolValue {
            sourceRoot = nested
        }

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
    }

    private func countFiles(in root: URL, manager: FileManager) throws -> Int {
        guard let enumerator = manager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var count = 0
        for case let itemURL as URL in enumerator {
            let values = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            if values.isDirectory != true {
                count += 1
            }
        }
        return count
    }
}
