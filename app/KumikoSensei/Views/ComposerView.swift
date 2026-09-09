import SwiftUI

struct ComposerView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft = HandoffDraft()
    @State private var slugEdited = false
    @State private var error: String?
    @State private var created: URL?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("New handoff").font(.deskTitle).foregroundStyle(Palette.ink)
                    Text("Writes a template-compatible Markdown file into handoffs/inbox/. No GitHub, no model.").font(.caption).foregroundStyle(Palette.inkMuted)
                }
                Spacer()
                MascotBadge(size: 52).accessibilityHidden(true)
            }
            .padding(20)
            Divider()
            if let created {
                createdView(created)
            } else {
                form
            }
        }
        .frame(width: 680, height: 640)
        .background(Palette.paper)
    }

    private var form: some View {
        VStack(spacing: 0) {
            Form {
                Section("Basics") {
                    TextField("Title", text: $draft.title)
                        .onChange(of: draft.title) { _, value in if !slugEdited { draft.slug = HandoffComposer.slugify(value) } }
                    TextField("Slug", text: $draft.slug)
                        .onChange(of: draft.slug) { _, value in if value != HandoffComposer.slugify(draft.title) { slugEdited = true } }
                        .font(.body.monospaced())
                    TextField("Source repository", text: $draft.sourceRepo, prompt: Text("rentspree-frontend"))
                    TextField("Branch or commit", text: $draft.branchOrCommit)
                    Picker("Format", selection: $draft.format) {
                        ForEach(HandoffFormat.allCases) { Text($0.label).tag($0) }
                    }
                    TextField("Audience", text: $draft.audience)
                }
                Section("Knowledge") {
                    TextField("One-line takeaway", text: $draft.takeaway, axis: .vertical).lineLimit(2...4)
                    editor("Goal and context", $draft.context)
                    editor("The story: what happened and why", $draft.story)
                    editor("Before → after", $draft.beforeAfter)
                    editor("Evidence to verify (one per line)", $draft.evidence)
                    editor("Key decisions and trade-offs", $draft.decisions)
                    editor("Caveats and non-goals", $draft.caveats)
                    editor("Visual request", $draft.visualRequest)
                }
                if draft.format == .prReviewPack {
                    Section("PR review pack") {
                        TextField("Reviewer takeaway (problem + decision + outcome)", text: $draft.reviewerTakeaway, axis: .vertical).lineLimit(2...4)
                        editor("Why this matters", $draft.whyItMatters)
                        editor("Review focus (2–4 paths, symbols, invariants, or risks, one per line)", $draft.reviewFocus)
                        TextField("PR placement (top of new or existing PR description)", text: $draft.prPlacement, axis: .vertical).lineLimit(1...3)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            Divider()
            HStack {
                if let error { Text(error).font(.callout).foregroundStyle(Palette.coral) }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Create Handoff") { create() }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                    .disabled(draft.title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)
        }
    }

    private func editor(_ label: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.callout).foregroundStyle(Palette.inkMuted)
            TextEditor(text: text)
                .font(.body)
                .frame(minHeight: 54)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Palette.cardRaised))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.rule, lineWidth: 1))
                .accessibilityLabel(label)
        }
    }

    private func create() {
        guard let root = store.rootURL else { error = "No library is open."; return }
        do {
            created = try HandoffComposer(root: root).write(draft)
            error = nil
            store.rescan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func createdView(_ url: URL) -> some View {
        let relative = LibraryScanner.relativePath(of: url, from: store.rootURL ?? url)
        let prompt = "Open Cheatbook in Codex and ask: “Process `\(relative)` and create the requested visual.”"
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Circle().fill(Palette.moss).frame(width: 8, height: 8)
                Text("Created \(relative)").font(.headline).foregroundStyle(Palette.ink)
            }
            Text("The file is now in the inbox and will appear under “Inbox / needs attention”. Fill in anything you skipped in your editor, then hand it to Kumiko-sensei.")
                .font(.callout).foregroundStyle(Palette.inkMuted)
            Panel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next step").font(.headline).foregroundStyle(Palette.ink)
                    Text(prompt).font(.callout).foregroundStyle(Palette.inkMuted).textSelection(.enabled)
                    if draft.format == .prReviewPack {
                        Text("After Kumiko-sensei returns pr-review-pack.md, the session's detail view offers the Claude Code relay text for the live PR.")
                            .font(.caption).foregroundStyle(Palette.inkMuted)
                    }
                }
            }
            HStack {
                Button("Copy Prompt") { FolderAccess.copyToPasteboard(prompt) }
                Button("Reveal in Finder") { FolderAccess.reveal(url) }
                Button("Open in Editor") { FolderAccess.openInEditor(url) }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding(20)
    }
}
