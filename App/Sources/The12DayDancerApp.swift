import SwiftUI
import AVFoundation
import AVKit
import UIKit

@main
struct The12DayDancerApp: App {
    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

enum AlbumKind {
    case audio
    case video
}

struct TrackDefinition: Identifiable {
    let title: String
    let mediaResource: String
    let artworkResource: String
    var id: String { mediaResource }
}

struct FilmDefinition: Identifiable {
    let title: String
    let mediaResource: String
    let durationLabel: String
    var id: String { mediaResource }
}

struct AlbumDefinition: Identifiable {
    let roman: String
    let slug: String
    let title: String
    let subtitle: String
    let description: String
    let kind: AlbumKind
    let bannerResource: String
    let portraitResource: String
    let tracks: [TrackDefinition]
    let films: [FilmDefinition]
    var id: String { slug }
}

private let gold = Color(red: 0.83, green: 0.68, blue: 0.33)
private let cream = Color(red: 0.96, green: 0.91, blue: 0.78)
private let panelBlack = Color(red: 0.035, green: 0.04, blue: 0.04)

private func concertResourceURL(_ name: String) -> URL? {
    guard !name.isEmpty else { return nil }
    let url = Bundle.main.bundleURL
        .appendingPathComponent("ConcertResources", isDirectory: true)
        .appendingPathComponent(name, isDirectory: false)
    return FileManager.default.fileExists(atPath: url.path) ? url : nil
}

struct LocalResourceImage: View {
    let resource: String
    var contentMode: ContentMode = .fill
    var fallbackSystemName: String = "photo"

    var body: some View {
        Group {
            if let url = concertResourceURL(resource), let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.white.opacity(0.11), Color.black.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: fallbackSystemName)
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    LocalResourceImage(resource: facadeBackgroundResource)
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .ignoresSafeArea()

                    LinearGradient(
                        colors: [Color.black.opacity(0.18), Color.black.opacity(0.04), Color.black.opacity(0.86)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    RadialGradient(
                        colors: [Color.clear, Color.black.opacity(0.62)],
                        center: .center,
                        startRadius: 120,
                        endRadius: max(proxy.size.width, proxy.size.height) * 0.75
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 22) {
                            mast
                                .padding(.top, 26)

                            Spacer(minLength: max(180, proxy.size.height * 0.30))

                            HStack {
                                Spacer(minLength: 10)
                                ConcertConsole(albums: concertAlbums)
                                    .frame(maxWidth: 700)
                            }

                            Text("Bryan MacKayne · The 12 Day Dancer")
                                .font(.caption2.weight(.semibold))
                                .tracking(2)
                                .foregroundStyle(Color.white.opacity(0.44))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 26)
                        .frame(minHeight: proxy.size.height)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var mast: some View {
        VStack(spacing: 13) {
            Text("BRYAN MACKAYNE")
                .font(.caption.weight(.semibold))
                .tracking(5)
                .foregroundStyle(Color(red: 0.79, green: 0.69, blue: 0.52))
            Text("The 12 Day Dancer")
                .font(.system(size: 58, weight: .medium, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.93, blue: 0.69), gold, Color(red: 0.61, green: 0.42, blue: 0.11)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.9), radius: 14, y: 7)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            HStack(spacing: 12) {
                Rectangle().fill(LinearGradient(colors: [.clear, gold, cream], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
                Image(systemName: "diamond.fill").font(.system(size: 8)).foregroundStyle(gold)
                Rectangle().fill(LinearGradient(colors: [cream, gold, .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
            }
            .frame(maxWidth: 560)
        }
        .multilineTextAlignment(.center)
    }
}

struct ConcertConsole: View {
    let albums: [AlbumDefinition]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("SELECTIO · XII ALBUM")
                Spacer()
                Text("МЕХАНИЧЕН ПУЛТ · РЪЧНО УПРАВЛЕНИЕ")
                    .foregroundStyle(Color(red: 0.51, green: 0.46, blue: 0.36))
                    .font(.system(size: 8, weight: .bold))
            }
            .font(.system(size: 10, weight: .bold))
            .tracking(2.2)
            .foregroundStyle(Color(red: 0.79, green: 0.69, blue: 0.48))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.black.opacity(0.9)))

            if albums.isEmpty {
                Text("Catalog not generated")
                    .foregroundStyle(.secondary)
                    .padding(40)
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(albums) { album in
                        NavigationLink {
                            AlbumDestinationView(album: album)
                        } label: {
                            MechanicalAlbumButton(album: album)
                        }
                        .buttonStyle(MechanicalPressStyle())
                    }
                }
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color(red: 0.28, green: 0.29, blue: 0.28), Color(red: 0.06, green: 0.07, blue: 0.07), Color(red: 0.19, green: 0.20, blue: 0.19)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.85), radius: 28, y: 18)
    }
}

struct MechanicalPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 8 : 0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.07), value: configuration.isPressed)
    }
}

struct MechanicalAlbumButton: View {
    let album: AlbumDefinition

    var body: some View {
        VStack(spacing: 9) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 13)
                    .fill(
                        LinearGradient(
                            colors: [Color.black, Color(red: 0.28, green: 0.29, blue: 0.28), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.85), radius: 7, y: 8)

                ZStack(alignment: .leading) {
                    LocalResourceImage(resource: album.bannerResource)
                        .scaledToFill()
                    LinearGradient(colors: [Color.black.opacity(0.32), .clear, Color.black.opacity(0.35)], startPoint: .leading, endPoint: .trailing)
                    LocalResourceImage(resource: album.portraitResource)
                        .scaledToFill()
                        .frame(maxWidth: 70)
                        .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .leading, endPoint: .trailing))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.72, green: 0.58, blue: 0.31), lineWidth: 2))
                .padding(8)

                Text(album.roman)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(Color(red: 0.93, green: 0.83, blue: 0.57))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.82))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(red: 0.73, green: 0.60, blue: 0.39).opacity(0.6)))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(13)
            }
            .frame(height: 118)

            Text(album.title)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.1)
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 0.94, green: 0.86, blue: 0.66))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
                .background(LinearGradient(colors: [Color(red: 0.18, green: 0.14, blue: 0.09), Color(red: 0.05, green: 0.04, blue: 0.03)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(red: 0.44, green: 0.34, blue: 0.18)))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .contentShape(Rectangle())
    }
}

struct AlbumDestinationView: View {
    let album: AlbumDefinition

    var body: some View {
        switch album.kind {
        case .audio:
            AudioAlbumView(album: album)
        case .video:
            VideoAlbumView(album: album)
        }
    }
}

struct AlbumHeroView: View {
    let album: AlbumDefinition

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LocalResourceImage(resource: album.bannerResource)
                .scaledToFill()
                .frame(height: 330)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.78), Color.black.opacity(0.18), Color.black.opacity(0.72)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 330)

            LocalResourceImage(resource: album.portraitResource)
                .scaledToFill()
                .frame(width: 265, height: 330)
                .clipped()
                .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .leading, endPoint: .trailing))

            LinearGradient(colors: [.clear, Color.black.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                .frame(height: 330)

            VStack(alignment: .leading, spacing: 7) {
                Text("BRYAN MACKAYNE")
                    .font(.caption2.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(gold)
                Text(album.title)
                    .font(.system(size: 50, weight: .medium, design: .serif))
                    .foregroundStyle(cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(album.subtitle)
                    .font(.title2.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.white.opacity(0.84))
                Text(album.description)
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(3)
            }
            .padding(.leading, 285)
            .padding(.trailing, 34)
            .padding(.bottom, 28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }
}

@MainActor
final class AudioPlayerModel: ObservableObject {
    let album: AlbumDefinition
    let player = AVPlayer()

    @Published var currentIndex = 0
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var volume: Double = 0.86
    @Published var shuffle = false
    @Published var repeatOne = false
    @Published var status = "ready"

    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    init(album: AlbumDefinition) {
        self.album = album
        player.volume = Float(volume)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentTime = time.seconds.isFinite ? max(0, time.seconds) : 0
                if let seconds = self.player.currentItem?.duration.seconds, seconds.isFinite, seconds > 0 {
                    self.duration = seconds
                }
            }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor [weak self] in
                guard let self, let item = note.object as? AVPlayerItem, item === self.player.currentItem else { return }
                if self.repeatOne {
                    self.seek(0)
                    self.player.play()
                    self.isPlaying = true
                } else {
                    self.next()
                }
            }
        }
        if !album.tracks.isEmpty {
            load(index: 0, autoplay: false)
        }
    }

    func load(index: Int, autoplay: Bool) {
        guard album.tracks.indices.contains(index) else { return }
        let track = album.tracks[index]
        currentIndex = index
        guard let url = concertResourceURL(track.mediaResource) else {
            status = "missing local media"
            isPlaying = false
            return
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        currentTime = 0
        duration = 1
        status = "local · ready"
        if autoplay {
            player.play()
            isPlaying = true
            status = "local · playing"
        } else {
            isPlaying = false
        }
    }

    func togglePlay() {
        guard !album.tracks.isEmpty else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
            status = "local · paused"
        } else {
            player.play()
            isPlaying = true
            status = "local · playing"
        }
    }

    func previous() {
        guard !album.tracks.isEmpty else { return }
        load(index: (currentIndex - 1 + album.tracks.count) % album.tracks.count, autoplay: true)
    }

    func next() {
        guard !album.tracks.isEmpty else { return }
        if shuffle && album.tracks.count > 1 {
            var candidate = currentIndex
            while candidate == currentIndex {
                candidate = Int.random(in: album.tracks.indices)
            }
            load(index: candidate, autoplay: true)
        } else {
            load(index: (currentIndex + 1) % album.tracks.count, autoplay: true)
        }
    }

    func seek(_ seconds: Double) {
        let value = max(0, min(seconds, duration))
        player.seek(to: CMTime(seconds: value, preferredTimescale: 600))
        currentTime = value
    }

    func setVolume(_ value: Double) {
        volume = value
        player.volume = Float(value)
    }

    func stop() {
        player.pause()
        isPlaying = false
    }
}

struct AudioAlbumView: View {
    let album: AlbumDefinition
    @StateObject private var model: AudioPlayerModel
    @State private var searchText = ""
    @State private var artworkIndex: Int?

    init(album: AlbumDefinition) {
        self.album = album
        _model = StateObject(wrappedValue: AudioPlayerModel(album: album))
    }

    private var filteredIndices: [Int] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return Array(album.tracks.indices) }
        return album.tracks.indices.filter { album.tracks[$0].title.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AlbumHeroView(album: album)

                if !album.tracks.isEmpty {
                    nowPlayingPanel
                    library
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 70)
        }
        .background(
            RadialGradient(colors: [Color(red: 0.09, green: 0.12, blue: 0.17), Color.black], center: .topLeading, startRadius: 20, endRadius: 900)
                .ignoresSafeArea()
        )
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onDisappear { model.stop() }
        .fullScreenCover(
            isPresented: Binding(
                get: { artworkIndex != nil },
                set: { if !$0 { artworkIndex = nil } }
            )
        ) {
            if let index = artworkIndex {
                ArtworkViewer(album: album, index: Binding(
                    get: { artworkIndex ?? index },
                    set: { artworkIndex = $0 }
                )) {
                    artworkIndex = nil
                }
            }
        }
    }

    private var nowPlayingPanel: some View {
        HStack(spacing: 24) {
            Button {
                artworkIndex = model.currentIndex
            } label: {
                LocalResourceImage(resource: album.tracks[model.currentIndex].artworkResource, contentMode: .fill)
                    .scaledToFill()
                    .frame(width: 210, height: 210)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.16)))
                    .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOW PLAYING")
                        .font(.caption2.weight(.bold))
                        .tracking(2.2)
                        .foregroundStyle(gold)
                    Text(album.tracks[model.currentIndex].title)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(cream)
                        .lineLimit(2)
                    Text(model.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(get: { model.currentTime }, set: { model.seek($0) }),
                    in: 0...max(model.duration, 1)
                )
                .tint(gold)

                HStack {
                    Text(formatTime(model.currentTime))
                    Spacer()
                    Text(formatTime(model.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button { model.shuffle.toggle() } label: {
                        Image(systemName: "shuffle")
                            .foregroundStyle(model.shuffle ? gold : Color.white.opacity(0.72))
                    }
                    Button(action: model.previous) { Image(systemName: "backward.end.fill") }
                    Button(action: model.togglePlay) {
                        Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 54))
                    }
                    Button(action: model.next) { Image(systemName: "forward.end.fill") }
                    Button { model.repeatOne.toggle() } label: {
                        Image(systemName: "repeat.1")
                            .foregroundStyle(model.repeatOne ? gold : Color.white.opacity(0.72))
                    }
                }
                .font(.title3)
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill")
                    Slider(value: Binding(get: { model.volume }, set: { model.setVolume($0) }), in: 0...1)
                        .tint(gold)
                    Image(systemName: "speaker.wave.3.fill")
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .background(LinearGradient(colors: [Color.white.opacity(0.075), Color.black.opacity(0.24)], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.10)))
    }

    private var library: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(album.title) · \(album.tracks.count) tracks")
                        .font(.title2.weight(.medium))
                        .fontDesign(.serif)
                    Text("Local native library")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search the album…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 10)
                .frame(maxWidth: 330)
                .background(Color.white.opacity(0.07))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.12)))
            }
            .padding(18)

            Divider().overlay(Color.white.opacity(0.10))

            LazyVStack(spacing: 0) {
                ForEach(filteredIndices, id: \.self) { index in
                    TrackRow(
                        album: album,
                        track: album.tracks[index],
                        index: index,
                        isCurrent: index == model.currentIndex,
                        isPlaying: model.isPlaying,
                        selectTrack: { model.load(index: index, autoplay: true) },
                        showArtwork: { artworkIndex = index }
                    )
                    if index != filteredIndices.last {
                        Divider().overlay(Color.white.opacity(0.07))
                    }
                }
            }
        }
        .background(Color.black.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08)))
    }
}

struct TrackRow: View {
    let album: AlbumDefinition
    let track: TrackDefinition
    let index: Int
    let isCurrent: Bool
    let isPlaying: Bool
    let selectTrack: () -> Void
    let showArtwork: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(String(format: "%02d", index + 1))
                .font(.caption.monospacedDigit())
                .foregroundStyle(isCurrent ? gold : Color.secondary)
                .frame(width: 34, alignment: .leading)

            Button(action: selectTrack) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(track.title)
                            .font(.headline)
                            .fontDesign(.serif)
                            .foregroundStyle(cream)
                            .multilineTextAlignment(.leading)
                        Text("Bryan MacKayne · \(album.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isCurrent {
                        Image(systemName: isPlaying ? "speaker.wave.2.fill" : "music.note")
                            .foregroundStyle(gold)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: showArtwork) {
                LocalResourceImage(resource: track.artworkResource, contentMode: .fill)
                    .scaledToFill()
                    .frame(width: 76, height: 76)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.13)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(isCurrent ? Color.white.opacity(0.055) : Color.clear)
    }
}

struct ArtworkViewer: View {
    let album: AlbumDefinition
    @Binding var index: Int
    let close: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LocalResourceImage(resource: album.tracks[index].artworkResource, contentMode: .fill)
                .scaledToFill()
                .blur(radius: 34)
                .brightness(-0.18)
                .scaleEffect(1.12)
                .ignoresSafeArea()

            Color.black.opacity(0.25).ignoresSafeArea()

            LocalResourceImage(resource: album.tracks[index].artworkResource, contentMode: .fit)
                .scaledToFit()
                .padding(.horizontal, 90)
                .padding(.vertical, 60)
                .shadow(color: .black.opacity(0.8), radius: 36, y: 18)

            HStack {
                Button {
                    index = (index - 1 + album.tracks.count) % album.tracks.count
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 32, weight: .semibold))
                        .frame(width: 58, height: 78)
                }
                Spacer()
                Button {
                    index = (index + 1) % album.tracks.count
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 32, weight: .semibold))
                        .frame(width: 58, height: 78)
                }
            }
            .padding(.horizontal, 18)
            .buttonStyle(.bordered)

            VStack {
                HStack {
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.bold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
                Text(album.tracks[index].title)
                    .font(.headline)
                    .fontDesign(.serif)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.58))
                    .clipShape(Capsule())
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}

@MainActor
final class VideoPlayerModel: ObservableObject {
    let album: AlbumDefinition
    let player = AVPlayer()
    @Published var currentIndex = 0
    @Published var status = "ready"

    private var endObserver: NSObjectProtocol?

    init(album: AlbumDefinition) {
        self.album = album
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor [weak self] in
                guard let self, let item = note.object as? AVPlayerItem, item === self.player.currentItem else { return }
                self.next(autoplay: true)
            }
        }
        if !album.films.isEmpty {
            load(index: 0, autoplay: false)
        }
    }

    func load(index: Int, autoplay: Bool) {
        guard album.films.indices.contains(index) else { return }
        currentIndex = index
        guard let url = concertResourceURL(album.films[index].mediaResource) else {
            status = "missing local video"
            return
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        status = "local · ready"
        if autoplay {
            player.play()
            status = "local · playing"
        }
    }

    func previous() {
        guard !album.films.isEmpty else { return }
        load(index: (currentIndex - 1 + album.films.count) % album.films.count, autoplay: true)
    }

    func next(autoplay: Bool = true) {
        guard !album.films.isEmpty else { return }
        load(index: (currentIndex + 1) % album.films.count, autoplay: autoplay)
    }

    func restart() {
        player.seek(to: .zero)
        player.play()
        status = "local · playing"
    }

    func stop() {
        player.pause()
    }
}

struct VideoAlbumView: View {
    let album: AlbumDefinition
    @StateObject private var model: VideoPlayerModel
    private let columns = [GridItem(.adaptive(minimum: 210), spacing: 14)]

    init(album: AlbumDefinition) {
        self.album = album
        _model = StateObject(wrappedValue: VideoPlayerModel(album: album))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AlbumHeroView(album: album)

                if !album.films.isEmpty {
                    VStack(spacing: 14) {
                        VideoPlayer(player: model.player)
                            .aspectRatio(16.0 / 9.0, contentMode: .fit)
                            .background(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12)))

                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("NOW SHOWING")
                                    .font(.caption2.weight(.bold))
                                    .tracking(2)
                                    .foregroundStyle(gold)
                                Text(album.films[model.currentIndex].title)
                                    .font(.title2.weight(.semibold))
                                    .fontDesign(.serif)
                                Text("Film \(model.currentIndex + 1) of \(album.films.count) · \(album.films[model.currentIndex].durationLabel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 10) {
                                Button(action: model.previous) { Image(systemName: "backward.end.fill") }
                                Button(action: model.restart) { Image(systemName: "arrow.counterclockwise") }
                                Button { model.next() } label: { Image(systemName: "forward.end.fill") }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.09)))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("\(album.title) · \(album.films.count) films")
                            .font(.title2.weight(.medium))
                            .fontDesign(.serif)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(Array(album.films.enumerated()), id: \.element.id) { index, film in
                                Button {
                                    model.load(index: index, autoplay: true)
                                } label: {
                                    ZStack(alignment: .bottomLeading) {
                                        LocalResourceImage(resource: album.bannerResource)
                                            .scaledToFill()
                                            .frame(height: 132)
                                            .clipped()
                                        LinearGradient(colors: [.clear, Color.black.opacity(0.92)], startPoint: .top, endPoint: .bottom)
                                        VStack(alignment: .leading, spacing: 5) {
                                            HStack {
                                                Text(String(format: "%02d", index + 1))
                                                    .font(.caption2.monospacedDigit().bold())
                                                    .foregroundStyle(gold)
                                                Spacer()
                                                Image(systemName: index == model.currentIndex ? "play.circle.fill" : "film")
                                                    .foregroundStyle(index == model.currentIndex ? gold : Color.white.opacity(0.72))
                                            }
                                            Text(film.title)
                                                .font(.headline)
                                                .fontDesign(.serif)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                            Text(film.durationLabel)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(12)
                                    }
                                    .frame(height: 132)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(index == model.currentIndex ? gold.opacity(0.72) : Color.white.opacity(0.11)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(18)
                    .background(Color.black.opacity(0.38))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 70)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onDisappear { model.stop() }
    }
}

private func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let value = Int(seconds.rounded(.down))
    return "\(value / 60):\(String(format: "%02d", value % 60))"
}
