#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "App" / "Sources" / "The12DayDancerApp.swift"
text = source.read_text(encoding="utf-8")

start_marker = "// UI-FIX-V3-AKITA-GRID:"
end_marker = "private func formatTime"
start = text.find(start_marker)
if start < 0:
    raise SystemExit("Video simplifier: Akita UI marker not found")
end = text.find(end_marker, start)
if end < 0:
    raise SystemExit("Video simplifier: formatTime marker not found")

replacement = r'''// UI-FIX-V3-AKITA-GRID: real film stills, centered 3x3 magazine, unclipped titles.
// UI-FIX-V4-SPLIT: keep the SwiftUI type graph small enough for Xcode 15/16 compilers.
struct VideoAlbumView: View {
    let album: AlbumDefinition
    @StateObject private var model: VideoPlayerModel

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 220, maximum: 320), spacing: 16),
        count: 3
    )

    init(album: AlbumDefinition) {
        self.album = album
        _model = StateObject(wrappedValue: VideoPlayerModel(album: album))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                AlbumHeroView(album: album)
                if !album.films.isEmpty {
                    cinemaPanel
                    filmLibrary
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

    private var cinemaPanel: some View {
        VStack(spacing: 14) {
            VideoPlayer(player: model.player)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12))
                )

            nowShowingBar
        }
        .padding(18)
        .frame(maxWidth: 980)
        .background(Color.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.09))
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var nowShowingBar: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("NOW SHOWING")
                    .font(.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(gold)

                Text(currentFilm.title)
                    .font(.title2.weight(.semibold))
                    .fontDesign(.serif)

                Text("Film \(model.currentIndex + 1) of \(album.films.count) · \(currentFilm.durationLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                Button(action: model.previous) {
                    Image(systemName: "backward.end.fill")
                }
                Button(action: model.restart) {
                    Image(systemName: "arrow.counterclockwise")
                }
                Button {
                    model.next()
                } label: {
                    Image(systemName: "forward.end.fill")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 4)
    }

    private var currentFilm: FilmDefinition {
        album.films[model.currentIndex]
    }

    private var filmLibrary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(album.title) · \(album.films.count) films")
                .font(.title2.weight(.medium))
                .fontDesign(.serif)

            LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                ForEach(album.films.indices, id: \.self) { index in
                    AkitaFilmCard(
                        film: album.films[index],
                        index: index,
                        isCurrent: index == model.currentIndex,
                        action: { model.load(index: index, autoplay: true) }
                    )
                }
            }
        }
        .padding(18)
        .frame(maxWidth: 980)
        .background(Color.black.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

'''

text = text[:start] + replacement + text[end:]
source.write_text(text, encoding="utf-8")
print("Akita video UI split into compiler-friendly subviews.")
