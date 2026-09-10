import AppKit
import SwiftUI

struct LocalImage: View {
    let url: URL
    @State private var image: NSImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            } else if failed {
                EmptyNote(text: "The media file \(url.lastPathComponent) exists but could not be decoded.", tone: Palette.error)
            } else {
                ProgressView().frame(maxWidth: .infinity, minHeight: 120)
            }
        }
        .task(id: url) {
            let loaded = await Task.detached(priority: .userInitiated) { NSImage(contentsOf: url) }.value
            if let loaded { image = loaded } else { failed = true }
        }
    }
}

struct MediaSection: View {
    let item: KnowledgeItem
    @State private var selected: MediaAsset?
    @State private var inspecting: MediaAsset?
    @State private var givingFeedback = false

    private var current: MediaAsset? { selected ?? item.media.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(number: 2, title: "Visual explanation", subtitle: item.media.isEmpty ? nil : "\(item.media.count) file\(item.media.count == 1 ? "" : "s") in media/. Click the image to inspect it at full size.")
            if let asset = current {
                Button { inspecting = asset } label: {
                    LocalImage(url: asset.url)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Palette.cardRaised))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.rule, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Visual for \(item.title): \(asset.fileName). Activate to inspect at full size.")
                .accessibilityIdentifier("media.primary")
                HStack(spacing: 12) {
                    Text(asset.relativePath).font(.caption.monospaced()).foregroundStyle(Palette.inkMuted).lineLimit(1).truncationMode(.middle)
                    Spacer()
                    Button("Inspect") { inspecting = asset }
                    Button("Reveal in Finder") { FolderAccess.reveal(asset.url) }
                    Button { givingFeedback = true } label: { Label("Feedback", systemImage: "text.bubble") }
                        .help("Ask Kumiko-sensei to revise this image")
                        .accessibilityIdentifier("media.feedback")
                        .popover(isPresented: $givingFeedback, arrowEdge: .bottom) { MediaFeedbackPopover(asset: asset, item: item) }
                }
                .controlSize(.small)
                MediaFeedbackList(asset: asset, item: item)
                if item.media.count > 1 {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(item.media) { thumb in
                                Button { selected = thumb } label: {
                                    LocalImage(url: thumb.url)
                                        .frame(width: 96, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(thumb.id == asset.id ? Palette.primary : Palette.rule, lineWidth: thumb.id == asset.id ? 2 : 1))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Show \(thumb.fileName)")
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            } else {
                EmptyNote(text: item.kind == .inboxHandoff
                          ? "This handoff is still in the inbox; no visual exists until Kumiko-sensei processes it."
                          : "No visual has been generated for this session. The written knowledge below stands on its own.")
            }
        }
        .sheet(item: $inspecting) { asset in ImageInspector(asset: asset, title: item.title) }
    }
}

struct ImageInspector: View {
    let asset: MediaAsset
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var actualSize = false
    @State private var image: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.inter(.headline, .semibold))
                    Text(asset.relativePath).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Zoom", selection: $actualSize) {
                    Text("Fit").tag(false)
                    Text("Actual size").tag(true)
                }
                .pickerStyle(.segmented).frame(width: 180).labelsHidden()
                Button("Reveal in Finder") { FolderAccess.reveal(asset.url) }
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
            .padding(14)
            Divider()
            Group {
                if let image {
                    if actualSize {
                        ScrollView([.horizontal, .vertical]) {
                            Image(nsImage: image).frame(width: image.size.width, height: image.size.height)
                        }
                    } else {
                        Image(nsImage: image).resizable().aspectRatio(contentMode: .fit).padding(16)
                    }
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Palette.surface)
        }
        .frame(minWidth: 900, idealWidth: 1200, minHeight: 640, idealHeight: 860)
        .task { image = await Task.detached { NSImage(contentsOf: asset.url) }.value }
        .accessibilityLabel("Full-size visual: \(asset.fileName)")
    }
}

struct MediaFeedbackPopover: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let asset: MediaAsset
    let item: KnowledgeItem
    @State private var text = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Feedback on \(asset.fileName)").font(.inter(.headline, .semibold)).foregroundStyle(Palette.ink)
            Text("Saved as an open item in revisions.md. Kumiko-sensei reads it on the next relay and regenerates only this image.").font(.inter(.caption)).foregroundStyle(Palette.inkMuted).fixedSize(horizontal: false, vertical: true)
            TextEditor(text: $text)
                .font(.inter())
                .frame(height: 110)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Palette.cardRaised))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Palette.rule, lineWidth: 1))
                .accessibilityLabel("Feedback for \(asset.fileName)")
            HStack {
                if let error { Text(error).font(.inter(.caption)).foregroundStyle(Palette.error) }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Save Feedback") {
                    do { try MediaFeedback.append(text, for: asset, in: item); store.rescan(); dismiss() } catch { self.error = error.localizedDescription }
                }
                .keyboardShortcut(.defaultAction).buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 380)
    }
}

struct MediaFeedbackList: View {
    @Environment(LibraryStore.self) private var store
    let asset: MediaAsset
    let item: KnowledgeItem
    @State private var copied = false

    var body: some View {
        let entries = MediaFeedback.entries(for: asset, in: item)
        if !entries.isEmpty {
            Panel(fill: entries.contains(where: \.isOpen) ? Palette.errorWash : Palette.card) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Feedback for this image").font(.inter(.headline, .semibold)).foregroundStyle(Palette.ink)
                    ForEach(entries) { entry in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: entry.isOpen ? "circle" : "checkmark.circle.fill").foregroundStyle(entry.isOpen ? Palette.error : Palette.secondary).font(.inter(.caption))
                            Text(entry.text).font(.inter(.callout)).foregroundStyle(entry.isOpen ? Palette.ink : Palette.inkMuted).textSelection(.enabled)
                        }
                    }
                    if entries.contains(where: \.isOpen), let root = store.rootURL {
                        Divider()
                        HStack {
                            Text("Run from the source repo to hand the open items to Kumiko-sensei:").font(.inter(.caption)).foregroundStyle(Palette.inkMuted)
                            Spacer()
                            Button(copied ? "Copied" : "Copy relay command") {
                                FolderAccess.copyToPasteboard(MediaFeedback.relayCommand(root: root, item: item))
                                copied = true
                                Task { try? await Task.sleep(for: .seconds(2)); copied = false }
                            }
                            .controlSize(.small)
                        }
                        Text(MediaFeedback.relayCommand(root: root, item: item)).font(.caption.monospaced()).foregroundStyle(Palette.inkMuted).textSelection(.enabled).lineLimit(2).truncationMode(.middle)
                    }
                }
            }
        }
    }
}
