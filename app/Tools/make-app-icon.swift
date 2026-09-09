import AppKit

let src = URL(fileURLWithPath: CommandLine.arguments[1])
let out = URL(fileURLWithPath: CommandLine.arguments[2])
let mode = CommandLine.arguments.count > 3 ? CommandLine.arguments[3] : "measure"
guard let image = NSImage(contentsOf: src), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { fatalError("cannot read") }
let w = cg.width, h = cg.height
var data = [UInt8](repeating: 0, count: w * h * 4)
let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
var minX = w, minY = h, maxX = 0, maxY = 0
for y in 0..<h { for x in 0..<w where data[(y * w + x) * 4 + 3] > 40 { minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y) } }
print("size \(w)x\(h) opaque bbox x:\(minX)-\(maxX) y:\(minY)-\(maxY)")
guard mode == "render" || mode == "render-transparent" else { exit(0) }
let side = CGFloat(max(maxX - minX, maxY - minY) + 1)
let bbox = CGRect(x: CGFloat(minX), y: CGFloat(h - 1 - maxY), width: CGFloat(maxX - minX + 1), height: CGFloat(maxY - minY + 1))
let square = CGRect(x: bbox.midX - side / 2, y: bbox.midY - side / 2, width: side, height: side)
let cropped = cg.cropping(to: square)!
let canvas = 1024
let outCtx = CGContext(data: nil, width: canvas, height: canvas, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
if mode == "render" {
    outCtx.setFillColor(CGColor(srgbRed: 0.93, green: 0.96, blue: 1.0, alpha: 1))
    outCtx.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
}
outCtx.interpolationQuality = .high
let bleed = mode == "render" ? 1.04 : 1.02
let drawSide = CGFloat(canvas) * bleed
outCtx.draw(cropped, in: CGRect(x: (CGFloat(canvas) - drawSide) / 2, y: (CGFloat(canvas) - drawSide) / 2, width: drawSide, height: drawSide))
let result = outCtx.makeImage()!
let rep = NSBitmapImageRep(cgImage: result)
try! rep.representation(using: .png, properties: [:])!.write(to: out)
print("wrote \(out.path)")
