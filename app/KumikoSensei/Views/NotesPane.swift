import SwiftUI

struct NotesPane: View {
    @Environment(LibraryStore.self) private var store
    let item: KnowledgeItem?

    var body: some View {
        if let item, let root = store.rootURL {
            NotesEditor(item: item, root: root).id(item.id)
        } else {
            VStack(spacing: 10) {
                Image(systemName: "note.text").font(.inter(.title)).foregroundStyle(Palette.inkMuted)
                Text("Pick a note to jot down your thinking").font(.inter(.callout)).foregroundStyle(Palette.inkMuted).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(20)
        }
    }
}

private struct NotesEditor: View {
    let item: KnowledgeItem
    let root: URL
    @State private var text = ""
    @State private var error: String?
    @State private var saveTask: Task<Void, Never>?

    private var fileURL: URL { SessionNotes.url(for: item, root: root) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("My notes").font(.deskSection).foregroundStyle(Palette.ink)
                Spacer()
                Button { FolderAccess.reveal(fileURL) } label: { Image(systemName: "folder") }
                    .buttonStyle(.borderless)
                    .help("Reveal notes.md in Finder")
                    .disabled(!FileManager.default.fileExists(atPath: fileURL.path))
            }
            Text(LibraryScanner.relativePath(of: fileURL, from: root)).font(.caption.monospaced()).foregroundStyle(Palette.inkMuted).lineLimit(1).truncationMode(.middle)
            MarkdownEditor(text: $text)
                .background(RoundedRectangle(cornerRadius: 8).fill(Palette.cardRaised))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.rule, lineWidth: 1))
                .accessibilityLabel("Notes for \(item.title)")
            if let error { Text(error).font(.inter(.caption)).foregroundStyle(Palette.error) }
        }
        .padding(14)
        .onAppear { text = SessionNotes.load(for: item, root: root) }
        .onChange(of: text) { _, _ in scheduleSave() }
        .onDisappear { saveTask?.cancel(); save() }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            if !Task.isCancelled { save() }
        }
    }

    private func save() {
        do { try SessionNotes.save(text, for: item, root: root); error = nil } catch { self.error = error.localizedDescription }
    }
}
