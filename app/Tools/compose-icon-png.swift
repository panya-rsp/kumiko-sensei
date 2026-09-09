import AppKit

let bgURL = URL(fileURLWithPath: CommandLine.arguments[1])
let fgURL = URL(fileURLWithPath: CommandLine.arguments[2])
let out = URL(fileURLWithPath: CommandLine.arguments[3])
func load(_ url: URL) -> CGImage { NSImage(contentsOf: url)!.cgImage(forProposedRect: nil, context: nil, hints: nil)! }
let canvas: CGFloat = 1024
let art = CGRect(x: 100, y: 100, width: 824, height: 824)
let ctx = CGContext(data: nil, width: Int(canvas), height: Int(canvas), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.interpolationQuality = .high
ctx.addPath(CGPath(roundedRect: art, cornerWidth: 185.4, cornerHeight: 185.4, transform: nil))
ctx.clip()
ctx.draw(load(bgURL), in: art)
let scale = CommandLine.arguments.count > 4 ? CGFloat(Double(CommandLine.arguments[4])!) : 1
let tx = CommandLine.arguments.count > 5 ? CGFloat(Double(CommandLine.arguments[5])!) : 0
let ty = CommandLine.arguments.count > 6 ? CGFloat(Double(CommandLine.arguments[6])!) : 0
let fgSide = art.width * scale
let fgRect = CGRect(x: art.midX - fgSide / 2 + tx * art.width / canvas, y: art.midY - fgSide / 2 - ty * art.height / canvas, width: fgSide, height: fgSide)
ctx.draw(load(fgURL), in: fgRect)
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: out)
print("wrote \(out.path)")
