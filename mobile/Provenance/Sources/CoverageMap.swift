import SwiftUI

/// Positional coverage of shared passages: each document is a full-height
/// track (top = word 0, bottom = last word); amber bands mark where a
/// verbatim shared passage sits inside each document, ribboned across.
struct CoverageMap: View {
    struct Band {
        let aStart: Int
        let aEnd: Int
        let bStart: Int
        let bEnd: Int
    }

    let wordsA: Int
    let wordsB: Int
    let bands: [Band]
    var labelA: String = "A"
    var labelB: String = "B"

    @State private var t: Double = 0

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let colW: CGFloat = 14
                let ax = w * 0.18
                let bx = w * 0.82 - colW
                Canvas { ctx, _ in
                    for (x, _) in [(ax, wordsA), (bx, wordsB)] {
                        let track = Path(roundedRect: CGRect(x: x, y: 0, width: colW, height: h), cornerRadius: colW / 2)
                        ctx.fill(track, with: .color(Color.white.opacity(0.05)))
                    }
                    for band in bands {
                        let at = CGFloat(band.aStart) / CGFloat(max(wordsA, 1))
                        let ab = CGFloat(band.aEnd) / CGFloat(max(wordsA, 1))
                        let bt = CGFloat(band.bStart) / CGFloat(max(wordsB, 1))
                        let bb = CGFloat(band.bEnd) / CGFloat(max(wordsB, 1))
                        let ah = max(ab - at, 0.006) * h * t
                        let bh = max(bb - bt, 0.006) * h * t
                        let aRect = CGRect(x: ax, y: at * h, width: colW, height: ah)
                        let bRect = CGRect(x: bx, y: bt * h, width: colW, height: bh)
                        var ribbon = Path()
                        ribbon.move(to: CGPoint(x: ax + colW, y: aRect.minY))
                        ribbon.addCurve(
                            to: CGPoint(x: bx, y: bRect.minY),
                            control1: CGPoint(x: (ax + colW + bx) / 2, y: aRect.minY),
                            control2: CGPoint(x: (ax + colW + bx) / 2, y: bRect.minY))
                        ribbon.addLine(to: CGPoint(x: bx, y: bRect.maxY))
                        ribbon.addCurve(
                            to: CGPoint(x: ax + colW, y: aRect.maxY),
                            control1: CGPoint(x: (ax + colW + bx) / 2, y: bRect.maxY),
                            control2: CGPoint(x: (ax + colW + bx) / 2, y: aRect.maxY))
                        ribbon.closeSubpath()
                        ctx.fill(ribbon, with: .color(Theme.amber.opacity(0.18)))
                        ctx.fill(Path(roundedRect: aRect, cornerRadius: 3), with: .color(Theme.amber))
                        ctx.fill(Path(roundedRect: bRect, cornerRadius: 3), with: .color(Theme.amber))
                    }
                }
            }
            .frame(height: 150)
            .onAppear {
                withAnimation(.easeOut(duration: 0.9).delay(0.15)) { t = 1 }
            }
            HStack {
                Text(labelA).font(.mono(11, weight: .semibold)).foregroundStyle(Theme.secondary)
                Spacer()
                Text(labelB).font(.mono(11, weight: .semibold)).foregroundStyle(Theme.secondary)
            }
            HStack {
                Text("\(wordsA.formatted()) words").font(.mono(9)).foregroundStyle(Theme.tertiary)
                Spacer()
                Text("\(wordsB.formatted()) words").font(.mono(9)).foregroundStyle(Theme.tertiary)
            }
        }
    }
}
