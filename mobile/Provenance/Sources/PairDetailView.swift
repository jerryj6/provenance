import SwiftUI

struct PairDetailView: View {
    let pair: Pair
    @EnvironmentObject private var store: CorpusStore

    var body: some View {
        let a = store.bill(pair.a)
        let b = store.bill(pair.b)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let a, let b {
                    versusHeader(a: a, b: b)
                        .padding(.bottom, 26)
                }

                containmentSection(a: a, b: b)
                    .padding(.bottom, 8)

                MetricsRow([
                    (String(format: "%.3f", pair.jaccard), "Jaccard", Theme.text),
                    ("\(pair.shared_shingles)", "Shingles", Theme.text),
                    ("\(pair.evidence.count)", "Passages", Theme.text),
                ])
                Rule()
                    .padding(.bottom, 28)

                evidenceSection(a: a, b: b)
                    .padding(.bottom, 30)

                caveat
                    .padding(.bottom, 30)

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

    // MARK: - Versus header

    private func versusHeader(a: Bill, b: Bill) -> some View {
        VStack(spacing: 0) {
            billBlock(a)
            HStack(spacing: 12) {
                Rule()
                Text("\(Int((pair.maxContainment * 100).rounded()))%")
                    .font(.mono(20, weight: .bold))
                    .foregroundStyle(Theme.amber)
                    .monospacedDigit()
                Rule()
            }
            billBlock(b)
        }
    }

    private func billBlock(_ bill: Bill) -> some View {
        HStack(spacing: 14) {
            JurisdictionSeal(code: bill.jurisdiction, size: 44)
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
        .padding(.vertical, 14)
    }

    // MARK: - Directional containment

    private func containmentSection(a: Bill?, b: Bill?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow("Directional containment")
            VStack(spacing: 14) {
                directionalRow(
                    label: "\(a?.number ?? pair.a) ⊂ \(b?.number ?? pair.b)",
                    value: pair.containment_a_to_b
                )
                directionalRow(
                    label: "\(b?.number ?? pair.b) ⊂ \(a?.number ?? pair.a)",
                    value: pair.containment_b_to_a
                )
            }
        }
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) { Rule() }
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

    // MARK: - Evidence

    private func evidenceSection(a: Bill?, b: Bill?) -> some View {
        VStack(alignment: .leading, spacing: 18) {
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

    // MARK: - Caveat & sources

    private var caveat: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 12))
                .foregroundStyle(Theme.amber)
            Text("Similarity is not provenance — the longest passage here amends the same statute section in both bills.")
                .font(.bodySerif(13))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(4)
        }
        .padding(.bottom, 20)
        .overlay(alignment: .bottom) { Rule() }
    }

    private func sourcesSection(a: Bill?, b: Bill?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Sources")
                .padding(.bottom, 10)
            ForEach([a, b].compactMap { $0 }) { bill in
                if let url = URL(string: bill.url) {
                    Link(destination: url) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.tertiary)
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
                        .padding(.vertical, 12)
                        .overlay(alignment: .bottom) { Rule() }
                    }
                }
            }
        }
    }
}
