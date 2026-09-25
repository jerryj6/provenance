import SwiftUI

/// Run the real shingle engine on any two documents — corpus bills or pasted text.
struct CompareView: View {
    @EnvironmentObject private var store: CorpusStore
    @EnvironmentObject private var router: AppRouter

    @State private var selectionA: DocSource = .corpus(0)
    @State private var selectionB: DocSource = .corpus(1)
    @State private var textA = ""
    @State private var textB = ""
    @State private var result: ShingleEngine.AnalysisResult?

    enum DocSource: Hashable {
        case corpus(Int)       // index into store.bills
        case pasted
    }

    private func words(for source: DocSource, pasted: String) -> [String] {
        switch source {
        case .corpus(let index):
            guard store.bills.indices.contains(index) else { return [] }
            return store.words(for: store.bills[index])
        case .pasted:
            return ShingleEngine.tokenize(pasted)
        }
    }

    private func label(for source: DocSource, pasted: String) -> String {
        switch source {
        case .corpus(let index):
            guard store.bills.indices.contains(index) else { return "—" }
            return "\(store.bills[index].jurisdiction) \(store.bills[index].number)"
        case .pasted:
            return "Pasted text"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    header
                    pickers
                    analyzeButton
                    if let result { results(result) }
                    footerPad
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
            }
            .background(Theme.canvas)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: router.compareSeed) { _, seed in
                if let seed, let i = store.bills.firstIndex(of: seed) {
                    selectionA = .corpus(i)
                    router.compareSeed = nil
                }
            }
        }
    }

    private var header: some View {
        Text("Compare\ntwo documents")
            .font(.display(40, weight: .bold))
            .tracking(-1)
            .foregroundStyle(Theme.text)
            .lineSpacing(-2)
    }

    // MARK: - Inputs

    private var pickers: some View {
        VStack(spacing: 0) {
            docPicker(label: "A", selection: $selectionA, text: $textA)
                .padding(.bottom, 16)
                .overlay(alignment: .bottom) { Rule() }
            docPicker(label: "B", selection: $selectionB, text: $textB)
                .padding(.top, 16)
        }
    }

    private func docPicker(label: String, selection: Binding<DocSource>, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label)
                    .font(.mono(20, weight: .bold))
                    .foregroundStyle(Theme.amber)
                Spacer()
                Menu {
                    ForEach(Array(store.bills.enumerated()), id: \.element.id) { i, bill in
                        Button("\(bill.jurisdiction) \(bill.number)") { selection.wrappedValue = .corpus(i) }
                    }
                    Divider()
                    Button("Paste text…") { selection.wrappedValue = .pasted }
                } label: {
                    HStack(spacing: 6) {
                        Text(self.label(for: selection.wrappedValue, pasted: text.wrappedValue))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.text)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.tertiary)
                    }
                }
            }
            if selection.wrappedValue == .pasted {
                TextEditor(text: text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 90, maxHeight: 140)
                    .padding(10)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.hairlineStrong))
            } else {
                let w = words(for: selection.wrappedValue, pasted: text.wrappedValue)
                Text("\(w.count.formatted()) words")
                    .font(.mono(10))
                    .foregroundStyle(Theme.tertiary)
            }
        }
    }

    private var analyzeButton: some View {
        let ready = !words(for: selectionA, pasted: textA).isEmpty && !words(for: selectionB, pasted: textB).isEmpty
        return Button {
            let a = words(for: selectionA, pasted: textA)
            let b = words(for: selectionB, pasted: textB)
            withAnimation(.easeOut(duration: 0.25)) {
                result = ShingleEngine.analyze(a, b)
            }
        } label: {
            Text("Analyze")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ready ? Theme.canvas : Theme.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(ready ? Theme.amber : Color.white.opacity(0.06), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!ready)
    }

    // MARK: - Results

    @ViewBuilder
    private func results(_ r: ShingleEngine.AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 30) {
            // verdict
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int((r.maxContainment * 100).rounded()))%")
                    .font(.display(52, weight: .bold))
                    .foregroundStyle(r.isLinked ? Theme.amber : Theme.text)
                VStack(alignment: .leading, spacing: 3) {
                    Text(r.isLinked ? "Shared text" : "Independent")
                        .font(.display(19, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Text(r.isLinked ? "above the 15% link threshold" : "below the 15% link threshold")
                        .font(.mono(10))
                        .foregroundStyle(Theme.tertiary)
                }
            }

            MetricsRow([
                (String(format: "%.1f%%", r.containmentAToB * 100), "A ⊂ B", r.containmentAToB > 0 ? Theme.amber : Theme.text),
                (String(format: "%.1f%%", r.containmentBToA * 100), "B ⊂ A", r.containmentBToA > 0 ? Theme.amber : Theme.text),
                (String(format: "%.3f", r.jaccard), "Jaccard", Theme.text),
                (r.sharedShingles.formatted(), "Shingles", Theme.text),
            ])

            CoverageMap(
                wordsA: r.wordCountA, wordsB: r.wordCountB,
                bands: r.evidence.map { .init(aStart: $0.aStart, aEnd: $0.aEnd, bStart: $0.bStart, bEnd: $0.bEnd) },
                labelA: label(for: selectionA, pasted: textA),
                labelB: label(for: selectionB, pasted: textB)
            )

            if !r.evidence.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Eyebrow("Shared passages")
                    ForEach(Array(r.evidence.enumerated()), id: \.offset) { _, run in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(run.text)
                                .font(.bodySerif(13.5))
                                .foregroundStyle(Theme.secondary)
                                .lineSpacing(5)
                                .textSelection(.enabled)
                            Text("\(run.wordCount) words")
                                .font(.mono(10))
                                .foregroundStyle(Theme.tertiary)
                        }
                        .padding(.leading, 14)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(Theme.amber).frame(width: 3).padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }

    private var footerPad: some View { Spacer().frame(height: 40) }
}
