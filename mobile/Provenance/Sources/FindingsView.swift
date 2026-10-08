import SwiftUI

struct FindingsView: View {
    @EnvironmentObject private var store: CorpusStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 24)
                        .appear(0)

                    Rule()
                    MetricsRow([
                        ("\(store.bills.count)", "Bills", Theme.text),
                        ("\(store.lineage.pairs.count)", "Pairs read", Theme.text),
                        ("\(store.clusters().count)", "Clusters", store.clusters().isEmpty ? Theme.text : Theme.amber),
                    ])
                    Rule()
                        .padding(.bottom, 28)
                        .appear(1)

                    corpusMap
                        .padding(.bottom, 32)
                        .appear(2)

                    findingsSection
                        .appear(3)

                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Legislative lineage • Live corpus")
            Text("Who wrote\nthis law?")
                .font(.display(44, weight: .bold))
                .tracking(-1.2)
                .foregroundStyle(Theme.text)
                .lineSpacing(-2)

        }
    }

    // MARK: - Corpus map

    private var corpusMap: some View {
        VStack(alignment: .leading, spacing: 18) {
            Eyebrow("Corpus map")
            SimilarityMatrix(bills: store.bills, pairs: store.lineage.pairs)
            HStack(spacing: 18) {
                legendMark("Linked pair — tap a cell", amber: true)
                legendMark("Below threshold", amber: false)
            }
        }
    }

    private func legendMark(_ label: String, amber: Bool) -> some View {
        HStack(spacing: 7) {
            if amber {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Theme.amber)
                    .frame(width: 10, height: 10)
            } else {
                Circle()
                    .fill(Theme.tertiary)
                    .frame(width: 4, height: 4)
                    .padding(3)
            }
            Text(label)
                .font(.mono(10))
                .foregroundStyle(Theme.tertiary)
        }
    }

    // MARK: - Findings

    private var findingsSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            Eyebrow(store.findings.count == 1 ? "1 finding" : "\(store.findings.count) findings")
            ForEach(Array(store.findings.enumerated()), id: \.element.id) { index, finding in
                if let pair = store.pair(for: finding) {
                    NavigationLink(value: pair) {
                        FindingEntry(index: index + 1, finding: finding, pair: pair)
                            .environmentObject(store)
                    }
                    .buttonStyle(CardButtonStyle())
                }
            }
        }
        .navigationDestination(for: Pair.self) { pair in
            PairDetailView(pair: pair)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Rule()
            HStack {
                Text("PROVENANCE")
                    .font(.mono(10, weight: .bold)).tracking(2)
                    .foregroundStyle(Theme.tertiary)
                Spacer()
                if let date = store.manifest.runDate {
                    Text("Corpus built \(date.formatted(.dateTime.month(.abbreviated).day().year()))")
                        .font(.mono(10))
                        .foregroundStyle(Theme.tertiary)
                }
            }
        }
        .padding(.top, 36)
    }
}

// MARK: - Finding entry — an editorial line item, not a card

struct FindingEntry: View {
    let index: Int
    let finding: Finding
    let pair: Pair
    @EnvironmentObject private var store: CorpusStore

    /// containment_a_to_b = share of A's shingles found inside B.
    private var direction: (from: Bill?, to: Bill?, share: Double) {
        if pair.containment_a_to_b >= pair.containment_b_to_a {
            return (store.bill(pair.a), store.bill(pair.b), pair.containment_a_to_b)
        }
        return (store.bill(pair.b), store.bill(pair.a), pair.containment_b_to_a)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("Finding \(String(format: "%02d", index))", color: Theme.amber)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
            }

            Text(finding.title)
                .font(.display(24, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)

            if let a = store.bill(pair.a), let b = store.bill(pair.b) {
                HStack(spacing: 12) {
                    billRef(a)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.tertiary)
                    billRef(b)
                }
            }

            let d = direction
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    CountUp(d.share * 100, format: { "\(Int($0.rounded()))%" })
                        .font(.mono(22, weight: .bold))
                        .foregroundStyle(Theme.amber)
                    Spacer()
                    Text("\(d.from?.number ?? "?") ⊂ \(d.to?.number ?? "?")")
                        .font(.mono(11))
                        .foregroundStyle(Theme.tertiary)
                }
                ContainmentBar(value: d.share)
            }

            DocumentExcerpt(evidence: finding.top_evidence_passage, collapsed: true)
        }
        .padding(.top, 4)
        .padding(.bottom, 18)
        .overlay(alignment: .bottom) { Rule() }
    }

    private func billRef(_ bill: Bill) -> some View {
        HStack(spacing: 8) {
            JurisdictionSeal(code: bill.jurisdiction, size: 26)
            Text(bill.number)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Theme.text)
            Text(bill.session)
                .font(.mono(10))
                .foregroundStyle(Theme.tertiary)
        }
    }
}

// MARK: - Document excerpt — shared passage rendered as evidence

struct DocumentExcerpt: View {
    let evidence: Evidence
    var collapsed: Bool = false
    var billA: String? = nil
    var billB: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow("Verbatim match", color: Theme.amberDeep)
                Spacer()
                Text("\(evidence.word_count) words")
                    .font(.mono(10, weight: .semibold))
                    .foregroundStyle(Theme.amber)
            }
            Text(evidence.text)
                .font(.mono(11.5))
                .foregroundStyle(Theme.text.opacity(0.85))
                .lineSpacing(5)
                .lineLimit(collapsed ? 4 : nil)
                .truncationMode(.tail)
                .textSelection(.enabled)
            if let billA, let billB {
                HStack(spacing: 14) {
                    offset(billA, evidence.a_start, evidence.a_end)
                    offset(billB, evidence.b_start, evidence.b_end)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.amberSoft.opacity(0.5))
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.amber.opacity(0.7)).frame(width: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.amber.opacity(0.22)))
    }

    private func offset(_ bill: String, _ start: Int, _ end: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "bookmark.fill").font(.system(size: 8)).foregroundStyle(Theme.amberDeep)
            Text("\(bill) w.\(start)–\(end)")
                .font(.mono(9.5))
                .foregroundStyle(Theme.secondary)
        }
    }
}

// MARK: - Similarity matrix

struct SimilarityMatrix: View {
    let bills: [Bill]
    let pairs: [Pair]
    private let cellGap: CGFloat = 3

    private func score(_ a: String, _ b: String) -> Double {
        pairs.first { ($0.a == a && $0.b == b) || ($0.a == b && $0.b == a) }?.maxContainment ?? 0
    }

    var body: some View {
        let n = bills.count
        VStack(spacing: 10) {
            HStack(spacing: cellGap) {
                Text("").frame(width: 26)
                ForEach(bills) { bill in
                    Text(shortLabel(bill))
                        .font(.mono(8.5, weight: .medium))
                        .foregroundStyle(Theme.tertiary)
                        .frame(width: 28)
                        .rotationEffect(.degrees(-45))
                        .frame(height: 30)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(0..<n, id: \.self) { row in
                HStack(spacing: cellGap) {
                    Text(shortLabel(bills[row]))
                        .font(.mono(8.5, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 26, alignment: .trailing)
                    ForEach(0..<n, id: \.self) { col in
                        cell(row: row, col: col)
                    }
                }
            }
        }
    }

    private func pairFor(row: Int, col: Int) -> Pair? {
        pairs.first { ($0.a == bills[row].id && $0.b == bills[col].id) || ($0.a == bills[col].id && $0.b == bills[row].id) }
    }

    private func cell(row: Int, col: Int) -> some View {
        let diagonal = row == col
        let s = diagonal ? 0 : score(bills[row].id, bills[col].id)
        let linked = !diagonal && s >= 0.15
        let tile = RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(diagonal ? Color.white.opacity(0.015) : color(for: s, linked: linked))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(linked ? Theme.amber.opacity(0.6) : Theme.hairline.opacity(0.4), lineWidth: linked ? 1 : 0.5)
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if linked {
                    Text("\(Int((s * 100).rounded()))")
                        .font(.mono(9, weight: .bold))
                        .foregroundStyle(Theme.amber)
                } else if s > 0 {
                    Circle()
                        .fill(Theme.tertiary)
                        .frame(width: 3, height: 3)
                }
            }
        if linked, let pair = pairFor(row: row, col: col) {
            return AnyView(NavigationLink(value: pair) { tile }.buttonStyle(.plain))
        }
        return AnyView(tile)
    }

    private func color(for score: Double, linked: Bool) -> Color {
        if linked { return Theme.amber.opacity(0.16 + score * 1.7) }
        return Color.white.opacity(0.04)
    }

    private func shortLabel(_ bill: Bill) -> String {
        bill.number
            .replacingOccurrences(of: "AB ", with: "")
            .replacingOccurrences(of: "HB ", with: "")
            .replacingOccurrences(of: "SB ", with: "")
            .replacingOccurrences(of: "HF ", with: "")
            .replacingOccurrences(of: "SB24-", with: "")
            .replacingOccurrences(of: "S.", with: "")
            .replacingOccurrences(of: "2023 Act ", with: "A")
    }
}
