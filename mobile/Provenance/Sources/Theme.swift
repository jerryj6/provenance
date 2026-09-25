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

    /// Highlighter amber — spent only on shared-text signal, never decoration.
    static let amber = Color(red: 0.949, green: 0.702, blue: 0.212)
    static let amberDeep = Color(red: 0.820, green: 0.580, blue: 0.130)
    static let amberSoft = Color(red: 0.949, green: 0.702, blue: 0.212).opacity(0.14)
}

/// 1pt section rule — the primary chrome of the report layout.
struct Rule: View {
    var body: some View {
        Rectangle().fill(Theme.hairline).frame(height: 1)
    }
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

/// Outlined jurisdiction mark — neutral postmark, never an accent.
struct JurisdictionSeal: View {
    let code: String
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .strokeBorder(Theme.hairlineStrong, lineWidth: 1)
            Text(code)
                .font(.mono(size * 0.32, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Theme.secondary)
        }
        .frame(width: size, height: size)
    }
}

/// Flat metric column — value over label, divided by hairlines, no chrome.
struct MetricColumn: View {
    let value: String
    let label: String
    var accent: Color = Theme.text

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.mono(18, weight: .semibold))
                .foregroundStyle(accent)
                .monospacedDigit()
            Eyebrow(label, color: Theme.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A row of metrics separated by thin vertical rules.
struct MetricsRow: View {
    let items: [(value: String, label: String, accent: Color)]

    init(_ items: [(String, String, Color)] = []) {
        self.items = items
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                if i > 0 {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 1)
                        .padding(.vertical, 4)
                }
                MetricColumn(value: item.value, label: item.label, accent: item.accent)
                    .padding(.leading, i == 0 ? 0 : 18)
            }
        }
        .padding(.vertical, 16)
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

/// Staggered entrance — rise 10pt + fade, delayed by index. One modifier,
/// applied top-to-bottom so a screen assembles itself like a readout powering on.
struct Appear: ViewModifier {
    let index: Int
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .opacity(on ? 1 : 0)
            .offset(y: on ? 0 : 10)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.05 * Double(index))) { on = true }
            }
    }
}

extension View {
    func appear(_ index: Int) -> some View { modifier(Appear(index: index)) }
}

/// Number that eases 0→target on appear — the command-console counter.
struct CountUp: View {
    let value: Double
    var format: (Double) -> String
    @State private var t: Double = 0

    init(_ value: Double, format: @escaping (Double) -> String = { String(Int($0.rounded())) }) {
        self.value = value
        self.format = format
    }

    var body: some View {
        Text(format(value * t))
            .monospacedDigit()
            .onAppear {
                withAnimation(.easeOut(duration: 0.9)) { t = 1 }
            }
    }
}

/// Small hairline pill for topic tags — neutral, structural.
struct TopicTag: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.mono(10.5, weight: .medium))
            .foregroundStyle(Theme.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .overlay(Capsule().strokeBorder(Theme.hairlineStrong, lineWidth: 1))
    }
}
