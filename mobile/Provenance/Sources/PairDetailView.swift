import SwiftUI

struct PairDetailView: View {
    let pair: Pair
    @EnvironmentObject private var store: CorpusStore

    var body: some View {
        let a = store.bill(pair.a)
        let b = store.bill(pair.b)

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let a, let b {
                    versusHeader(a: a, b: b)
                }

                containmentSection(a: a, b: b)

                metricsStrip

                evidenceSection(a: a, b: b)

                caveat

                sourcesSection(a: a, b: b)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow("Pair analysis")
            }
        }
    }

    private func versusHeader(a: Bill, b: Bill) -> some View {
        VStack(spacing: 0) {
            billBlock(a)
            HStack(spacing: 12) {
                Rectangle().fill(Theme.hairline).frame(height: 1)
                ZStack {
                    Circle()
                        .fill(Theme.amber)
                        .frame(width: 44, height: 44)
                    Text("\(Int((pair.maxContainment * 100).rounded()))%")
                        .font(.mono(13, weight: .bold))
                        .foregroundStyle(Theme.canvas)
                }
                .shadow(color: Theme.amber.opacity(0.35), radius: 12)
                Rectangle().fill(Theme.hairline).frame(height: 1)
            }
            .padding(.vertical, 4)
            billBlock(b)
        }
    }

    private func billBlock(_ bill: Bill) -> some View {
        HStack(spacing: 14) {
            JurisdictionSeal(code: bill.jurisdiction, size: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.number)
                    .font(.display(20, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text(bill.title)
                    .font(.bodySerif(13.5))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private func containmentSection(a: Bill?, b: Bill?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow("Directional containment")
            directionalRow(
                label: "\(a?.number ?? pair.a) found inside \(b?.number ?? pair.b)",
                value: pair.containment_a_to_b
            )
            directionalRow(
                label: "\(b?.number ?? pair.b) found inside \(a?.number ?? pair.a)",
                value: pair.containment_b_to_a
            )
            Text("Share of one bill's 8-word shingles also present in the other.")
                .font(.mono(10.5))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline))
    }

    private func directionalRow(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text(String(format: "%.1f%%", value * 100))
                    .font(.mono(13, weight: .bold))
                    .foregroundStyle(value > 0 ? Theme.amber : Theme.tertiary)
            }
            ContainmentBar(value: value)
        }
    }

    private var metricsStrip: some View {
        HStack(spacing: 10) {
            StatTile(value: String(format: "%.3f", pair.jaccard), label: "Jaccard")
            StatTile(value: "\(pair.shared_shingles)", label: "Shingles")
            StatTile(value: "\(pair.evidence.count)", label: "Passages")
        }
    }

    private func evidenceSection(a: Bill?, b: Bill?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Eyebrow("Evidence passages")
                Spacer()
                Eyebrow("\(pair.evidence.count) longest", color: Theme.tertiary)
            }
            if pair.evidence.isEmpty {
                Text("No verbatim passages above threshold — this pair shares fewer than 15% of shingles.")
                    .font(.bodySerif(14))
                    .foregroundStyle(Theme.secondary)
            } else {
                ForEach(Array(pair.evidence.enumerated()), id: \.offset) { index, evidence in
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow("Passage \(String(format: "%02d", index + 1))", color: Theme.amberDeep)
                        DocumentExcerpt(
                            evidence: evidence,
                            billA: a?.number,
                            billB: b?.number
                        )
                    }
                }
            }
        }
    }

    private var caveat: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 12))
                .foregroundStyle(Theme.amber)
            Text("Similarity is not provenance. Long matches may quote the same existing statute rather than copied language — the longest passage here amends the same Code of Civil Procedure section in both bills.")
                .font(.bodySerif(13))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(4)
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.amber.opacity(0.2)))
    }

    private func sourcesSection(a: Bill?, b: Bill?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Sources")
            ForEach([a, b].compactMap { $0 }) { bill in
                if let url = URL(string: bill.url) {
                    Link(destination: url) {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.slate)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(bill.jurisdiction) \(bill.number) — official text")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.text)
                                Text(url.host ?? bill.url)
                                    .font(.mono(10))
                                    .foregroundStyle(Theme.tertiary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.tertiary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}
