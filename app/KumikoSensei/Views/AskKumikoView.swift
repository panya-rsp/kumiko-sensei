import SwiftUI

struct AskKumikoView: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let preselectedID: String?
    @State private var question = ""
    @State private var selected: Set<String> = []
    @State private var filter = ""
    @State private var error: String?
    @State private var result: AskKumikoDraft?
    @State private var copied = false

    private var candidates: [KnowledgeItem] {
        let trimmed = filter.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return store.items }
        return store.search(trimmed).map(\.item)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                MascotBadge(size: 64).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ask Kumiko").font(.deskTitle).foregroundStyle(Palette.ink)
                    Text("Writes a local question draft with the sessions and evidence you pick. No model is called from this app; you hand the prompt to Kumiko-sensei or Claude Code yourself.")
                        .font(.inter(.callout)).foregroundStyle(Palette.inkMuted).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            Divider()
            if let result { resultView(result) } else { composer }
        }
        .frame(width: 680, height: 600)
        .background(Palette.surface)
        .onAppear { if let preselectedID { selected = [preselectedID] } }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Question").font(.inter(.callout)).foregroundStyle(Palette.inkMuted)
                TextEditor(text: $question)
                    .font(.inter())
                    .frame(height: 96)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Palette.cardRaised))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.rule, lineWidth: 1))
                    .accessibilityLabel("Question for Kumiko")
            }
            HStack {
                Text("Attach sessions (\(selected.count) selected)").font(.inter(.callout)).foregroundStyle(Palette.inkMuted)
                Spacer()
                TextField("Filter", text: $filter).textFieldStyle(.roundedBorder).frame(width: 220)
            }
            List(candidates) { item in
                Toggle(isOn: Binding(get: { selected.contains(item.id) }, set: { on in if on { selected.insert(item.id) } else { selected.remove(item.id) } })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).font(.inter(.callout)).foregroundStyle(Palette.ink).lineLimit(1)
                        Text(item.id).font(.caption.monospaced()).foregroundStyle(Palette.inkMuted).lineLimit(1)
                    }
                }
                .toggleStyle(.checkbox)
            }
            .listStyle(.inset)
            .frame(minHeight: 160)
            HStack {
                if let error { Text(error).font(.inter(.callout)).foregroundStyle(Palette.error) }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Create Question Draft") { create() }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                    .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
    }

    private func create() {
        guard let root = store.rootURL else { error = "No library is open."; return }
        let items = store.items.filter { selected.contains($0.id) }
        do {
            result = try HandoffComposer(root: root).writeQuestion(question, about: items)
            error = nil
            store.rescan()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func resultView(_ draft: AskKumikoDraft) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Circle().fill(Palette.error).frame(width: 8, height: 8)
                Text("Question saved to \(LibraryScanner.relativePath(of: draft.fileURL, from: store.rootURL ?? draft.fileURL))").font(.inter(.headline, .semibold)).foregroundStyle(Palette.ink)
            }
            Text("It appears in the inbox as an open question until an answer is saved back into the library.").font(.inter(.callout)).foregroundStyle(Palette.inkMuted)
            Panel {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt to hand over").font(.inter(.headline, .semibold)).foregroundStyle(Palette.ink)
                    Text(draft.prompt).font(.inter(.callout)).foregroundStyle(Palette.inkMuted).textSelection(.enabled)
                }
            }
            HStack {
                Button(copied ? "Copied" : "Copy Prompt") {
                    FolderAccess.copyToPasteboard(draft.prompt)
                    copied = true
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                Button("Reveal in Finder") { FolderAccess.reveal(draft.fileURL) }
                Button("Open in Editor") { FolderAccess.openInEditor(draft.fileURL) }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding(20)
    }
}
