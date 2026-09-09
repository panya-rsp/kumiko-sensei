import SwiftUI

struct SearchPaletteView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var highlighted: String?
    @FocusState private var focused: Bool

    private var hits: [SearchHit] { store.search(query) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search titles, takeaways, evidence paths, symbols, ticket or PR IDs…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($focused)
                    .onSubmit(openHighlighted)
                    .onKeyPress(.downArrow) { move(1); return .handled }
                    .onKeyPress(.upArrow) { move(-1); return .handled }
                    .accessibilityLabel("Search library")
                    .accessibilityIdentifier("search.field")
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.plain).accessibilityLabel("Clear search")
                }
                Button("Close") { dismiss() }.keyboardShortcut(.cancelAction).buttonStyle(.plain).foregroundStyle(.secondary)
            }
            .padding(16)
            Divider()
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(spacing: 8) {
                    Text("Local search across \(store.items.count) notes").font(.headline).foregroundStyle(.primary)
                    Text("Matches filenames, titles, takeaways, evidence paths, symbols, tags, ticket and PR IDs, and review-guide text. ↑↓ to move, ⏎ to open, esc to close.")
                        .font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 460)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hits.isEmpty {
                ContentUnavailableView.search(text: query).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(hits) { hit in
                                Button { open(hit.item) } label: {
                                    SearchHitRow(hit: hit, isHighlighted: hit.id == highlighted)
                                }
                                .buttonStyle(.plain)
                                .id(hit.id)
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: highlighted) { _, id in if let id { proxy.scrollTo(id, anchor: .center) } }
                }
                Divider()
                Text("\(hits.count) match\(hits.count == 1 ? "" : "es") · nothing leaves this Mac")
                    .font(.caption).foregroundStyle(.secondary).padding(8)
            }
        }
        .frame(width: 700, height: 480)
        .deskFloatingPanel()
        .padding(12)
        .deskClearPresentation()
        .onAppear {
            focused = true
            if !ui.searchSeed.isEmpty { query = ui.searchSeed; ui.searchSeed = ""; highlighted = hits.first?.id }
        }
        .onChange(of: query) { _, _ in highlighted = hits.first?.id }
    }

    private func move(_ delta: Int) {
        let ids = hits.map(\.id)
        guard !ids.isEmpty else { return }
        let current = highlighted.flatMap { ids.firstIndex(of: $0) } ?? -1
        highlighted = ids[max(0, min(ids.count - 1, current + delta))]
    }

    private func openHighlighted() {
        if let id = highlighted, let item = store.item(id: id) { open(item) } else if let first = hits.first { open(first.item) }
    }

    private func open(_ item: KnowledgeItem) {
        ui.open(item, favorites: store.favorites)
        dismiss()
    }
}

struct SearchHitRow: View {
    let hit: SearchHit
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(hit.item.title).font(.headline).foregroundStyle(.primary).lineLimit(1)
                Spacer()
                Text("matched \(hit.matchedField.label)").font(.caption2).foregroundStyle(.secondary)
            }
            if !hit.excerpt.isEmpty {
                Text(hit.excerpt).font(.callout).foregroundStyle(.secondary).lineLimit(2)
            }
            Text([hit.item.id, hit.item.dateText].joined(separator: "  ·  ")).font(.caption.monospaced()).foregroundStyle(.tertiary).lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(isHighlighted ? Palette.indigo.opacity(0.18) : Color.clear))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(hit.item.title). \(hit.excerpt)")
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
    }
}
