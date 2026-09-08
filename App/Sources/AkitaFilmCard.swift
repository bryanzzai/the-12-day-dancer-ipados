import SwiftUI

struct AkitaFilmCard: View {
    let film: FilmDefinition
    let index: Int
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                thumbnail
                metadata
            }
            .background(Color.black.opacity(0.46))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isCurrent ? Color(red: 0.83, green: 0.68, blue: 0.33).opacity(0.78) : Color.white.opacity(0.11), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var thumbnail: some View {
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
                    .foregroundStyle(Color(red: 0.83, green: 0.68, blue: 0.33))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.74))
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Spacer()

                Image(systemName: isCurrent ? "play.circle.fill" : "film")
                    .font(.title3)
                    .foregroundStyle(isCurrent ? Color(red: 0.83, green: 0.68, blue: 0.33) : Color.white.opacity(0.82))
            }
            .padding(10)
        }
    }

    private var metadata: some View {
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
}
