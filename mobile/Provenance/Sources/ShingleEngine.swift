import Foundation

/// Faithful port of src/provenance/lineage.py — 8-word shingles, directional
/// containment, Jaccard, and longest verbatim shared runs.
enum ShingleEngine {
    static let shingleSize = 8
    static let linkThreshold = 0.15

    static func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .map { $0.isLetter || $0.isNumber ? $0 : " " }
            .reduce(into: String()) { $0.append($1) }
            .split(whereSeparator: { $0 == " " })
            .map(String.init)
    }

    static func shingles(of words: [String], n: Int = shingleSize) -> Set<String> {
        guard words.count >= n else { return [] }
        var set = Set<String>(minimumCapacity: words.count - n + 1)
        for i in 0...(words.count - n) {
            set.insert(words[i..<(i + n)].joined(separator: " "))
        }
        return set
    }

    struct SharedRun: Hashable {
        let aStart: Int
        let aEnd: Int
        let bStart: Int
        let bEnd: Int
        let text: String
        var wordCount: Int { aEnd - aStart }
    }

    struct AnalysisResult {
        let containmentAToB: Double
        let containmentBToA: Double
        let jaccard: Double
        let sharedShingles: Int
        let isLinked: Bool
        let evidence: [SharedRun]
        let wordCountA: Int
        let wordCountB: Int
        var maxContainment: Double { max(containmentAToB, containmentBToA) }
    }

    static func analyze(_ wordsA: [String], _ wordsB: [String], n: Int = shingleSize) -> AnalysisResult {
        let sa = shingles(of: wordsA, n: n)
        let sb = shingles(of: wordsB, n: n)
        let shared = sa.intersection(sb)
        let aToB = sa.isEmpty ? 0 : Double(shared.count) / Double(sa.count)
        let bToA = sb.isEmpty ? 0 : Double(shared.count) / Double(sb.count)
        let union = sa.union(sb)
        let jaccard = union.isEmpty ? 0 : Double(shared.count) / Double(union.count)
        let linked = max(aToB, bToA) >= linkThreshold
        let evidence = linked ? sharedRuns(wordsA, wordsB, n: n) : []
        return AnalysisResult(
            containmentAToB: aToB, containmentBToA: bToA,
            jaccard: jaccard, sharedShingles: shared.count,
            isLinked: linked, evidence: evidence,
            wordCountA: wordsA.count, wordCountB: wordsB.count
        )
    }

    /// Longest verbatim shared runs — same expansion/dedup as lineage.py.
    private static func sharedRuns(_ left: [String], _ right: [String], n: Int, limit: Int = 3) -> [SharedRun] {
        var rightPositions: [String: [Int]] = [:]
        guard right.count >= n, left.count >= n else { return [] }
        for i in 0...(right.count - n) {
            rightPositions[right[i..<(i + n)].joined(separator: " "), default: []].append(i)
        }

        var unique: [Int: SharedRun] = [:]
        for li in 0...(left.count - n) {
            let key = left[li..<(li + n)].joined(separator: " ")
            for ri in rightPositions[key] ?? [] {
                var sl = li, sr = ri
                while sl > 0 && sr > 0 && left[sl - 1] == right[sr - 1] { sl -= 1; sr -= 1 }
                var el = li + n, er = ri + n
                while el < left.count && er < right.count && left[el] == right[er] { el += 1; er += 1 }
                let run = SharedRun(aStart: sl, aEnd: el, bStart: sr, bEnd: er,
                                    text: left[sl..<el].joined(separator: " "))
                unique[(sl << 40) | (el << 20) | sr] = run
            }
        }
        let ordered = unique.values.sorted {
            if $0.wordCount != $1.wordCount { return $0.wordCount > $1.wordCount }
            return $0.aStart < $1.aStart
        }
        var evidence: [SharedRun] = []
        for run in ordered {
            let overlaps = evidence.contains { item in
                !(run.aEnd <= item.aStart || run.aStart >= item.aEnd)
                    || !(run.bEnd <= item.bStart || run.bStart >= item.bEnd)
            }
            if overlaps { continue }
            if evidence.contains(where: { run.text.contains($0.text) || $0.text.contains(run.text) }) { continue }
            if evidence.contains(where: { wordRatio(run.text, $0.text) >= 0.4 }) { continue }
            evidence.append(run)
            if evidence.count >= limit { break }
        }
        return evidence
    }

    /// 2*M/(|a|+|b|) on word sequences — difflib-style ratio used for evidence dedup.
    private static func wordRatio(_ a: String, _ b: String) -> Double {
        let wa = a.split(separator: " ").map(String.init)
        let wb = b.split(separator: " ").map(String.init)
        guard !wa.isEmpty, !wb.isEmpty else { return 0 }
        let lcs = lcsLength(wa, wb)
        return 2.0 * Double(lcs) / Double(wa.count + wb.count)
    }

    private static func lcsLength(_ a: [String], _ b: [String]) -> Int {
        var dp = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            var prev = 0
            for j in 1...b.count {
                let tmp = dp[j]
                dp[j] = a[i - 1] == b[j - 1] ? prev + 1 : max(dp[j], dp[j - 1])
                prev = tmp
            }
        }
        return dp[b.count]
    }
}
