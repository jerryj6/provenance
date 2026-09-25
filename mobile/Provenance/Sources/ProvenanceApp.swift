import SwiftUI

@main
struct ProvenanceApp: App {
    @StateObject private var store = CorpusStore.load()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Findings", systemImage: "doc.text.magnifyingglass") {
                FindingsView()
            }
            Tab("Corpus", systemImage: "building.columns") {
                CorpusView()
            }
            Tab("Method", systemImage: "ruler") {
                MethodView()
            }
        }
        .tint(Theme.amber)
    }
}
