import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    @Published var tab = 0
    @Published var compareSeed: Bill?
}

@main
struct ProvenanceApp: App {
    @StateObject private var store = CorpusStore.load()
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(router)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        TabView(selection: $router.tab) {
            Tab("Findings", systemImage: "doc.text.magnifyingglass", value: 0) {
                FindingsView()
            }
            Tab("Corpus", systemImage: "building.columns", value: 1) {
                CorpusView()
            }
            Tab("Compare", systemImage: "arrow.left.arrow.right", value: 2) {
                CompareView()
            }
            Tab("Method", systemImage: "ruler", value: 3) {
                MethodView()
            }
        }
        .tint(Theme.amber)
    }
}
