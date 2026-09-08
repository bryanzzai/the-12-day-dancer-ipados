#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "App" / "Sources" / "The12DayDancerApp.swift"
text = SOURCE.read_text(encoding="utf-8")


def replace_section(start_marker: str, end_marker: str, replacement: str) -> None:
    global text
    start = text.find(start_marker)
    if start < 0:
        raise SystemExit(f"UI patch: start marker not found: {start_marker}")
    end = text.find(end_marker, start)
    if end < 0:
        raise SystemExit(f"UI patch: end marker not found: {end_marker}")
    text = text[:start] + replacement.rstrip() + "\n\n" + text[end:]


if "UI-FIX-V3-LANDING" not in text:
    replace_section(
        "struct ContentView: View {",
        "struct ConcertConsole: View {",
        r'''// UI-FIX-V3-LANDING: first viewport is the ballerina; console begins below the fold.
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
                            // Exactly one viewport of facade before the control console.
                            // This reproduces the original reveal: the panel is hidden until Bryan scrolls upward.
                            VStack(spacing: 0) {
                                mast.padding(.top, 26)
                                Spacer(minLength: 0)
                            }
                            .frame(height: proxy.size.height)

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
}'''
    )

if "UI-FIX-V3-NOW-PLAYING" not in text:
    replace_section(
        "    private var nowPlayingPanel: some View {",
        "    private var library: some View {",
        r'''    // UI-FIX-V3-NOW-PLAYING: artwork no longer consumes half the player panel.
    private var nowPlayingPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOW PLAYING")
                        .font(.caption2.weight(.bold))
                        .tracking(2.2)
                        .foregroundStyle(gold)
                    Text(album.tracks[model.currentIndex].title)
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(cream)
                        .lineLimit(2)
                    Text(model.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    artworkIndex = model.currentIndex
                } label: {
                    Label("Artwork", systemImage: "photo.on.rectangle")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(gold)
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

            HStack(spacing: 13) {
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

                Spacer(minLength: 24)

                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(get: { model.volume }, set: { model.setVolume($0) }),
                    in: 0...1
                )
                .tint(gold)
                .frame(maxWidth: 280)
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
            .font(.title3)
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(LinearGradient(colors: [Color.white.opacity(0.075), Color.black.opacity(0.24)], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.10)))
    }'''
    )

if "UI-FIX-V3-ARTWORK-EXIT" not in text:
    replace_section(
        "struct ArtworkViewer: View {",
        "@MainActor\nfinal class VideoPlayerModel",
        r'''// UI-FIX-V3-ARTWORK-EXIT: explicit high-contrast exit plus downward swipe.
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

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: close) {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(cream)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(Color.black.opacity(0.82))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(gold, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                HStack(spacing: 16) {
                    Text(album.tracks[index].title)
                        .font(.headline)
                        .fontDesign(.serif)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.68))
                        .clipShape(Capsule())
                    Spacer()
                    Text("Swipe down to close")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.62))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .preferredColorScheme(.dark)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 35)
                .onEnded { value in
                    if value.translation.height > 90 { close() }
                }
        )
    }
}
'''
    )

if "UI-FIX-V3-AKITA-GRID" not in text:
    replace_section(
        "struct VideoAlbumView: View {",
        "private func formatTime",
        r'''// UI-FIX-V3-AKITA-GRID: real film stills, centered 3x3 magazine, unclipped titles.
struct VideoAlbumView: View {
    let album: AlbumDefinition
    @StateObject private var model: VideoPlayerModel
    private let columns = Array(repeating: GridItem(.flexible(minimum: 220, maximum: 320), spacing: 16), count: 3)

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
                    .frame(maxWidth: 980)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(18)
                    .background(Color.white.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.09)))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("\(album.title) · \(album.films.count) films")
                            .font(.title2.weight(.medium))
                            .fontDesign(.serif)

                        LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                            ForEach(Array(album.films.enumerated()), id: \.element.id) { index, film in
                                Button {
                                    model.load(index: index, autoplay: true)
                                } label: {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ZStack(alignment: .topLeading) {
                                            FilmThumbnailView(film: film)
                                                .aspectRatio(16.0 / 9.0, contentMode: .fill)
                                                .clipped()
                                            LinearGradient(
                                                colors: [Color.black.opacity(0.05), Color.clear, Color.black.opacity(0.64)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                            HStack {
                                                Text(String(format: "%02d", index + 1))
                                                    .font(.caption2.monospacedDigit().bold())
                                                    .foregroundStyle(gold)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 5)
                                                    .background(Color.black.opacity(0.74))
                                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                                Spacer()
                                                Image(systemName: index == model.currentIndex ? "play.circle.fill" : "film")
                                                    .font(.title3)
                                                    .foregroundStyle(index == model.currentIndex ? gold : Color.white.opacity(0.82))
                                            }
                                            .padding(10)
                                        }

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(film.title)
                                                .font(.headline)
                                                .fontDesign(.serif)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(minHeight: 46, alignment: .topLeading)
                                            HStack {
                                                Text("Dies Akita")
                                                Spacer()
                                                Text(film.durationLabel)
                                            }
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        }
                                        .padding(12)
                                    }
                                    .background(Color.black.opacity(0.46))
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(index == model.currentIndex ? gold.opacity(0.78) : Color.white.opacity(0.11), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: 980)
                    .frame(maxWidth: .infinity, alignment: .center)
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

'''
    )

SOURCE.write_text(text, encoding="utf-8")
print("Native UI refinements are present.")
