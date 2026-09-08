#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "App" / "Sources" / "The12DayDancerApp.swift"
CARD = ROOT / "App" / "Sources" / "AkitaFilmCard.swift"
THUMB = ROOT / "App" / "Sources" / "FilmThumbnailView.swift"

text = SOURCE.read_text(encoding="utf-8")

if "UI-FIX-V5-FINAL-POLISH" not in text:
    # Bulgarian console: fixed geometry. Image intrinsic sizes can no longer force cells to overlap.
    text = text.replace(
        "private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)",
        "private let columns = Array(repeating: GridItem(.fixed(180), spacing: 14), count: 3)",
        1,
    )
    text = text.replace(".frame(maxWidth: 700)", ".frame(maxWidth: 650)", 1)
    text = text.replace(".frame(height: 118)", ".frame(width: 180, height: 118)", 1)
    text = text.replace(
        """                .minimumScaleFactor(0.72)\n                .frame(maxWidth: .infinity)\n                .padding(.vertical, 8)""",
        """                .minimumScaleFactor(0.72)\n                .frame(width: 180)\n                .padding(.vertical, 8)""",
        1,
    )
    text = text.replace(
        """        .contentShape(Rectangle())\n    }\n}\n\nstruct AlbumDestinationView""",
        """        .frame(width: 180)\n        .clipped()\n        .contentShape(Rectangle())\n    }\n}\n\nstruct AlbumDestinationView""",
        1,
    )

    # Artwork button is redundant: album thumbs already open the gallery.
    text = text.replace(
        """                Spacer()\n                Button {\n                    artworkIndex = model.currentIndex\n                } label: {\n                    Label(\"Artwork\", systemImage: \"photo.on.rectangle\")\n                        .font(.subheadline.weight(.semibold))\n                }\n                .buttonStyle(.bordered)\n                .tint(gold)\n""",
        "",
        1,
    )

    # Artwork gallery: preserve down-to-close and add horizontal swipe navigation.
    text = text.replace(
        'Text("Swipe down to close")',
        'Text("Swipe sideways to browse · down to close")',
        1,
    )
    text = text.replace(
        """        .gesture(\n            DragGesture(minimumDistance: 35)\n                .onEnded { value in\n                    if value.translation.height > 90 { close() }\n                }\n        )""",
        """        .gesture(\n            DragGesture(minimumDistance: 35)\n                .onEnded { value in\n                    let dx = value.translation.width\n                    let dy = value.translation.height\n                    if abs(dx) > abs(dy), abs(dx) > 70 {\n                        if dx < 0 {\n                            index = (index + 1) % album.tracks.count\n                        } else {\n                            index = (index - 1 + album.tracks.count) % album.tracks.count\n                        }\n                    } else if dy > 90 {\n                        close()\n                    }\n                }\n        )""",
        1,
    )

    # Harden the video transport model. Film selection already proved load() works on the physical iPad;
    # these explicit target calculations and playImmediately calls make the three transport buttons use
    # the exact same path as selecting a film from the magazine.
    vm_start = text.find("@MainActor\nfinal class VideoPlayerModel")
    vm_end = text.find("// UI-FIX-V3-AKITA-GRID:", vm_start)
    if vm_start < 0 or vm_end < 0:
        raise SystemExit("V5 patch: VideoPlayerModel section not found")
    vm = text[vm_start:vm_end]
    vm = vm.replace(
        """        player.replaceCurrentItem(with: AVPlayerItem(url: url))\n        status = \"local · ready\"\n        if autoplay {\n            player.play()\n            status = \"local · playing\"\n        }""",
        """        player.pause()\n        player.replaceCurrentItem(with: AVPlayerItem(url: url))\n        status = \"local · ready\"\n        if autoplay {\n            player.playImmediately(atRate: 1.0)\n            status = \"local · playing\"\n        }""",
        1,
    )
    vm = vm.replace(
        """    func previous() {\n        guard !album.films.isEmpty else { return }\n        load(index: (currentIndex - 1 + album.films.count) % album.films.count, autoplay: true)\n    }\n\n    func next(autoplay: Bool = true) {\n        guard !album.films.isEmpty else { return }\n        load(index: (currentIndex + 1) % album.films.count, autoplay: autoplay)\n    }\n\n    func restart() {\n        player.seek(to: .zero)\n        player.play()\n        status = \"local · playing\"\n    }""",
        """    func previous() {\n        guard !album.films.isEmpty else { return }\n        let target = (currentIndex - 1 + album.films.count) % album.films.count\n        load(index: target, autoplay: true)\n    }\n\n    func next(autoplay: Bool = true) {\n        guard !album.films.isEmpty else { return }\n        let target = (currentIndex + 1) % album.films.count\n        load(index: target, autoplay: autoplay)\n    }\n\n    func restart() {\n        player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in\n            guard finished else { return }\n            Task { @MainActor [weak self] in\n                self?.player.playImmediately(atRate: 1.0)\n                self?.status = \"local · playing\"\n            }\n        }\n    }""",
        1,
    )
    text = text[:vm_start] + vm + text[vm_end:]

    # Video magazine: exact fixed 16:9 cells and explicit full-screen playback.
    text = text.replace(
        """    @StateObject private var model: VideoPlayerModel\n\n    private let columns = Array(\n        repeating: GridItem(.flexible(minimum: 220, maximum: 320), spacing: 16),\n        count: 3\n    )""",
        """    @StateObject private var model: VideoPlayerModel\n    @State private var showFullScreen = false\n\n    private let columns = Array(repeating: GridItem(.fixed(280), spacing: 16), count: 3)""",
        1,
    )
    text = text.replace(
        """        .preferredColorScheme(.dark)\n        .onDisappear { model.stop() }\n    }\n\n    private var cinemaPanel""",
        """        .preferredColorScheme(.dark)\n        .onDisappear { model.stop() }\n        .fullScreenCover(isPresented: $showFullScreen) {\n            FullScreenVideoView(player: model.player, title: currentFilm.title) {\n                showFullScreen = false\n            }\n        }\n    }\n\n    private var cinemaPanel""",
        1,
    )
    text = text.replace(
        """            VideoPlayer(player: model.player)\n                .aspectRatio(16.0 / 9.0, contentMode: .fit)\n                .background(Color.black)\n                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))\n                .overlay(\n                    RoundedRectangle(cornerRadius: 18)\n                        .stroke(Color.white.opacity(0.12))\n                )\n\n            nowShowingBar""",
        """            ZStack(alignment: .topTrailing) {\n                VideoPlayer(player: model.player)\n                    .aspectRatio(16.0 / 9.0, contentMode: .fit)\n                    .background(Color.black)\n                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))\n                    .overlay(\n                        RoundedRectangle(cornerRadius: 18)\n                            .stroke(Color.white.opacity(0.12))\n                    )\n\n                Button {\n                    showFullScreen = true\n                } label: {\n                    Image(systemName: \"arrow.up.left.and.arrow.down.right\")\n                        .font(.system(size: 18, weight: .bold))\n                        .frame(width: 46, height: 42)\n                        .foregroundStyle(.white)\n                        .background(Color.black.opacity(0.72))\n                        .clipShape(RoundedRectangle(cornerRadius: 10))\n                }\n                .buttonStyle(.plain)\n                .padding(12)\n            }\n\n            nowShowingBar""",
        1,
    )
    text = text.replace(
        """            HStack(spacing: 10) {\n                Button(action: model.previous) {\n                    Image(systemName: \"backward.end.fill\")\n                }\n                Button(action: model.restart) {\n                    Image(systemName: \"arrow.counterclockwise\")\n                }\n                Button {\n                    model.next()\n                } label: {\n                    Image(systemName: \"forward.end.fill\")\n                }\n            }\n            .buttonStyle(.bordered)""",
        """            HStack(spacing: 12) {\n                Button {\n                    model.previous()\n                } label: {\n                    Label(\"Previous\", systemImage: \"backward.end.fill\")\n                        .frame(minWidth: 92, minHeight: 38)\n                }\n                Button {\n                    model.restart()\n                } label: {\n                    Label(\"Replay\", systemImage: \"arrow.counterclockwise\")\n                        .frame(minWidth: 92, minHeight: 38)\n                }\n                Button {\n                    model.next()\n                } label: {\n                    Label(\"Next\", systemImage: \"forward.end.fill\")\n                        .frame(minWidth: 92, minHeight: 38)\n                }\n            }\n            .buttonStyle(.borderedProminent)\n            .tint(Color.white.opacity(0.12))""",
        1,
    )

    full_screen = r'''struct FullScreenVideoView: View {
    let player: AVPlayer
    let title: String
    let close: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: player)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(1)
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(radius: 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

'''
    text = text.replace("private func formatTime", full_screen + "private func formatTime", 1)
    text = text.replace("// UI-FIX-V4-SPLIT:", "// UI-FIX-V5-FINAL-POLISH:\n// UI-FIX-V4-SPLIT:", 1)

SOURCE.write_text(text, encoding="utf-8")

# Film cards are fixed-size so native 16:9 films cannot force the first row wider than the other six.
card = CARD.read_text(encoding="utf-8")
if ".frame(width: 280, height: 158)" not in card:
    card = card.replace(
        """            .background(Color.black.opacity(0.46))""",
        """            .frame(width: 280)\n            .background(Color.black.opacity(0.46))""",
        1,
    )
    card = card.replace(
        """            .padding(10)\n        }\n    }""",
        """            .padding(10)\n        }\n        .frame(width: 280, height: 158)\n        .clipped()\n    }""",
        1,
    )
    CARD.write_text(card, encoding="utf-8")

thumb = THUMB.read_text(encoding="utf-8")
if "        .clipped()\n        .task(id: film.mediaResource)" not in thumb:
    thumb = thumb.replace(
        """        }\n        .task(id: film.mediaResource)""",
        """        }\n        .clipped()\n        .task(id: film.mediaResource)""",
        1,
    )
    THUMB.write_text(thumb, encoding="utf-8")

print("Native UI V5 polish applied: fixed console/cards, artwork swipes, video transport and full screen.")
