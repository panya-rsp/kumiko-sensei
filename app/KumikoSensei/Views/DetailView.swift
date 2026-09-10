import SwiftUI

struct DetailView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(UIState.self) private var ui
    let item: KnowledgeItem
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header
                takeaway
                MediaSection(item: item)
                explanation
                reviewGuide
                evidence
                files
            }
            .padding(.horizontal, 32).padding(.vertical, 28)
            .frame(maxWidth: 880, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .deskColumnBackground()
        .navigationTitle(item.title)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button { store.toggleFavorite(item.id) } label: {
                    Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? Palette.accentYellow : .primary)
                }
                .keyboardShortcut("d")
                .help(isFavorite ? "Remove from Favorites (⌘D)" : "Add to Favorites (⌘D)")
            }
        }
    }

    private var isFavorite: Bool { store.favorites.contains(item.id) }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text((item.kind == .session ? "Session" : "Inbox handoff").uppercased()).font(.deskLabel).tracking(0.8).foregroundStyle(Palette.secondary)
                if item.isPRReviewPack { ReviewPackTag() }
                Spacer()
                StatusMark(completion: item.completion)
            }
            Text(item.title).font(.deskTitle).foregroundStyle(Palette.ink).textSelection(.enabled)
            HStack(spacing: 14) {
                if let repo = item.sourceRepo { MetaChip(systemImage: "shippingbox", text: repo) }
                MetaChip(systemImage: "calendar", text: item.dateText)
                if let format = item.format { MetaChip(systemImage: "rectangle.3.group", text: format) }
                if let audience = item.audience { MetaChip(systemImage: "person", text: audience) }
                if let status = item.status { MetaChip(systemImage: "circle.dotted", text: status) }
            }
            HStack(spacing: 10) {
                Button { FolderAccess.reveal(item.kind == .session ? item.folderURL : item.primaryFileURL) } label: { Label("Reveal in Finder", systemImage: "folder") }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                Button { FolderAccess.openInEditor(item.primaryFileURL) } label: { Label("Open Source", systemImage: "doc.text") }
                    .keyboardShortcut("o")
                if let artifact = item.artifactURL {
                    Button { FolderAccess.openInEditor(artifact) } label: { Label("Open Live Artifact", systemImage: "safari") }
                }
                Button { ui.showAsk = true } label: { Label("Ask Kumiko about this", systemImage: "bubble.left.and.text.bubble.right") }
            }
            .controlSize(.regular)
            if !item.identifiers.isEmpty {
                Text(item.identifiers.prefix(8).joined(separator: "   ")).font(.caption.monospaced()).foregroundStyle(Palette.inkMuted).textSelection(.enabled)
                    .accessibilityLabel("Identifiers: \(item.identifiers.prefix(8).joined(separator: ", "))")
            }
        }
    }

    private var takeaway: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(number: 1, title: "Takeaway")
            if let text = item.takeaway {
                InlineText(text: text).font(.deskTakeaway).foregroundStyle(Palette.ink).lineSpacing(4).textSelection(.enabled)
            } else {
                EmptyNote(text: "No one-line takeaway is recorded in handoff.md or visual-brief.md. Add one under “# One-line takeaway”.", tone: Palette.error)
            }
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(number: 3, title: "Why and what changed", subtitle: item.handoff != nil ? "From \(item.handoff?.fileName ?? "handoff.md")" : item.visualBrief != nil ? "From visual-brief.md" : nil)
            let sections = item.explanationSections
            if sections.isEmpty {
                EmptyNote(text: "No narrative sections were found. The session may hold only media or an empty template.")
            } else {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title).font(.inter(.headline, .semibold)).foregroundStyle(Palette.ink).accessibilityAddTraits(.isHeader)
                        MarkdownView(markdown: section.body)
                    }
                    .padding(.bottom, 6)
                }
            }
        }
    }

    private var reviewGuide: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: 4, title: "Review guide", subtitle: item.isPRReviewPack ? "Ready for reviewers. Exact paths, symbols, and caveats stay in selectable text." : nil)
            let sections = item.reviewGuideSections
            if sections.isEmpty {
                EmptyNote(text: item.isPRReviewPack
                          ? "Marked as a PR review pack, but pr-review-pack.md has not been written yet."
                          : "Not a PR review pack. Compose one with the pr-review-pack format when a change needs reviewer context.")
            } else {
                Panel(fill: item.isPRReviewPack ? Palette.primaryWash : Palette.card) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(section.title).font(.inter(.headline, .semibold)).foregroundStyle(Palette.primary).accessibilityAddTraits(.isHeader)
                                MarkdownView(markdown: section.body)
                            }
                        }
                    }
                }
            }
            if item.isPRReviewPack, item.prReviewPack != nil {
                relayBlock
            }
        }
    }

    private var relayBlock: some View {
        Panel {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Claude Code relay").font(.inter(.headline, .semibold)).foregroundStyle(Palette.ink)
                    Spacer()
                    Button(copied ? "Copied" : "Copy relay text") {
                        FolderAccess.copyToPasteboard(item.relayText)
                        copied = true
                        Task { try? await Task.sleep(for: .seconds(2)); copied = false }
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
                Text(item.relayText).font(.inter(.callout)).foregroundStyle(Palette.inkMuted).textSelection(.enabled)
                if let relay = item.relaySection, !relay.isEmpty {
                    Divider()
                    Text("From pr-review-pack.md").font(.inter(.caption)).foregroundStyle(Palette.inkMuted)
                    MarkdownView(markdown: relay.body)
                }
                Text("Kumiko-sensei has no GitHub access. Paste this into your authorized Claude Code session; nothing is sent from this app.")
                    .font(.inter(.caption)).foregroundStyle(Palette.inkMuted)
            }
        }
    }

    private var evidence: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: 5, title: "Evidence", subtitle: "What the source files cite. A listed check is a claim to verify, not proof that it ran.")
            HStack(spacing: 8) {
                Circle().fill(item.completion.color).frame(width: 8, height: 8)
                Text(verificationSummary).font(.inter(.callout)).foregroundStyle(Palette.ink)
            }
            if item.evidence.isEmpty {
                EmptyNote(text: "No “Evidence to verify” section was found in the source files.")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(item.evidence) { entry in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: entry.isUnverified ? "questionmark.circle" : "doc.text.magnifyingglass")
                                .foregroundStyle(entry.isUnverified ? Palette.error : Palette.primary)
                                .accessibilityLabel(entry.isUnverified ? "Unverified or proposed" : "Cited evidence")
                            MarkdownView(markdown: entry.text)
                        }
                    }
                }
                Text("Coral marks evidence the text itself calls unverified, proposed, or not yet performed.").font(.inter(.caption)).foregroundStyle(Palette.inkMuted)
            }
            if !item.accuracyConstraints.isEmpty {
                Panel(fill: Palette.errorWash) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Must not be inferred").font(.inter(.headline, .semibold)).foregroundStyle(Palette.error)
                        ForEach(Array(item.accuracyConstraints.enumerated()), id: \.offset) { _, line in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("•").foregroundStyle(Palette.error)
                                MarkdownView(markdown: line)
                            }
                        }
                    }
                }
            }
        }
    }

    private var verificationSummary: String {
        switch item.completion {
        case .delivered: return "Visual brief marked generated and media is present on disk."
        case .inProgress: return item.media.isEmpty ? "Session exists but no media has been delivered yet." : "Media exists, but the visual brief does not mark this session as generated."
        case .needsAttention: return "Waiting in the inbox. Nothing has been processed or verified."
        case .openQuestion: return "An open question. No answer has been recorded yet."
        }
    }

    private var files: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(number: 6, title: "Files on disk", subtitle: LibraryScanner.relativePath(of: item.kind == .session ? item.folderURL : item.primaryFileURL, from: store.rootURL ?? item.folderURL))
            VStack(spacing: 0) {
                if item.kind == .session {
                    fileRow(url: item.folderURL, label: "Session folder", icon: "folder")
                    Divider()
                }
                ForEach(Array(item.sourceFiles.enumerated()), id: \.offset) { index, url in
                    fileRow(url: url, label: url.lastPathComponent, icon: "doc.text")
                    if index < item.sourceFiles.count - 1 || !item.media.isEmpty || item.artifactURL != nil { Divider() }
                }
                ForEach(Array(item.media.enumerated()), id: \.offset) { index, asset in
                    fileRow(url: asset.url, label: asset.relativePath.components(separatedBy: "/").dropFirst(2).joined(separator: "/"), icon: "photo")
                    if index < item.media.count - 1 || item.artifactURL != nil { Divider() }
                }
                if let artifact = item.artifactURL {
                    fileRow(url: artifact, label: "artifact/index.html", icon: "safari")
                }
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.rule, lineWidth: 1))
            if item.sourceFiles.isEmpty {
                EmptyNote(text: "No Markdown source files were found for this entry.", tone: Palette.error)
            }
        }
    }

    private func fileRow(url: URL, label: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Palette.primary).frame(width: 18)
            Text(label).font(.callout.monospaced()).foregroundStyle(Palette.ink).lineLimit(1).truncationMode(.middle)
            Spacer()
            Button("Reveal") { FolderAccess.reveal(url) }.accessibilityLabel("Reveal \(label) in Finder")
            Button("Open") { FolderAccess.openInEditor(url) }.accessibilityLabel("Open \(label) in the default app")
        }
        .controlSize(.small)
        .padding(.horizontal, 12).padding(.vertical, 8)
    }
}
