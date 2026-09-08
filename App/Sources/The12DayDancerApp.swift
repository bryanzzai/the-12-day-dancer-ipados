import SwiftUI
import AVFoundation
import AVKit

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

struct AlbumSlot: Identifiable {
    let id = UUID()
    let roman: String
    let name: String
    let liveProbe: Bool
}

private let slots: [AlbumSlot] = [
    .init(roman: "I", name: "Dies Iovis", liveProbe: false),
    .init(roman: "II", name: "Dies Solis", liveProbe: false),
    .init(roman: "III", name: "Dies Martis", liveProbe: false),
    .init(roman: "IV", name: "Dies Albini", liveProbe: false),
    .init(roman: "V", name: "Dies Tigris", liveProbe: false),
    .init(roman: "VI", name: "Dies Delfini", liveProbe: false),
    .init(roman: "VII", name: "Dies Canis", liveProbe: false),
    .init(roman: "VIII", name: "Dies Felis", liveProbe: false),
    .init(roman: "IX", name: "Dies Tauri", liveProbe: false),
    .init(roman: "X", name: "Dies Ursi", liveProbe: false),
    .init(roman: "XI", name: "Dies Apri", liveProbe: true),
    .init(roman: "XII", name: "Dies Akita", liveProbe: true)
]

struct ContentView: View {
    private let columns = [GridItem(.adaptive(minimum: 205), spacing: 18)]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.black, Color(red: 0.07, green: 0.08, blue: 0.11)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 7) {
                            Text("BRYAN MACKAYNE")
                                .font(.caption.weight(.semibold))
                                .tracking(4)
                                .foregroundStyle(.secondary)
                            Text("The 12 Day Dancer")
                                .font(.system(size: 48, weight: .semibold, design: .serif))
                            Text("Native iPadOS probe · AVFoundation · no WebKit")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 12)

                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(slots) { slot in
                                slotView(slot)
                            }
                        }

                        Text("This is the jolle: XI and XII are live. The other ten slots are present only to prove the final panel geometry on the physical iPad.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(24)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private func slotView(_ slot: AlbumSlot) -> some View {
        if slot.name == "Dies Apri" {
            NavigationLink { ApriPlayerView() } label: { PanelButton(slot: slot) }
                .buttonStyle(.plain)
        } else if slot.name == "Dies Akita" {
            NavigationLink { AkitaProbeView() } label: { PanelButton(slot: slot) }
                .buttonStyle(.plain)
        } else {
            PanelButton(slot: slot)
                .opacity(0.42)
        }
    }
}

struct PanelButton: View {
    let slot: AlbumSlot

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.13), Color.white.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(slot.liveProbe ? Color.yellow.opacity(0.65) : Color.white.opacity(0.16), lineWidth: 1)
                VStack(spacing: 8) {
                    Text(slot.roman)
                        .font(.caption2.bold())
                        .tracking(2)
                        .foregroundStyle(slot.liveProbe ? .yellow : .secondary)
                    Image(systemName: slot.name == "Dies Akita" ? "film.fill" : "waveform")
                        .font(.system(size: 34, weight: .light))
                    Text(slot.name)
                        .font(.title3.weight(.semibold))
                        .fontDesign(.serif)
                    if slot.liveProbe {
                        Text("NATIVE PROBE")
                            .font(.caption2.bold())
                            .tracking(1.5)
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(18)
            }
            .frame(height: 180)
        }
        .contentShape(Rectangle())
    }
}

struct Track: Identifiable {
    let title: String
    let file: String
    var id: String { file }
}

private let apriTracks: [Track] = [
    .init(title: "Alternating Ambience [ I ] MX", file: "Alternating.Ambience.I.MX.web.m4a"),
    .init(title: "Alternating Ambience [ II ] MX", file: "Alternating.Ambience.II.MX.web.m4a"),
    .init(title: "Alternating Ambience [ III ] MX", file: "Alternating.Ambience.III.MX.web.m4a"),
    .init(title: "Alternating Ambience [ IV ] MX", file: "Alternating.Ambience.IV.MX.web.m4a"),
    .init(title: "Alternating Ambience [ V ] MX", file: "Alternating.Ambience.V.MX.web.m4a"),
    .init(title: "Alternating Ambience [ VI ] MX", file: "Alternating.Ambience.VI.MX.web.m4a"),
    .init(title: "Alternating Ambience [ VII ] MX", file: "Alternating.Ambience.VII.MX.web.m4a"),
    .init(title: "Alternating Ambience [ VIII ] MX", file: "Alternating.Ambience.VIII.MX.web.m4a")
]

@MainActor
final class AudioPlayerModel: ObservableObject {
    let tracks = apriTracks
    let player = AVPlayer()

    @Published var currentIndex = 0
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var volume: Double = 0.86
    @Published var status = "ready"

    private var timeObserver: Any?

    init() {
        player.volume = Float(volume)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self else { return }
            let now = time.seconds
            self.currentTime = now.isFinite ? now : 0
            if let seconds = self.player.currentItem?.duration.seconds, seconds.isFinite, seconds > 0 {
                self.duration = seconds
            }
        }
        load(index: 0, autoplay: false)
    }

    func load(index: Int, autoplay: Bool) {
        guard tracks.indices.contains(index) else { return }
        currentIndex = index
        guard let url = Bundle.main.url(forResource: tracks[index].file, withExtension: nil) else {
            status = "missing local media"
            return
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        currentTime = 0
        duration = 1
        status = "local · ready"
        if autoplay {
            player.play()
            isPlaying = true
        } else {
            isPlaying = false
        }
    }

    func togglePlay() {
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func previous() {
        load(index: (currentIndex - 1 + tracks.count) % tracks.count, autoplay: true)
    }

    func next() {
        load(index: (currentIndex + 1) % tracks.count, autoplay: true)
    }

    func seek(_ seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        currentTime = seconds
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

struct ApriPlayerView: View {
    @StateObject private var model = AudioPlayerModel()

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("Dies Apri")
                    .font(.system(size: 48, weight: .semibold, design: .serif))
                Text("American Hymnal")
                    .foregroundStyle(.secondary)
                Text(model.tracks[model.currentIndex].title)
                    .font(.title2.weight(.semibold))
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                Text(model.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: Binding(get: { model.currentTime }, set: { model.seek($0) }), in: 0...max(model.duration, 1))
                HStack {
                    Text(formatTime(model.currentTime))
                    Spacer()
                    Text(formatTime(model.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

                HStack(spacing: 26) {
                    Button(action: model.previous) { Image(systemName: "backward.end.fill") }
                    Button(action: model.togglePlay) {
                        Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 58))
                    }
                    Button(action: model.next) { Image(systemName: "forward.end.fill") }
                }
                .font(.title2)
                .buttonStyle(.plain)

                HStack {
                    Image(systemName: "speaker.fill")
                    Slider(value: Binding(get: { model.volume }, set: { model.setVolume($0) }), in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                }
                .foregroundStyle(.secondary)
            }
            .padding(26)
            .background(Color.white.opacity(0.055))

            List(Array(model.tracks.enumerated()), id: \.element.id) { index, track in
                Button {
                    model.load(index: index, autoplay: true)
                } label: {
                    HStack(spacing: 14) {
                        Text(String(format: "%02d", index + 1))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(index == model.currentIndex ? .yellow : .secondary)
                            .frame(width: 30, alignment: .leading)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.headline)
                            Text("Bundled local M4A · AVPlayer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if index == model.currentIndex {
                            Image(systemName: model.isPlaying ? "speaker.wave.2.fill" : "music.note")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Dies Apri")
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

struct Film: Identifiable {
    let title: String
    let file: String
    var id: String { file }
}

private let probeFilms: [Film] = [
    .init(title: "A Count of Tears [ V ]", file: "A.Count.of.Tears.V.mp4")
]

@MainActor
final class FilmPlayerModel: ObservableObject {
    let films = probeFilms
    let player = AVPlayer()
    @Published var currentIndex = 0
    @Published var status = "ready"

    init() {
        load(index: 0, autoplay: false)
    }

    func load(index: Int, autoplay: Bool) {
        guard films.indices.contains(index) else { return }
        currentIndex = index
        guard let url = Bundle.main.url(forResource: films[index].file, withExtension: nil) else {
            status = "missing local video"
            return
        }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        status = "local MP4 · AVPlayer"
        if autoplay { player.play() }
    }

    func stop() { player.pause() }
}

struct AkitaProbeView: View {
    @StateObject private var model = FilmPlayerModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Dies Akita")
                        .font(.system(size: 46, weight: .semibold, design: .serif))
                    Text("Brumbrum native video probe")
                        .foregroundStyle(.secondary)
                }

                VideoPlayer(player: model.player)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .background(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.14)))

                Text(model.films[model.currentIndex].title)
                    .font(.title2.weight(.semibold))
                    .fontDesign(.serif)
                Text(model.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    model.load(index: 0, autoplay: true)
                } label: {
                    Label("Play Brumbrum", systemImage: "play.fill")
                        .font(.headline)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)

                Text("The probe bundles one of the nine Dies Akita films. If this behaves correctly on the physical iPad, the final build uses the same native player for all nine.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(24)
        }
        .navigationTitle("Dies Akita")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onDisappear { model.stop() }
    }
}
