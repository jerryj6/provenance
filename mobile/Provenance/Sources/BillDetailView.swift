import SwiftUI

struct BillDetailView: View {
    let bill: Bill
    @EnvironmentObject private var store: CorpusStore

    private var linkedPairs: [Pair] {
        store.pairs(involving: bill.id).filter(\.isLinked)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metadataGrid
                lineageSection
                sourceSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Eyebrow("Legislative profile")
            }
        }
        .navigationDestination(for: Pair.self) { pair in
            PairDetailView(pair: pair)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                JurisdictionSeal(code: bill.jurisdiction, size: 56)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Eyebrow("Session")
                    Text(bill.session)
                        .font(.mono(13, weight: .semibold))
                        .foregroundStyle(Theme.text)
                }
            }
            Text(bill.number)
                .font(.display(40, weight: .bold))
                .tracking(-1)
                .foregroundStyle(Theme.text)
            Text(bill.title)
                .font(.bodySerif(17))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(4)
            HStack(spacing: 6) {
                ForEach(bill.topics, id: \.self) { topic in
                    TopicTag(text: topic)
                }
            }
        }
    }

    private var metadataGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Profile")
            HStack(spacing: 10) {
                StatTile(value: bill.word_count.formatted(), label: "Words")
                StatTile(value: "\(bill.topics.count)", label: "Topics")
                StatTile(value: bill.jurisdiction, label: "Region")
            }
        }
    }

    private var lineageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow("Lineage")
            if linkedPairs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.slate)
                    Text("No shared text detected")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Text("This bill shares fewer than 15% of its 8-word shingles with any other bill in the corpus — its language is its own.")
                        .font(.bodySerif(13.5))
                        .foregroundStyle(Theme.secondary)
                        .lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.hairline))
            } else {
                ForEach(linkedPairs) { pair in
                    let otherID = pair.a == bill.id ? pair.b : pair.a
                    if let other = store.bill(otherID) {
                        NavigationLink(value: pair) {
                            HStack(spacing: 14) {
                                JurisdictionSeal(code: other.jurisdiction, size: 40)
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
                            }
                            .padding(14)
                            .background(Theme.amberSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Theme.amber.opacity(0.25)))
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
            }
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow("Official source")
            if let url = URL(string: bill.url) {
                Link(destination: url) {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.slate)
                        Text(url.host ?? bill.url)
                            .font(.mono(11.5))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.tertiary)
                    }
                    .padding(14)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline))
                }
            }
            Text("SHA-256 \(bill.text_sha256.prefix(16))…")
                .font(.mono(9.5))
                .foregroundStyle(Theme.tertiary)
                .textSelection(.enabled)
        }
    }
}
