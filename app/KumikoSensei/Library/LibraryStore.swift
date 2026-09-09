import Foundation
import Observation

@MainActor
@Observable
final class LibraryStore {
    enum State: Equatable {
        case needsFolder
        case accessLost(String)
        case loading
        case ready
    }

    private(set) var rootURL: URL?
    private(set) var items: [KnowledgeItem] = []
    private(set) var warnings: [String] = []
    private(set) var state: State = .needsFolder
    private(set) var lastScan: Date?
    private(set) var isWatching = false
    private(set) var searchIndex = SearchIndex()
    var favorites: Set<String> {
        didSet { UserDefaults.standard.set(Array(favorites).sorted(), forKey: "favorites") }
    }

    let searchProvider: SearchProvider = LexicalSearchProvider()
    private var watcher: FolderWatcher?
    private var accessingURL: URL?
    private var scanTask: Task<Void, Never>?

    init(restoreBookmark: Bool = true) {
        favorites = Set(UserDefaults.standard.stringArray(forKey: "favorites") ?? [])
        guard restoreBookmark else { return }
        if let url = FolderAccess.restoreBookmark() {
            open(url, remember: false)
        }
    }

    var templateURL: URL? { rootURL?.appending(path: LibraryScanner.templatePath) }
    var inboxURL: URL? { rootURL?.appending(path: LibraryScanner.inboxPath) }

    func chooseFolder() {
        guard let url = FolderAccess.chooseFolder() else { return }
        open(url, remember: true)
    }

    func openSampleLibrary() {
        do {
            let url = try FolderAccess.installSampleLibrary()
            open(url, remember: true)
        } catch {
            state = .accessLost("The sample library could not be installed: \(error.localizedDescription)")
        }
    }

    func open(_ url: URL, remember: Bool) {
        stopAccess()
        let granted = url.startAccessingSecurityScopedResource()
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            if granted { url.stopAccessingSecurityScopedResource() }
            state = .accessLost("Access to \(url.lastPathComponent) expired or was revoked. Choose the folder again to reconnect.")
            return
        }
        if granted { accessingURL = url }
        if remember {
            do { try FolderAccess.saveBookmark(for: url) } catch { warnings = ["Bookmark could not be saved: \(error.localizedDescription)"] }
        }
        rootURL = url
        state = .loading
        watcher = FolderWatcher(url: url) { [weak self] in self?.rescan() }
        isWatching = watcher?.isActive ?? false
        rescan()
    }

    func disconnect() {
        stopAccess()
        FolderAccess.forgetBookmark()
        rootURL = nil
        items = []
        searchIndex = SearchIndex()
        state = .needsFolder
    }

    func rescan() {
        guard let root = rootURL else { return }
        scanTask?.cancel()
        let scanner = LibraryScanner(root: root)
        scanTask = Task { [weak self] in
            let result = await Task.detached(priority: .userInitiated) { scanner.scan() }.value
            guard !Task.isCancelled, let self else { return }
            self.items = result.items
            self.warnings = result.warnings
            self.searchIndex = SearchIndex(items: result.items)
            self.lastScan = Date()
            self.state = .ready
        }
    }

    func search(_ query: String) -> [SearchHit] {
        searchProvider.search(query, in: searchIndex)
    }

    func item(id: String?) -> KnowledgeItem? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    func toggleFavorite(_ id: String) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
    }

    var repositories: [String] {
        Array(Set(items.compactMap(\.repositoryName))).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var tags: [String] {
        Array(Set(items.flatMap(\.tags))).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private func stopAccess() {
        watcher = nil
        isWatching = false
        accessingURL?.stopAccessingSecurityScopedResource()
        accessingURL = nil
    }
}
