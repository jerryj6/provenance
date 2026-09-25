import SwiftUI

enum Theme {
    /// Deep ink canvas — warmer than pure black, cool enough to feel forensic.
    static let canvas = Color(red: 0.035, green: 0.041, blue: 0.055)
    static let surface = Color(red: 0.075, green: 0.086, blue: 0.110)
    static let surfaceRaised = Color(red: 0.098, green: 0.112, blue: 0.140)
    static let hairline = Color.white.opacity(0.09)
    static let hairlineStrong = Color.white.opacity(0.16)

    static let text = Color.white.opacity(0.94)
    static let secondary = Color.white.opacity(0.58)
    static let tertiary = Color.white.opacity(0.34)

    /// Highlighter amber — the mark of found copied text.
    static let amber = Color(red: 0.949, green: 0.702, blue: 0.212)
    static let amberDeep = Color(red: 0.820, green: 0.580, blue: 0.130)
    static let amberSoft = Color(red: 0.949, green: 0.702, blue: 0.212).opacity(0.14)

    /// Slate-blue for secondary/jurisdictional accents.
    static let slate = Color(red: 0.490, green: 0.584, blue: 0.776)
    static let slateSoft = Color(red: 0.490, green: 0.584, blue: 0.776).opacity(0.14)
}

extension Font {
    /// Monumental display serif — editorial, legal gravitas (New York).
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func bodySerif(_ size: CGFloat = 17, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func mono(_ size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// Small uppercase tracking label — the "desk stamp" of the design system.
struct Eyebrow: View {
    let text: String
    var color: Color = Theme.secondary

    init(_ text: String, color: Color = Theme.secondary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(.mono(10.5, weight: .semibold))
            .tracking(1.8)
            .foregroundStyle(color)
    }
}

/// Rounded jurisdiction seal — like a postal postmark stamp.
struct JurisdictionSeal: View {
    let code: String
    var size: CGFloat = 34
    var accent: Color = Theme.amber

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Theme.surfaceRaised)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .strokeBorder(Theme.hairlineStrong, lineWidth: 1)
                )
            Text(code)
                .font(.mono(size * 0.34, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
    }
}

/// A stat tile — mono value over uppercase label.
struct StatTile: View {
    let value: String
    let label: String
    var accent: Color = Theme.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.mono(20, weight: .semibold))
                .foregroundStyle(accent)
                .monospacedDigit()
            Eyebrow(label)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }
}

/// Thin progress track used for containment scores. Fills on appear — data drawing itself.
struct ContainmentBar: View {
    let value: Double      // 0...1
    var color: Color = Theme.amber
    var height: CGFloat = 4
    @State private var fill: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.75)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geo.size.width * min(max(fill, 0), 1)))
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { fill = value }
        }
    }
}

/// Pressed-card feedback — scale 0.98 + soften, per iOS press conventions.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Small pill for topic tags.
struct TopicTag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.mono(10.5, weight: .medium))
            .foregroundStyle(Theme.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Theme.slateSoft)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Theme.slate.opacity(0.25), lineWidth: 0.5))
    }
}
