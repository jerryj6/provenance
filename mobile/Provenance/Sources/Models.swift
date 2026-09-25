import Foundation

struct Bill: Identifiable, Codable, Hashable {
    let id: String
    let jurisdiction: String
    let number: String
    let session: String
    let source: String
    let title: String
    let topics: [String]
    let url: String
    let word_count: Int
    let text_sha256: String

    var jurisdictionName: String {
        Bill.jurisdictionNames[jurisdiction] ?? jurisdiction
    }

    static let jurisdictionNames: [String: String] = [
        "US": "United States Congress", "CA": "California", "CO": "Colorado",
        "FL": "Florida", "MN": "Minnesota", "TN": "Tennessee",
        "UT": "Utah", "WI": "Wisconsin",
    ]
}

struct Evidence: Codable, Hashable {
    let a_start: Int
    let a_end: Int
    let b_start: Int
    let b_end: Int
    let text: String
    let word_count: Int
}

struct Pair: Codable, Hashable, Identifiable {
    var id: String { "\(a)|\(b)" }
    let a: String
    let b: String
    let containment_a_to_b: Double
    let containment_b_to_a: Double
    let jaccard: Double
    let shared_shingles: Int
    let evidence: [Evidence]

    var maxContainment: Double { max(containment_a_to_b, containment_b_to_a) }
    var isLinked: Bool { maxContainment >= 0.15 }
}

struct Lineage: Codable {
    let clusters: [[String]]
    let pairs: [Pair]
}

struct Finding: Codable, Hashable, Identifiable {
    var id: String { title }
    let members: [String]
    let title: String
    let top_evidence_passage: Evidence
}

struct CorpusManifest: Codable {
    let corpus_size: Int
    let run_timestamp: String

    var runDate: Date? {
        let f = ISO8601DateFormatter()
        return f.date(from: run_timestamp)
    }
}

@MainActor
final class CorpusStore: ObservableObject {
    let bills: [Bill]
    let lineage: Lineage
    let findings: [Finding]
    let manifest: CorpusManifest

    private let byID: [String: Bill]

    init(bills: [Bill], lineage: Lineage, findings: [Finding], manifest: CorpusManifest) {
        self.bills = bills
        self.lineage = lineage
        self.findings = findings
        self.manifest = manifest
        self.byID = Dictionary(uniqueKeysWithValues: bills.map { ($0.id, $0) })
    }

    func bill(_ id: String) -> Bill? { byID[id] }

    func pair(for finding: Finding) -> Pair? {
        lineage.pairs.first { Set([$0.a, $0.b]) == Set(finding.members) }
    }

    func pairs(involving billID: String) -> [Pair] {
        lineage.pairs.filter { $0.a == billID || $0.b == billID }
    }

    func linkedPairs() -> [Pair] {
        lineage.pairs.filter(\.isLinked)
    }

    func clusters() -> [[Bill]] {
        lineage.clusters.map { ids in ids.compactMap { byID[$0] } }
    }

    static func load() -> CorpusStore {
        let decoder = JSONDecoder()

        func decode<T: Decodable>(_ name: String, _ ext: String = "json", subdir: String? = nil, as type: T.Type = T.self) -> T {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir),
                  let data = try? Data(contentsOf: url),
                  let value = try? decoder.decode(T.self, from: data) else {
                fatalError("Missing or invalid bundled resource: \(name).\(ext)")
            }
            return value
        }

        let manifest: CorpusManifest = decode("manifest", subdir: "Data")
        let lineage: Lineage = decode("lineage", subdir: "Data")
        let findings: [Finding] = decode("findings", subdir: "Data")

        var bills: [Bill] = []
        if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Data/bills") {
            bills = urls.compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(Bill.self, from: data)
            }
        }

        return CorpusStore(
            bills: bills.sorted { $0.id < $1.id },
            lineage: lineage,
            findings: findings,
            manifest: manifest
        )
    }
}
