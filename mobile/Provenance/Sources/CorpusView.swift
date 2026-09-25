import SwiftUI

struct CorpusView: View {
    @EnvironmentObject private var store: CorpusStore

    private var grouped: [(jurisdiction: String, bills: [Bill])] {
        let groups = Dictionary(grouping: store.bills, by: \.jurisdiction)
        return groups.keys.sorted()
            .map { (jurisdiction: $0, bills: groups[$0]!.sorted { $0.number < $1.number }) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    ForEach(grouped, id: \.jurisdiction) { group in
                        jurisdictionSection(group)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: Bill.self) { bill in
                BillDetailView(bill: bill)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Every bill\nunder analysis")
                .font(.display(38, weight: .bold))
                .tracking(-1)
                .foregroundStyle(Theme.text)
                .lineSpacing(-2)

        }
    }

    private func jurisdictionSection(_ group: (jurisdiction: String, bills: [Bill])) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.bills.first?.jurisdictionName ?? group.jurisdiction)
                    .font(.display(19, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("\(group.bills.count)")
                    .font(.mono(12))
                    .foregroundStyle(Theme.tertiary)
            }
            .padding(.bottom, 8)
            Rule()

            ForEach(group.bills) { bill in
                NavigationLink(value: bill) {
                    BillRow(bill: bill)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct BillRow: View {
    let bill: Bill

    var body: some View {
        HStack(spacing: 14) {
            JurisdictionSeal(code: bill.jurisdiction, size: 42)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(bill.number)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Text(bill.session)
                        .font(.mono(10))
                        .foregroundStyle(Theme.tertiary)
                }
                Text(bill.title)
                    .font(.bodySerif(13.5))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(bill.word_count.formatted()) words")
                    .font(.mono(10))
                    .foregroundStyle(Theme.tertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Rule() }
        .contentShape(Rectangle())
    }
}
