import SwiftUI

struct MethodView: View {
    @EnvironmentObject private var store: CorpusStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 26)
                        .appear(0)
                    Rule()
                        .padding(.bottom, 26)

                    pipelineSection
                        .padding(.bottom, 30)
                        .appear(1)

                    metricsSection
                        .padding(.bottom, 30)
                        .appear(2)

                    limitationsSection
                        .padding(.bottom, 30)
                        .appear(3)

                    dataSection
                        .appear(4)
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
            Text("How it reads\na bill")
                .font(.display(38, weight: .bold))
                .tracking(-1)
                .foregroundStyle(Theme.text)
                .lineSpacing(-2)

        }
    }

    private var pipelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("The pipeline")
                .padding(.bottom, 12)
            step(number: "01", title: "Normalize", body: "Official text → lowercase words. Punctuation and formatting stripped.")
            step(number: "02", title: "Shingle", body: "Each bill → a set of overlapping 8-word sequences.")
            step(number: "03", title: "Compare", body: "Every pair scored. Links at ≥15% containment; longest shared passages kept as evidence.")
        }
    }

    private func step(number: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.mono(12, weight: .bold))
                .foregroundStyle(Theme.amber)
                .frame(width: 26, alignment: .leading)
                .padding(.top, 3)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.display(17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(body)
                    .font(.bodySerif(13.5))
                    .foregroundStyle(Theme.secondary)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Rule() }
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Reading the scores")
                .padding(.bottom, 10)
            metricRow(
                name: "A ⊂ B — containment",
                detail: "Share of bill A's shingles found inside bill B."
            )
            metricRow(
                name: "Jaccard",
                detail: "Shared shingles ÷ all unique shingles. Symmetric."
            )
            metricRow(
                name: "Link — ≥15%",
                detail: "Below that, matches are usually boilerplate, not lineage."
            )
        }
    }

    private func metricRow(name: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)
            Text(detail)
                .font(.bodySerif(13))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) { Rule() }
    }

    private var limitationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Honest limits", color: Theme.amberDeep)
                .padding(.bottom, 10)
            limitRow(title: "Similarity ≠ provenance", body: "Bills amending the same statute share its existing text — the top match here is shared Code of Civil Procedure language.")
            limitRow(title: "Boilerplate noise", body: "Enacting clauses repeat across all legislation; filtered by threshold, not judgment.")
            limitRow(title: "Corpus scope", body: "Nine bills prove the method. Definitive claims need the ~300-bill corpus plus statute-subtraction.")
        }
    }

    private func limitRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.text)
            Text(body)
                .font(.bodySerif(13))
                .foregroundStyle(Theme.secondary)
                .lineSpacing(4)
        }
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) { Rule() }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Data & reproducibility")
                .padding(.bottom, 10)
            sourceRow("California Legislative Information", "leginfo.legislature.ca.gov")
            sourceRow("GovInfo (US Congress)", "govinfo.gov")
            sourceRow("State legislature archives", "CO · FL · MN · TN · UT · WI")
            sourceRow("LegiScan API (planned)", "legiscan.com")
            if !store.loadWarnings.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.amber)
                    Text(store.loadWarnings.joined(separator: " · "))
                        .font(.mono(10))
                        .foregroundStyle(Theme.secondary)
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { Rule() }
            }
            HStack {
                Text("PIPELINE RUN")
                    .font(.mono(9.5, weight: .semibold)).tracking(1.5)
                    .foregroundStyle(Theme.tertiary)
                Spacer()
                if let date = store.manifest.runDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.mono(10))
                        .foregroundStyle(Theme.secondary)
                }
            }
            .padding(.top, 14)
        }
    }

    private func sourceRow(_ name: String, _ detail: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.text)
            Spacer()
            Text(detail)
                .font(.mono(10.5))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Rule() }
    }
}
