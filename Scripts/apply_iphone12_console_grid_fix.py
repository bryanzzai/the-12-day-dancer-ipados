#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "App" / "Sources" / "iPhone12ProMaxUI.swift"

text = SOURCE.read_text(encoding="utf-8")
marker = "IPHONE12-PRO-MAX-CONSOLE-GRID-FIX"

if marker in text:
    print("iPhone 12 Pro Max console grid fix already applied.")
    raise SystemExit(0)

old_columns = '''private struct iPhoneConcertConsole: View {
    let albums: [AlbumDefinition]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
'''
new_columns = '''private struct iPhoneConcertConsole: View {
    let albums: [AlbumDefinition]
    // IPHONE12-PRO-MAX-CONSOLE-GRID-FIX
    // Dedicated 12 Pro Max portrait geometry: two equal 187 pt columns plus 10 pt gutter.
    // The fixed geometry prevents image intrinsic sizes from pushing the left column off-center.
    private let columns = Array(repeating: GridItem(.fixed(187), spacing: 10), count: 2)
'''
if old_columns not in text:
    raise SystemExit("Expected flexible iPhone console columns not found; refusing to patch.")
text = text.replace(old_columns, new_columns, 1)

old_visual = '''            ZStack(alignment: .topLeading) {
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
'''
new_visual = '''            ZStack(alignment: .topLeading) {
                ZStack {
                    LocalResourceImage(resource: album.bannerResource)
                        .scaledToFill()
                        .frame(width: 187, height: 92)
                        .clipped()
                    LinearGradient(
                        colors: [Color.black.opacity(0.14), .clear, Color.black.opacity(0.28)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .frame(width: 187, height: 92)
                .clipped()
'''
if old_visual not in text:
    raise SystemExit("Expected iPhone banner/portrait button visual not found; refusing to patch.")
text = text.replace(old_visual, new_visual, 1)

old_title = '''                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 5)
                .background(
'''
new_title = '''                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .padding(.horizontal, 5)
                .frame(width: 187, minHeight: 44)
                .background(
'''
if old_title not in text:
    raise SystemExit("Expected iPhone album-title sizing block not found; refusing to patch.")
text = text.replace(old_title, new_title, 1)

old_card_end = '''        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(red: 0.58, green: 0.45, blue: 0.24), lineWidth: 1.5))
        .contentShape(Rectangle())
    }
}

private struct iPhoneAlbumDestinationView'''
new_card_end = '''        }
        .frame(width: 187)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color(red: 0.58, green: 0.45, blue: 0.24), lineWidth: 1.5))
        .contentShape(Rectangle())
    }
}

private struct iPhoneAlbumDestinationView'''
if old_card_end not in text:
    raise SystemExit("Expected iPhone album-card ending not found; refusing to patch.")
text = text.replace(old_card_end, new_card_end, 1)

SOURCE.write_text(text, encoding="utf-8")
print("Applied iPhone 12 Pro Max fixed two-column console grid; removed portrait overlays from buttons.")
