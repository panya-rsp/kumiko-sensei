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
                EmptyNote(text: "The media file \(url.lastPathComponent) exists but could not be decoded.", tone: Palette.coral)
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
                }
                .controlSize(.small)
                if item.media.count > 1 {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(item.media) { thumb in
                                Button { selected = thumb } label: {
                                    LocalImage(url: thumb.url)
                                        .frame(width: 96, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(thumb.id == asset.id ? Palette.indigo : Palette.rule, lineWidth: thumb.id == asset.id ? 2 : 1))
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
                    Text(title).font(.headline)
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
            .background(Palette.paper)
        }
        .frame(minWidth: 900, idealWidth: 1200, minHeight: 640, idealHeight: 860)
        .task { image = await Task.detached { NSImage(contentsOf: asset.url) }.value }
        .accessibilityLabel("Full-size visual: \(asset.fileName)")
    }
}
