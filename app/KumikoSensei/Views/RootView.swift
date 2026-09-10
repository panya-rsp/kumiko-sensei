import SwiftUI

enum SidebarFilter: Hashable {
    case all, sessions, prReviewPacks, handoffs, inbox, favorites
    case repository(String)
    case tag(String)

    var title: String {
        switch self {
        case .all: return "All knowledge"
        case .sessions: return "Sessions"
        case .prReviewPacks: return "PR review packs"
        case .handoffs: return "Handoffs"
        case .inbox: return "Inbox / needs attention"
        case .favorites: return "Favorites"
        case .repository(let name): return name
        case .tag(let name): return name
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "books.vertical"
        case .sessions: return "rectangle.stack"
        case .prReviewPacks: return "checklist"
        case .handoffs: return "doc.text"
        case .inbox: return "tray"
        case .favorites: return "star"
        case .repository: return "shippingbox"
        case .tag: return "tag"
        }
    }

    func matches(_ item: KnowledgeItem, favorites: Set<String>) -> Bool {
        switch self {
        case .all: return true
        case .sessions: return item.kind == .session
        case .prReviewPacks: return item.isPRReviewPack
        case .handoffs: return item.handoff != nil
        case .inbox: return item.kind == .inboxHandoff
        case .favorites: return favorites.contains(item.id)
        case .repository(let name): return item.repositoryName == name
        case .tag(let name): return item.tags.contains(name)
        }
    }
}

struct RootView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(UIState.self) private var ui

    var body: some View {
        @Bindable var ui = ui
        Group {
            switch store.state {
            case .needsFolder, .accessLost:
                OnboardingView()
            case .loading, .ready:
                desk
            }
        }
        .sheet(isPresented: $ui.showSearch) { SearchPaletteView() }
        .sheet(isPresented: $ui.showComposer) { ComposerView() }
        .sheet(isPresented: $ui.showAsk) { AskKumikoView(preselectedID: ui.selectedItemID) }
    }

    private var desk: some View {
        @Bindable var ui = ui
        return NavigationSplitView {
            SidebarView(selection: $ui.filter)
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
        } content: {
            LibraryListView(filter: ui.filter, selection: $ui.selectedItemID)
                .navigationSplitViewColumnWidth(min: 330, ideal: 400, max: 560)
        } detail: {
            if let item = store.item(id: ui.selectedItemID) {
                DetailView(item: item)
                    .id(item.id)
            } else {
                DetailEmptyView()
            }
        }
        .inspector(isPresented: $ui.showNotes) {
            NotesPane(item: store.item(id: ui.selectedItemID))
                .inspectorColumnWidth(min: 260, ideal: 360, max: 720)
        }
        .deskWindowBackground()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { ui.showComposer = true } label: { Label("New Handoff", systemImage: "square.and.pencil") }
                    .help("Compose a new handoff from the template (⌘N)")
                    .accessibilityIdentifier("toolbar.newHandoff")
                Button { ui.showAsk = true } label: { Label("Ask Kumiko", systemImage: "bubble.left.and.text.bubble.right") }
                    .help("Draft a local question for Kumiko-sensei (⇧⌘K)")
                    .accessibilityIdentifier("toolbar.askKumiko")
            }
            if #available(macOS 26, *) {
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button { store.rescan() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    .help("Rescan the library folder (⌘R)")
                Button { ui.showSearch = true } label: { Label("Search", systemImage: "magnifyingglass") }
                    .help("Search the library (⌘K)")
                    .accessibilityIdentifier("toolbar.search")
                    .accessibilityHint("Opens Spotlight-style local search")
                Button { ui.showNotes.toggle() } label: { Label("Notes", systemImage: ui.showNotes ? "note.text" : "note") }
                    .help(ui.showNotes ? "Hide my notes (⌥⌘I)" : "Show my notes for this entry (⌥⌘I)")
                    .accessibilityIdentifier("toolbar.notes")
            }
        }
    }
}

struct SidebarView: View {
    @Environment(LibraryStore.self) private var store
    @Binding var selection: SidebarFilter

    var body: some View {
        List(selection: Binding(get: { Optional(selection) }, set: { if let v = $0 { selection = v } })) {
            Section("Library") {
                ForEach([SidebarFilter.all, .sessions, .prReviewPacks, .handoffs, .inbox, .favorites], id: \.self) { filter in
                    row(filter)
                }
            }
            Section("Repositories") {
                if store.repositories.isEmpty {
                    Text("No source repositories recorded").font(.inter(.caption)).foregroundStyle(.secondary)
                } else {
                    ForEach(store.repositories, id: \.self) { row(.repository($0)) }
                }
            }
            Section("Tags") {
                if store.tags.isEmpty {
                    Text("No tags yet. Add `tags:` to a handoff's front matter.").font(.inter(.caption)).foregroundStyle(.secondary)
                } else {
                    ForEach(store.tags, id: \.self) { row(.tag($0)) }
                }
            }
        }
        .modifier(SidebarListStyle())
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                if let root = store.rootURL {
                    Text(root.lastPathComponent).font(.inter(.caption, .medium)).foregroundStyle(.secondary).lineLimit(1)
                    Text(store.isWatching ? "Watching for changes" : "Manual refresh (⌘R)").font(.inter(.caption2)).foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12).padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(_ filter: SidebarFilter) -> some View {
        let count = store.items.filter { filter.matches($0, favorites: store.favorites) }.count
        return Label(filter.title, systemImage: filter.systemImage)
            .badge(count)
            .tag(filter)
            .accessibilityLabel("\(filter.title), \(count) notes")
    }
}

struct SidebarListStyle: ViewModifier {
    func body(content: Content) -> some View {
        if DevLaunch.snapshotDirectory != nil {
            content.listStyle(.inset).scrollContentBackground(.hidden)
        } else {
            content.listStyle(.sidebar)
        }
    }
}

struct DetailEmptyView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(UIState.self) private var ui

    var body: some View {
        VStack(spacing: 16) {
            MascotBadge(size: 132)
                .accessibilityHidden(true)
            if store.items.isEmpty {
                Text("The library is empty").font(.deskTitle).foregroundStyle(Palette.ink)
                Text("Sessions live in sessions/ and pending work in handoffs/inbox/. Compose a handoff to start.")
                    .font(.inter(.callout)).foregroundStyle(Palette.inkMuted).multilineTextAlignment(.center).frame(maxWidth: 380)
                Button("New Handoff…") { ui.showComposer = true }.buttonStyle(.borderedProminent)
            } else {
                Text("Pick a note to read it").font(.deskTitle).foregroundStyle(Palette.ink)
                Text("Takeaway first, then the visual, the explanation, the review guide, and the evidence behind it.")
                    .font(.inter(.callout)).foregroundStyle(Palette.inkMuted).multilineTextAlignment(.center).frame(maxWidth: 380)
                Button("Search library  ⌘K") { ui.showSearch = true }.buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .deskColumnBackground()
    }
}
