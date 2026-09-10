import AppKit
import SwiftUI

enum DevLaunch {
    static func value(for flag: String) -> String? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: flag), index + 1 < args.count else { return nil }
        return args[index + 1]
    }

    static var libraryPath: String? { value(for: "--library") }
    static var snapshotDirectory: String? { value(for: "--snapshot-dir") }
    static var useSampleLibrary: Bool { CommandLine.arguments.contains("--sample-library") }
    static var forceDark: Bool { CommandLine.arguments.contains("--dark") }
}

@MainActor
enum SnapshotRunner {
    static func runIfRequested(store: LibraryStore, ui: UIState) async {
        guard let directory = DevLaunch.snapshotDirectory else { return }
        let out = URL(fileURLWithPath: directory, isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        NSApp.activate(ignoringOtherApps: true)
        try? await Task.sleep(for: .seconds(3))
        NSLog("SnapshotRunner: state=\(String(describing: store.state)) items=\(store.items.count) windows=\(NSApp.windows.count)")
        let sessions = store.items.filter { $0.kind == .session }
        if let first = sessions.first(where: { !$0.media.isEmpty }) ?? sessions.first { ui.open(first, favorites: store.favorites) }
        try? await Task.sleep(for: .seconds(2.5))
        capture(primaryWindow, to: out.appending(path: "01-library-and-detail.png"))
        if let pack = store.items.first(where: { $0.isPRReviewPack && $0.prReviewPack != nil }) {
            ui.filter = .prReviewPacks
            ui.selectedItemID = pack.id
            try? await Task.sleep(for: .seconds(2))
            capture(primaryWindow, to: out.appending(path: "02-pr-review-pack.png"))
        }
        if let inbox = store.items.first(where: { $0.kind == .inboxHandoff }) {
            ui.filter = .inbox
            ui.selectedItemID = inbox.id
            try? await Task.sleep(for: .seconds(2))
            capture(primaryWindow, to: out.appending(path: "03-inbox.png"))
        }
        ui.filter = .all
        ui.searchSeed = "replace"
        ui.showSearch = true
        try? await Task.sleep(for: .seconds(2))
        capture(sheetWindow ?? primaryWindow, to: out.appending(path: "04-search.png"))
        ui.showSearch = false
        try? await Task.sleep(for: .seconds(1))
        ui.showComposer = true
        try? await Task.sleep(for: .seconds(2))
        capture(sheetWindow ?? primaryWindow, to: out.appending(path: "05-composer.png"))
        ui.showComposer = false
        try? await Task.sleep(for: .seconds(1))
        ui.showAsk = true
        try? await Task.sleep(for: .seconds(2))
        capture(sheetWindow ?? primaryWindow, to: out.appending(path: "06-ask-kumiko.png"))
        ui.showAsk = false
        if let first = sessions.first(where: { !$0.media.isEmpty }) ?? sessions.first {
            ui.open(first, favorites: store.favorites)
            ui.showNotes = true
            try? await Task.sleep(for: .seconds(2))
            capture(primaryWindow, to: out.appending(path: "07-notes-pane.png"))
        }
        try? await Task.sleep(for: .seconds(0.5))
        NSApp.terminate(nil)
    }

    static var primaryWindow: NSWindow? {
        NSApp.windows.first { $0.isVisible && $0.contentView != nil && $0.sheetParent == nil && $0.frame.width > 600 }
    }

    static var sheetWindow: NSWindow? {
        NSApp.windows.first { $0.isVisible && $0.sheetParent != nil } ?? primaryWindow?.attachedSheet
    }

    static func capture(_ window: NSWindow?, to url: URL) {
        guard let window, let content = window.contentView else { NSLog("SnapshotRunner: no window for \(url.lastPathComponent)"); return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-x", "-o", "-l", "\(window.windowNumber)", url.path]
        try? process.run()
        process.waitUntilExit()
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        NSLog("SnapshotRunner: screencapture window \(window.windowNumber) -> \(url.lastPathComponent) (\(size) bytes)")
        let fallback = url.deletingPathExtension().appendingPathExtension("offscreen.png")
        cacheDisplayCapture(window: window, content: content, to: size > 0 ? fallback : url)
    }

    static func cacheDisplayCapture(window: NSWindow, content: NSView, to url: URL) {
        let view = content.superview ?? content
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        let image = NSImage(size: view.bounds.size)
        image.addRepresentation(rep)
        let composed = NSImage(size: view.bounds.size)
        composed.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: view.bounds.size))
        for glass in views(in: content, matching: { String(describing: type(of: $0)).contains("GlassEffectView") }) {
            let rect = view.convert(glass.bounds, from: glass)
            NSColor(hex: 0xF3EEE4).withAlphaComponent(0.92).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 14, yRadius: 14).fill()
        }
        for host in views(in: content, matching: { String(describing: type(of: $0)).contains("SidebarStyleContext") }) {
            guard let hostRep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { continue }
            host.cacheDisplay(in: host.bounds, to: hostRep)
            let hostImage = NSImage(size: host.bounds.size)
            hostImage.addRepresentation(hostRep)
            hostImage.draw(in: view.convert(host.bounds, from: host))
        }
        composed.unlockFocus()
        guard let tiff = composed.tiffRepresentation, let final = NSBitmapImageRep(data: tiff), let data = final.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
    }

    static func dump(_ view: NSView, depth: Int) {
        guard depth < 9 else { return }
        NSLog("SnapshotRunner: \(String(repeating: "  ", count: depth))\(type(of: view)) \(NSStringFromRect(view.frame)) layer=\(view.layer != nil)")
        view.subviews.forEach { dump($0, depth: depth + 1) }
    }

    static func views(in root: NSView, matching predicate: (NSView) -> Bool) -> [NSView] {
        var found: [NSView] = []
        func walk(_ view: NSView) {
            if predicate(view) { found.append(view); return }
            view.subviews.forEach(walk)
        }
        walk(root)
        return found
    }
}
