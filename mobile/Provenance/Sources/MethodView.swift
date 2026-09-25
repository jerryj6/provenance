import SwiftUI

struct MethodView: View {
    @EnvironmentObject private var store: CorpusStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.bottom, 26)
                    Rule()
                        .padding(.bottom, 26)

                    pipelineSection
                        .padding(.bottom, 30)

                    metricsSection
                        .padding(.bottom, 30)

                    limitationsSection
                        .padding(.bottom, 30)

                    dataSection
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
            Eyebrow("Methodology & limitations")
            Text("How it reads\na bill")
                .font(.display(38, weight: .bold))
                .tracking(-1)
                .foregroundStyle(Theme.text)
                .lineSpacing(-2)
            Text("Reproducible by design: every claim links back to passage-level evidence, and every weakness is disclosed.")
                .font(.bodySerif(15))
                .foregroundStyle(Theme.secondary)
                .padding(.top, 2)
        }
    }

    private var pipelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("The pipeline")
                .padding(.bottom, 12)
            step(number: "01", title: "Normalize", body: "Each bill's official text — HTML, XML, or PDF — is reduced to lowercase words. Formatting, punctuation, and citation style are stripped so only the language remains.")
            step(number: "02", title: "Shingle", body: "Every document becomes a set of overlapping 8-word sequences. Two bills that copied each other share thousands of identical shingles.")
            step(number: "03", title: "Compare", body: "All pairs are scored. When either bill contains ≥15% of the other's shingles, the pair is linked and its longest verbatim passages are preserved as evidence.")
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
                name: "Containment",
                detail: "Directional — the fraction of bill A's shingles found in bill B. High containment means one text may be embedded in the other."
            )
            metricRow(
                name: "Jaccard",
                detail: "Symmetric overlap — shared shingles divided by all unique shingles. Lower even for true copies when bills differ in length."
            )
            metricRow(
                name: "Link threshold",
                detail: "Pairs link at ≥15% directional containment. Below that, matches are usually boilerplate rather than lineage."
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
            limitRow(title: "Similarity ≠ provenance", body: "Two bills amending the same statute share its existing text — the corpus's longest match is shared Code of Civil Procedure language, not necessarily copied drafting.")
            limitRow(title: "Boilerplate noise", body: "Enacting clauses and codification rituals repeat across all legislation and are filtered only by thresholds, not semantic judgment.")
            limitRow(title: "Corpus scope", body: "Nine bills prove the method. Definitive lineage claims need the full ~300-bill corpus and the change-diff engine that subtracts current statute text.")
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
