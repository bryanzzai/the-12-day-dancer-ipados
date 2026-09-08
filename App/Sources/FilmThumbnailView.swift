import SwiftUI
import AVFoundation
import UIKit

private let akitaThumbnailTimes: [String: Double] = [
    "A Count of Tears [ V ]": 140,
    "A Dollar and a Dime [ I ]": 144,
    "A Dollar and a Dime [ II ]": 144,
    "A Dollar and a Dime [ III ]": 212,
    "Black Hole Heart": 85,
    "Gateway Girl [ I ]": 129,
    "Gateway Girl [ II ]": 152,
    "Intergalactic Lovers [ I ]": 137,
    "Intergalactic Lovers [ II ]": 138,
]

private func thumbnailResourceURL(_ name: String) -> URL? {
    guard !name.isEmpty else { return nil }
    let url = Bundle.main.bundleURL
        .appendingPathComponent("ConcertResources", isDirectory: true)
        .appendingPathComponent(name, isDirectory: false)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

struct FilmThumbnailView: View {
    let film: FilmDefinition
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color.white.opacity(0.10), Color.black.opacity(0.80)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "film")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.38))
            }
        }
        .task(id: film.mediaResource) {
            guard image == nil,
                  let url = thumbnailResourceURL(film.mediaResource)
            else { return }

            let seconds = akitaThumbnailTimes[film.title] ?? 30
            let loaded = await Task.detached(priority: .utility) { () -> UIImage? in
                let asset = AVURLAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 720, height: 405)
                generator.requestedTimeToleranceBefore = CMTime(seconds: 1.0, preferredTimescale: 600)
                generator.requestedTimeToleranceAfter = CMTime(seconds: 1.0, preferredTimescale: 600)

                let duration = asset.duration.seconds
                let requestedSeconds: Double
                if duration.isFinite && duration > 1 {
                    requestedSeconds = min(seconds, max(0, duration - 0.5))
                } else {
                    requestedSeconds = max(0, seconds)
                }

                let time = CMTime(seconds: requestedSeconds, preferredTimescale: 600)
                guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
                    return nil
                }
                return UIImage(cgImage: cgImage)
            }.value

            if !Task.isCancelled {
                image = loaded
            }
        }
    }
}
