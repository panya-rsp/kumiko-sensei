import Foundation

enum Fixtures {
    static var previewLibrary: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "PreviewLibrary")
    }

    static var realLibrary: URL? {
        let url = previewLibrary.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return FileManager.default.fileExists(atPath: url.appending(path: "sessions").path) ? url : nil
    }

    static func temporaryCopyOfPreviewLibrary() throws -> URL {
        let destination = FileManager.default.temporaryDirectory.appending(path: "KumikoTests-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: previewLibrary, to: destination)
        return destination
    }
}
