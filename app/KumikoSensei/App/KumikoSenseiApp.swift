import SwiftUI

@MainActor
@Observable
final class UIState {
    var filter: SidebarFilter = .all
    var selectedItemID: String?
    var showSearch = false
    var showComposer = false
    var showAsk = false
    var searchSeed = ""

    func open(_ item: KnowledgeItem, favorites: Set<String>) {
        if !filter.matches(item, favorites: favorites) { filter = .all }
        selectedItemID = item.id
    }
}

@main
struct KumikoSenseiApp: App {
    @State private var store: LibraryStore
    @State private var ui = UIState()

    init() {
        let store = LibraryStore(restoreBookmark: DevLaunch.libraryPath == nil && !DevLaunch.useSampleLibrary)
        if let path = DevLaunch.libraryPath {
            store.open(URL(fileURLWithPath: path, isDirectory: true), remember: false)
        } else if DevLaunch.useSampleLibrary {
            store.openSampleLibrary()
        }
        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup("Kumiko Sensei") {
            RootView()
                .environment(store)
                .environment(ui)
                .frame(minWidth: 980, minHeight: 620)
                .task { await SnapshotRunner.runIfRequested(store: store, ui: ui) }
        }
        .defaultSize(width: 1340, height: 880)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Handoff…") { ui.showComposer = true }
                    .keyboardShortcut("n")
                    .disabled(store.rootURL == nil)
                Button("Ask Kumiko…") { ui.showAsk = true }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .disabled(store.rootURL == nil)
            }
            CommandMenu("Library") {
                Button("Search Library…") { ui.showSearch = true }
                    .keyboardShortcut("k")
                    .disabled(store.rootURL == nil)
                Button("Refresh") { store.rescan() }
                    .keyboardShortcut("r")
                    .disabled(store.rootURL == nil)
                Divider()
                Button("Reveal Library in Finder") { store.rootURL.map(FolderAccess.reveal) }
                    .disabled(store.rootURL == nil)
                Button("Choose Library Folder…") { store.chooseFolder() }
                Button("Disconnect Library") { store.disconnect() }
                    .disabled(store.rootURL == nil)
            }
        }
    }
}
