import AppKit
import SwiftUI

enum Palette {
    static let paper = dynamic(light: 0xF7F3EC, dark: 0x1E1C1A)
    static let card = dynamic(light: 0xFFFDF9, dark: 0x2A2724)
    static let cardRaised = dynamic(light: 0xFFFFFF, dark: 0x332F2A)
    static let ink = dynamic(light: 0x1F2233, dark: 0xEDE7DC)
    static let inkMuted = dynamic(light: 0x5F6274, dark: 0xB3ADA2)
    static let indigo = dynamic(light: 0x2E3C7E, dark: 0xA3B1F0)
    static let indigoWash = dynamic(light: 0xE8ECF9, dark: 0x2A3050)
    static let mint = dynamic(light: 0x2FA57C, dark: 0x8FE0C0)
    static let mintWash = dynamic(light: 0xE2F6EC, dark: 0x22382F)
    static let sun = dynamic(light: 0xE0AE2A, dark: 0xF2C94C)
    static let sky = dynamic(light: 0x2F6FCB, dark: 0x8BB8F0)
    static let coral = dynamic(light: 0xC4644C, dark: 0xF09079)
    static let coralWash = dynamic(light: 0xFBECE7, dark: 0x4A322C)
    static let moss = dynamic(light: 0x3B7A4D, dark: 0x86C296)
    static let mossWash = dynamic(light: 0xE6F1E8, dark: 0x2B3F31)
    static let rule = dynamic(light: 0xE4DDD0, dark: 0x3B3631)

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

extension Font {
    static let deskTitle = Font.system(.title, design: .rounded, weight: .bold)
    static let deskTakeaway = Font.system(.title3, design: .rounded, weight: .medium)
    static let deskSection = Font.system(.headline, design: .rounded, weight: .semibold)
    static let deskLabel = Font.system(.caption, design: .rounded, weight: .semibold)
    static let deskMono = Font.system(.callout, design: .monospaced)
}

extension CompletionState {
    var color: Color {
        switch self {
        case .delivered: return Palette.moss
        case .inProgress: return Palette.inkMuted
        case .needsAttention, .openQuestion: return Palette.coral
        }
    }
}

struct StatusMark: View {
    let completion: CompletionState

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(completion.color).frame(width: 7, height: 7)
            Text(completion.label).font(.deskLabel).foregroundStyle(completion.color)
        }
        .accessibilityLabel("Status: \(completion.label)")
    }
}

struct ReviewPackTag: View {
    var body: some View {
        Text("Review pack")
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(Palette.indigo)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(Palette.indigoWash))
            .accessibilityLabel("PR review pack, ready for reviewers")
    }
}

struct SectionHeader: View {
    let number: Int
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(String(format: "%02d", number))
                    .font(.system(.caption, design: .rounded, weight: .bold).monospacedDigit())
                    .foregroundStyle(Palette.indigo)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Palette.mintWash))
                Text(title).font(.deskSection).foregroundStyle(Palette.ink)
            }
            if let subtitle {
                Text(subtitle).font(.caption).foregroundStyle(Palette.inkMuted).padding(.leading, 42)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct EmptyNote: View {
    let text: String
    var tone: Color = Palette.inkMuted

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 1).fill(tone.opacity(0.6)).frame(width: 3)
            Text(text).font(.callout).italic().foregroundStyle(Palette.inkMuted).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

struct Panel<Content: View>: View {
    var fill: Color = Palette.card
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.rule, lineWidth: 1))
    }
}

struct MetaChip: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(Palette.inkMuted)
            .lineLimit(1)
    }
}

extension View {
    @ViewBuilder
    func deskWindowBackground() -> some View {
        if #available(macOS 15, *), DevLaunch.snapshotDirectory == nil {
            containerBackground(Palette.paper, for: .window)
        } else {
            self
        }
    }

    @ViewBuilder
    func deskColumnBackground() -> some View {
        if #available(macOS 26, *), DevLaunch.snapshotDirectory == nil {
            self
        } else {
            background(Palette.paper)
        }
    }

    @ViewBuilder
    func deskGlassButton(prominent: Bool = false) -> some View {
        if #available(macOS 26, *) {
            if prominent { buttonStyle(.glassProminent) } else { buttonStyle(.glass) }
        } else {
            if prominent { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
        }
    }

    @ViewBuilder
    func deskFloatingPanel(cornerRadius: CGFloat = 18) -> some View {
        if #available(macOS 26, *) {
            glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            background(RoundedRectangle(cornerRadius: cornerRadius).fill(Palette.paper))
        }
    }

    @ViewBuilder
    func deskClearPresentation() -> some View {
        if #available(macOS 26, *) {
            presentationBackground(.clear)
        } else {
            self
        }
    }
}

struct MascotBadge: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            Circle().fill(Palette.mintWash)
            Image("KumikoMascot").resizable().scaledToFit().frame(width: size * 0.86).offset(y: size * 0.08)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
