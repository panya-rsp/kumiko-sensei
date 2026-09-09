import AppKit

func render(_ path: String, title: String, left: String, right: String, accent: NSColor) {
    let size = NSSize(width: 1400, height: 900)
    let image = NSImage(size: size)
    image.lockFocus()
    NSColor(srgbRed: 0.97, green: 0.95, blue: 0.92, alpha: 1).setFill()
    NSRect(origin: .zero, size: size).fill()
    NSColor(srgbRed: 0.20, green: 0.25, blue: 0.48, alpha: 1).setFill()
    NSRect(x: 0, y: size.height - 120, width: size.width, height: 120).fill()
    let titleAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 44, weight: .semibold), .foregroundColor: NSColor.white]
    NSString(string: title).draw(at: NSPoint(x: 60, y: size.height - 84), withAttributes: titleAttrs)
    let cardAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 30, weight: .medium), .foregroundColor: NSColor(srgbRed: 0.12, green: 0.13, blue: 0.2, alpha: 1)]
    for (index, text) in [left, right].enumerated() {
        let rect = NSRect(x: 60 + CGFloat(index) * 660, y: 120, width: 620, height: 620)
        let path = NSBezierPath(roundedRect: rect, xRadius: 24, yRadius: 24)
        NSColor.white.setFill(); path.fill()
        (index == 0 ? NSColor(srgbRed: 0.77, green: 0.39, blue: 0.30, alpha: 1) : accent).setStroke(); path.lineWidth = 6; path.stroke()
        NSString(string: text).draw(in: rect.insetBy(dx: 40, dy: 40), withAttributes: cardAttrs)
    }
    image.unlockFocus()
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else { fatalError("render failed") }
    try! png.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

let base = CommandLine.arguments[1]
let green = NSColor(srgbRed: 0.23, green: 0.48, blue: 0.30, alpha: 1)
render("\(base)/sessions/2026-08-14--sample-edge-swipe-review-pack/media/v1-pr-review-pack.png",
       title: "Edge swipe: who owns the gesture?",
       left: "BEFORE\n\nOne recognizer on UIWindow\nHandlers registry → handlers.last\nSwipe dismisses the wrong sheet",
       right: "AFTER\n\nRecognizer on presentingViewController.view\nNo shared registry\nSwipe dismisses the topmost sheet only",
       accent: green)
render("\(base)/sessions/2026-08-28--sample-retry-lesson/media/v1/01-problem.png",
       title: "1 · Problem: synchronized retries",
       left: "Deploy restarts all consumers\nin the same second",
       right: "Every consumer sleeps exactly 5 s\nand retries together",
       accent: NSColor(srgbRed: 0.20, green: 0.25, blue: 0.48, alpha: 1))
render("\(base)/sessions/2026-08-28--sample-retry-lesson/media/v1/02-mechanism.png",
       title: "2 · Mechanism: full jitter",
       left: "delay = base × 2^attempt",
       right: "delay = random(0 … base × 2^attempt)\nConsumers desynchronize",
       accent: green)
