import SwiftUI

struct LibraryListView: View {
    @Environment(LibraryStore.self) private var store
    let filter: SidebarFilter
    @Binding var selection: String?

    private var items: [KnowledgeItem] {
        store.items.filter { filter.matches($0, favorites: store.favorites) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if store.state == .loading && store.items.isEmpty {
                ProgressView("Reading library…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: filter.systemImage)
                } description: {
                    Text(emptyDescription)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(items, selection: $selection) { item in
                    KnowledgeCard(item: item, isFavorite: store.favorites.contains(item.id))
                        .tag(item.id)
                        .accessibilityIdentifier("card.\(item.id)")
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                        .contextMenu {
                            Button(store.favorites.contains(item.id) ? "Remove from Favorites" : "Add to Favorites") { store.toggleFavorite(item.id) }
                            Button("Reveal in Finder") { FolderAccess.reveal(item.primaryFileURL) }
                            Button("Open Source File") { FolderAccess.openInEditor(item.primaryFileURL) }
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .deskColumnBackground()
        .navigationTitle(filter.title)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(filter.title).font(.deskSection).foregroundStyle(Palette.ink)
            Spacer()
            Text("\(items.count) \(items.count == 1 ? "note" : "notes")").font(.caption).foregroundStyle(Palette.inkMuted)
            if !store.warnings.isEmpty {
                Image(systemName: "info.circle").foregroundStyle(Palette.inkMuted)
                    .help(store.warnings.joined(separator: "\n"))
                    .accessibilityLabel("Scan notes: \(store.warnings.joined(separator: ". "))")
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var emptyTitle: String {
        switch filter {
        case .inbox: return "Inbox is clear"
        case .favorites: return "No favorites yet"
        case .prReviewPacks: return "No PR review packs yet"
        default: return "Nothing here yet"
        }
    }

    private var emptyDescription: String {
        switch filter {
        case .inbox: return "Handoffs waiting in handoffs/inbox/ appear here until Kumiko-sensei processes them."
        case .favorites: return "Star a note from its detail view or the context menu to keep it close."
        case .prReviewPacks: return "Compose a handoff with the pr-review-pack format to prepare one."
        default: return "Nothing in the library matches this view."
        }
    }
}

struct KnowledgeCard: View {
    let item: KnowledgeItem
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.title).font(.system(.headline, design: .rounded, weight: .semibold)).foregroundStyle(Palette.ink).lineLimit(2)
                Spacer(minLength: 4)
                if isFavorite { Image(systemName: "star.fill").font(.caption).foregroundStyle(Palette.sun) }
            }
            if let takeaway = item.takeaway {
                Text(InlineMarkdown.attributed(takeaway)).font(.subheadline).foregroundStyle(Palette.inkMuted).lineLimit(2)
            } else {
                Text("No one-line takeaway recorded yet.").font(.subheadline).italic().foregroundStyle(Palette.inkMuted.opacity(0.8))
            }
            HStack(spacing: 6) {
                Text(metaLine).font(.caption).foregroundStyle(Palette.inkMuted).lineLimit(1)
                Spacer()
                if item.isPRReviewPack { ReviewPackTag() }
                StatusMark(completion: item.completion)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.rule, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var metaLine: String {
        [item.repositoryName, item.dateText, item.format].compactMap { $0 }.joined(separator: "  ·  ")
    }

    private var accessibilityText: String {
        var parts = [item.title]
        if let takeaway = item.takeaway { parts.append(takeaway) }
        parts.append(metaLine)
        parts.append(item.completion.label)
        if item.isPRReviewPack { parts.append("PR review pack") }
        if isFavorite { parts.append("Favorite") }
        return parts.joined(separator: ". ")
    }
}
