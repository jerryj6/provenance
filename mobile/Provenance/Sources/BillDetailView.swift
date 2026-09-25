import SwiftUI

struct BillDetailView: View {
    let bill: Bill
    @EnvironmentObject private var store: CorpusStore
    @EnvironmentObject private var router: AppRouter

    private var linkedPairs: [Pair] {
        store.pairs(involving: bill.id).filter(\.isLinked)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 24)
                    .appear(0)

                Rule()
                MetricsRow([
                    (bill.word_count.formatted(), "Words", Theme.text),
                    ("\(bill.topics.count)", "Topics", Theme.text),
                    (bill.jurisdiction, "Region", Theme.text),
                ])
                Rule()
                    .padding(.bottom, 28)
                    .appear(1)

                lineageSection
                    .padding(.bottom, 30)
                    .appear(2)

                sourceSection
                    .appear(3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Pair.self) { pair in
            PairDetailView(pair: pair)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                JurisdictionSeal(code: bill.jurisdiction, size: 56)
                Spacer()
                Text(bill.session)
                    .font(.mono(12, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                    .padding(.top, 4)
            }
            Text(bill.number)
                .font(.display(40, weight: .bold))
                .tracking(-1)
                .foregroundStyle(Theme.text)
            Text(bill.title)
                .font(.bodySerif(17))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            if !bill.topics.isEmpty {
                FlowLayout(spacing: 7) {
                    ForEach(bill.topics, id: \.self) { topic in
                        TopicTag(text: topic)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private var lineageSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Lineage")
                .padding(.bottom, 12)

            if linkedPairs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.secondary)
                    Text("No shared text detected")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Text("This bill shares fewer than 15% of its 8-word shingles with any other bill in the corpus — its language is its own.")
                        .font(.bodySerif(13.5))
                        .foregroundStyle(Theme.secondary)
                        .lineSpacing(4)
                }
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) { Rule() }
            } else {
                ForEach(linkedPairs) { pair in
                    let otherID = pair.a == bill.id ? pair.b : pair.a
                    if let other = store.bill(otherID) {
                        NavigationLink(value: pair) {
                            HStack(spacing: 14) {
                                JurisdictionSeal(code: other.jurisdiction, size: 38)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Shares text with \(other.number)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.text)
                                    Text(other.title)
                                        .font(.bodySerif(12.5))
                                        .foregroundStyle(Theme.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Text("\(Int((pair.maxContainment * 100).rounded()))%")
                                    .font(.mono(16, weight: .bold))
                                    .foregroundStyle(Theme.amber)
                                    .monospacedDigit()
                            }
                            .padding(.vertical, 13)
                            .overlay(alignment: .bottom) { Rule() }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Button {
                router.compareSeed = bill
                router.tab = 2
            } label: {
                HStack(spacing: 10) {
                    Text("Compare against another document")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(Theme.secondary)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                }
                .padding(.vertical, 13)
                .overlay(alignment: .bottom) { Rule() }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Official source")
                .padding(.bottom, 10)
            if let url = URL(string: bill.url) {
                Link(destination: url) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.tertiary)
                        Text(url.host ?? bill.url)
                            .font(.mono(11.5))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.tertiary)
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) { Rule() }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("SHA-256")
                    .font(.mono(9.5, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
                Text(bill.text_sha256)
                    .font(.mono(10))
                    .foregroundStyle(Theme.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 12)
        }
    }
}

/// Minimal wrapping layout for the topic pills.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
