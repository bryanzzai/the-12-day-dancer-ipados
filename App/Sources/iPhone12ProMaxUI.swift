import SwiftUI
import AVKit

// IPHONE12-PRO-MAX-UI
// Dedicated phone presentation for Bryan's iPhone 12 Pro Max.
// The media/catalog/player engine remains shared with the proven SideStore Lite build.
// Ordinary screens are deliberately portrait-first and capped at phone width.
// Rotation is left to iOS; Akita full-screen video can naturally use landscape.

private let phoneGold = Color(red: 0.83, green: 0.68, blue: 0.33)
private let phoneCream = Color(red: 0.96, green: 0.91, blue: 0.78)
private let phonePanel = Color(red: 0.055, green: 0.06, blue: 0.06)
private let phoneMaxWidth: CGFloat = 430

struct iPhone12ProMaxRootView: View {
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
                        colors: [Color.black.opacity(0.12), Color.black.opacity(0.10), Color.black.opacity(0.86)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 18) {
                            phoneMast
                                .padding(.top, 18)

                            Spacer(minLength: max(270, proxy.size.height * 0.39))

                            iPhoneConcertConsole(albums: concertAlbums)
                                .frame(maxWidth: phoneMaxWidth)

                            Text("Bryan MacKayne · The 12 Day Dancer")
                                .font(.caption2.weight(.semibold))
                                .tracking(1.5)
                                .foregroundStyle(Color.white.opacity(0.42))
                                .frame(maxWidth: phoneMaxWidth, alignment: .trailing)
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 22)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: proxy.size.height)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var phoneMast: some View {
        VStack(spacing: 9) {
            Text("BRYAN MACKAYNE")
                .font(.caption2.weight(.semibold))
                .tracking(4)
                .foregroundStyle(Color(red: 0.79, green: 0.69, blue: 0.52))

            Text("The 12 Day Dancer")
                .font(.system(size: 36, weight: .medium, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.93, blue: 0.69), phoneGold, Color(red: 0.61, green: 0.42, blue: 0.11)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.9), radius: 10, y: 5)
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            HStack(spacing: 10) {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, phoneGold, phoneCream], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                Image(systemName: "diamond.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(phoneGold)
                Rectangle()
                    .fill(LinearGradient(colors: [phoneCream, phoneGold, .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
            }
            .frame(maxWidth: 330)
        }
        .multilineTextAlignment(.center)
    }
}

private struct iPhoneConcertConsole: View {
    let albums: [AlbumDefinition]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SELECTIO · XII ALBUM")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.7)
                    .foregroundStyle(Color(red: 0.82, green: 0.72, blue: 0.50))
                Text("МЕХАНИЧЕН ПУЛТ · РЪЧНО УПРАВЛЕНИЕ")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(Color(red: 0.54, green: 0.49, blue: 0.39))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.black.opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 7))

            if albums.isEmpty {
                Text("Catalog not generated")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(36)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(albums) { album in
                        NavigationLink {
                            iPhoneAlbumDestinationView(album: album)
                        } label: {
                            iPhoneAlbumButton(album: album)
                        }
                        .buttonStyle(iPhoneMechanicalPressStyle())
                    }
                }
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(red: 0.28, green: 0.29, blue: 0.28), Color(red: 0.06, green: 0.07, blue: 0.07), Color(red: 0.19, green: 0.20, blue: 0.19)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.86), radius: 22, y: 14)
    }
}

private struct iPhoneMechanicalPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 5 : 0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.07), value: configuration.isPressed)
    }
}

private struct iPhoneAlbumButton: View {
    let album: AlbumDefinition

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .leading) {
                    LocalResourceImage(resource: album.bannerResource)
                        .scaledToFill()
                    LinearGradient(
                        colors: [Color.black.opacity(0.28), .clear, Color.black.opacity(0.42)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    LocalResourceImage(resource: album.portraitResource)
                        .scaledToFill()
                        .frame(width: 62)
                        .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .leading, endPoint: .trailing))
                }
                .frame(height: 92)
                .clipped()

                Text(album.roman)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(0.8)
                    .foregroundStyle(Color(red: 0.93, green: 0.83, blue: 0.57))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(7)
            }

            Text(album.title)
                .font(.system(size: 12, weight: .heavy))
                .tracking(0.7)
                .textCase(.uppercase)
                .foregroundStyle(Color(red: 0.94, green: 0.86, blue: 0.66))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 5)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.18, green: 0.14, blue: 0.09), Color(red: 0.05, green: 0.04, blue: 0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(red: 0.58, green: 0.45, blue: 0.24), lineWidth: 1.5))
        .contentShape(Rectangle())
    }
}

private struct iPhoneAlbumDestinationView: View {
    let album: AlbumDefinition

    var body: some View {
        switch album.kind {
        case .audio:
            iPhoneAudioAlbumView(album: album)
        case .video:
            iPhoneVideoAlbumView(album: album)
        }
    }
}

private struct iPhoneAlbumHeroView: View {
    let album: AlbumDefinition

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LocalResourceImage(resource: album.bannerResource)
                .scaledToFill()
                .frame(height: 220)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.18), Color.black.opacity(0.20), Color.black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)

            LocalResourceImage(resource: album.portraitResource)
                .scaledToFill()
                .frame(width: 126, height: 220)
                .clipped()
                .mask(LinearGradient(colors: [.black, .black, .clear], startPoint: .leading, endPoint: .trailing))

            VStack(alignment: .leading, spacing: 4) {
                Text("BRYAN MACKAYNE")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2.2)
                    .foregroundStyle(phoneGold)
                Text(album.title)
                    .font(.system(size: 32, weight: .medium, design: .serif))
                    .foregroundStyle(phoneCream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                Text(album.subtitle)
                    .font(.subheadline.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.white.opacity(0.86))
                    .lineLimit(2)
                Text(album.description)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(3)
            }
            .padding(.leading, 112)
            .padding(.trailing, 14)
            .padding(.bottom, 14)
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

private struct iPhoneAudioAlbumView: View {
    let album: AlbumDefinition
    @StateObject private var model: AudioPlayerModel
    @State private var searchText = ""
    @State private var artworkIndex: Int?

    init(album: AlbumDefinition) {
        self.album = album
        _model = StateObject(wrappedValue: AudioPlayerModel(album: album))
    }

    private var filteredIndices: [Int] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return Array(album.tracks.indices) }
        return album.tracks.indices.filter { album.tracks[$0].title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                iPhoneAlbumHeroView(album: album)

                if !album.tracks.isEmpty {
                    nowPlayingPanel
                    library
                }
            }
            .frame(maxWidth: phoneMaxWidth)
            .padding(.horizontal, 10)
            .padding(.bottom, 54)
            .frame(maxWidth: .infinity)
        }
        .background(
            RadialGradient(
                colors: [Color(red: 0.09, green: 0.12, blue: 0.17), Color.black],
                center: .topLeading,
                startRadius: 20,
                endRadius: 760
            )
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
                iPhoneArtworkViewer(
                    album: album,
                    index: Binding(
                        get: { artworkIndex ?? index },
                        set: { artworkIndex = $0 }
                    )
                ) {
                    artworkIndex = nil
                }
            }
        }
    }

    private var nowPlayingPanel: some View {
        VStack(spacing: 16) {
            Button {
                artworkIndex = model.currentIndex
            } label: {
                LocalResourceImage(resource: album.tracks[model.currentIndex].artworkResource, contentMode: .fill)
                    .scaledToFill()
                    .frame(width: 278, height: 278)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.16)))
                    .shadow(color: .black.opacity(0.58), radius: 16, y: 8)
            }
            .buttonStyle(.plain)

            VStack(spacing: 5) {
                Text("NOW PLAYING")
                    .font(.caption2.weight(.bold))
                    .tracking(2.2)
                    .foregroundStyle(phoneGold)
                Text(album.tracks[model.currentIndex].title)
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(phoneCream)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(model.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 6) {
                Slider(
                    value: Binding(get: { model.currentTime }, set: { model.seek($0) }),
                    in: 0...max(model.duration, 1)
                )
                .tint(phoneGold)

                HStack {
                    Text(formatIPhoneTime(model.currentTime))
                    Spacer()
                    Text(formatIPhoneTime(model.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 18) {
                Button { model.shuffle.toggle() } label: {
                    Image(systemName: "shuffle")
                        .foregroundStyle(model.shuffle ? phoneGold : Color.white.opacity(0.72))
                        .frame(width: 44, height: 44)
                }
                Button(action: model.previous) {
                    Image(systemName: "backward.end.fill")
                        .frame(width: 48, height: 48)
                }
                Button(action: model.togglePlay) {
                    Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 62))
                        .frame(width: 68, height: 68)
                }
                Button(action: model.next) {
                    Image(systemName: "forward.end.fill")
                        .frame(width: 48, height: 48)
                }
                Button { model.repeatOne.toggle() } label: {
                    Image(systemName: "repeat.1")
                        .foregroundStyle(model.repeatOne ? phoneGold : Color.white.opacity(0.72))
                        .frame(width: 44, height: 44)
                }
            }
            .font(.title3)
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                Slider(
                    value: Binding(get: { model.volume }, set: { model.setVolume($0) }),
                    in: 0...1
                )
                .tint(phoneGold)
                Image(systemName: "speaker.wave.3.fill")
            }
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.075), Color.black.opacity(0.28)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.10)))
    }

    private var library: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(album.title) · \(album.tracks.count) tracks")
                        .font(.title3.weight(.medium))
                        .fontDesign(.serif)
                    Text("Local native library")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search the album…", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 13)
                .frame(height: 46)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12)))
            }
            .padding(16)

            Divider().overlay(Color.white.opacity(0.10))

            LazyVStack(spacing: 0) {
                ForEach(filteredIndices, id: \.self) { index in
                    iPhoneTrackRow(
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
        .background(Color.black.opacity(0.44))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.08)))
    }
}

private struct iPhoneTrackRow: View {
    let album: AlbumDefinition
    let track: TrackDefinition
    let index: Int
    let isCurrent: Bool
    let isPlaying: Bool
    let selectTrack: () -> Void
    let showArtwork: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            Text(String(format: "%02d", index + 1))
                .font(.caption.monospacedDigit())
                .foregroundStyle(isCurrent ? phoneGold : Color.secondary)
                .frame(width: 28, alignment: .leading)

            Button(action: selectTrack) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.body.weight(.semibold))
                            .fontDesign(.serif)
                            .foregroundStyle(phoneCream)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text("Bryan MacKayne")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    if isCurrent {
                        Image(systemName: isPlaying ? "speaker.wave.2.fill" : "music.note")
                            .foregroundStyle(phoneGold)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: showArtwork) {
                LocalResourceImage(resource: track.artworkResource, contentMode: .fill)
                    .scaledToFill()
                    .frame(width: 66, height: 66)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.13)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(isCurrent ? Color.white.opacity(0.06) : Color.clear)
    }
}

private struct iPhoneArtworkViewer: View {
    let album: AlbumDefinition
    @Binding var index: Int
    let close: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LocalResourceImage(resource: album.tracks[index].artworkResource, contentMode: .fill)
                .scaledToFill()
                .blur(radius: 30)
                .brightness(-0.22)
                .scaleEffect(1.12)
                .ignoresSafeArea()

            Color.black.opacity(0.34).ignoresSafeArea()

            LocalResourceImage(resource: album.tracks[index].artworkResource, contentMode: .fit)
                .scaledToFit()
                .padding(.horizontal, 18)
                .padding(.vertical, 80)
                .shadow(color: .black.opacity(0.85), radius: 28, y: 14)

            VStack {
                HStack {
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                HStack(spacing: 22) {
                    Button {
                        index = (index - 1 + album.tracks.count) % album.tracks.count
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .frame(width: 58, height: 52)
                    }
                    Spacer()
                    Text(album.tracks[index].title)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        index = (index + 1) % album.tracks.count
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24, weight: .bold))
                            .frame(width: 58, height: 52)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(14)
        }
        .preferredColorScheme(.dark)
        .gesture(
            DragGesture(minimumDistance: 35)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    if abs(dx) > abs(dy), abs(dx) > 70 {
                        if dx < 0 {
                            index = (index + 1) % album.tracks.count
                        } else {
                            index = (index - 1 + album.tracks.count) % album.tracks.count
                        }
                    } else if dy > 90 {
                        close()
                    }
                }
        )
    }
}

private struct iPhoneVideoAlbumView: View {
    let album: AlbumDefinition
    @StateObject private var model: VideoPlayerModel
    @State private var showFullScreen = false

    init(album: AlbumDefinition) {
        self.album = album
        _model = StateObject(wrappedValue: VideoPlayerModel(album: album))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                iPhoneAlbumHeroView(album: album)

                if !album.films.isEmpty {
                    cinemaPanel
                    filmLibrary
                }
            }
            .frame(maxWidth: phoneMaxWidth)
            .padding(.horizontal, 10)
            .padding(.bottom, 54)
            .frame(maxWidth: .infinity)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onDisappear { model.stop() }
        .fullScreenCover(isPresented: $showFullScreen) {
            iPhoneFullScreenVideoView(player: model.player) {
                showFullScreen = false
            }
        }
    }

    private var currentFilm: FilmDefinition {
        album.films[model.currentIndex]
    }

    private var cinemaPanel: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                VideoPlayer(player: model.player)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12)))

                Button {
                    showFullScreen = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 48, height: 46)
                        .foregroundStyle(.white)
                        .background(Color.black.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(9)
            }

            VStack(spacing: 5) {
                Text("NOW SHOWING")
                    .font(.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(phoneGold)
                Text(currentFilm.title)
                    .font(.title3.weight(.semibold))
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text("Film \(model.currentIndex + 1) of \(album.films.count) · \(currentFilm.durationLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button { model.previous() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "backward.end.fill")
                        Text("Previous")
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                Button { model.restart() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Replay")
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                Button { model.next() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "forward.end.fill")
                        Text("Next")
                            .font(.caption2.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.white.opacity(0.12))
        }
        .padding(14)
        .background(Color.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.09)))
    }

    private var filmLibrary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(album.title) · \(album.films.count) films")
                .font(.title3.weight(.medium))
                .fontDesign(.serif)

            LazyVStack(spacing: 13) {
                ForEach(Array(album.films.enumerated()), id: \.element.id) { index, film in
                    Button {
                        model.load(index: index, autoplay: true)
                    } label: {
                        iPhoneFilmCard(
                            film: film,
                            index: index,
                            isCurrent: index == model.currentIndex
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color.black.opacity(0.40))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08)))
    }
}

private struct iPhoneFilmCard: View {
    let film: FilmDefinition
    let index: Int
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                FilmThumbnailView(film: film)
                    .aspectRatio(16.0 / 9.0, contentMode: .fill)
                    .clipped()

                LinearGradient(
                    colors: [Color.black.opacity(0.02), Color.clear, Color.black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack {
                    Text(String(format: "%02d", index + 1))
                        .font(.caption2.monospacedDigit().bold())
                        .foregroundStyle(phoneGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    Spacer()
                    Image(systemName: isCurrent ? "play.circle.fill" : "film")
                        .font(.title3)
                        .foregroundStyle(isCurrent ? phoneGold : Color.white.opacity(0.84))
                }
                .padding(10)
            }
            .frame(height: 205)
            .clipped()

            HStack(alignment: .center, spacing: 10) {
                Text(film.title)
                    .font(.body.weight(.semibold))
                    .fontDesign(.serif)
                    .foregroundStyle(phoneCream)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Spacer()
                Text(film.durationLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minHeight: 54)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isCurrent ? phoneGold.opacity(0.78) : Color.white.opacity(0.11), lineWidth: 1)
        )
    }
}

private struct iPhoneFullScreenVideoView: View {
    let player: AVPlayer
    let close: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: player)
                .ignoresSafeArea()

            Button(action: close) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .shadow(radius: 8)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .preferredColorScheme(.dark)
    }
}

private func formatIPhoneTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let value = Int(seconds.rounded(.down))
    return "\(value / 60):\(String(format: "%02d", value % 60))"
}
