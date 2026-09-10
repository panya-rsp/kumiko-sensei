import AppKit
import SwiftUI

enum Palette {
    static let surface = dynamic(light: 0xF8FAFC, dark: 0x0F172A)
    static let card = dynamic(light: 0xFFFFFF, dark: 0x1E293B)
    static let cardRaised = dynamic(light: 0xFFFFFF, dark: 0x334155)
    static let ink = dynamic(light: 0x0F172A, dark: 0xFFFFFF)
    static let inkMuted = dynamic(light: 0x64748B, dark: 0xCBD5E1)
    static let rule = dynamic(light: 0xCBD5E1, dark: 0x334155)
    static let primary = dynamic(light: 0x2563EB, dark: 0x3B82F6)
    static let primaryWash = dynamic(light: 0xDBEAFE, dark: 0x1E3A8A)
    static let secondary = dynamic(light: 0x14B8A6, dark: 0x2DD4BF)
    static let secondaryWash = dynamic(light: 0xCCFBF1, dark: 0x134E4A)
    static let accentPink = dynamic(light: 0xF472B6, dark: 0xF472B6)
    static let accentPurple = dynamic(light: 0xA78BFA, dark: 0xA78BFA)
    static let accentYellow = dynamic(light: 0xFCD34D, dark: 0xFCD34D)
    static let success = dynamic(light: 0x10B981, dark: 0x10B981)
    static let warning = dynamic(light: 0xF59E0B, dark: 0xF59E0B)
    static let error = dynamic(light: 0xEF4444, dark: 0xEF4444)
    static let errorWash = dynamic(light: 0xFEE2E2, dark: 0x3F1D1D)
    static let info = dynamic(light: 0x3B82F6, dark: 0x3B82F6)

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

enum Gradients {
    static let brand = LinearGradient(colors: [Color(nsColor: NSColor(hex: 0x2563EB)), Color(nsColor: NSColor(hex: 0x14B8A6))], startPoint: .leading, endPoint: .trailing)
    static let sunrise = LinearGradient(colors: [Color(nsColor: NSColor(hex: 0xF472B6)), Color(nsColor: NSColor(hex: 0xFCD34D))], startPoint: .leading, endPoint: .trailing)
    static let night = LinearGradient(colors: [Color(nsColor: NSColor(hex: 0x6366F1)), Color(nsColor: NSColor(hex: 0x2563EB))], startPoint: .leading, endPoint: .trailing)
}

extension NSColor {
    convenience init(hex: UInt32) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

enum Inter {
    static func register() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []) + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, nil)
    }

    static func name(_ weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light: "Inter-Light"
        case .medium: "Inter-Medium"
        case .semibold: "Inter-SemiBold"
        case .bold, .heavy, .black: "Inter-Bold"
        default: "Inter-Regular"
        }
    }

    static func size(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 26
        case .title: 22
        case .title2: 17
        case .title3: 15
        case .headline, .body: 13
        case .callout: 12
        case .subheadline: 11
        default: 10
        }
    }

    static func nsFont(size: CGFloat, weight: Font.Weight = .regular) -> NSFont {
        NSFont(name: name(weight), size: size) ?? .systemFont(ofSize: size)
    }
}

extension Font {
    static func inter(_ style: TextStyle = .body, _ weight: Weight = .regular) -> Font {
        .custom(Inter.name(weight), size: Inter.size(style), relativeTo: style)
    }

    static let deskTitle = inter(.title, .semibold)
    static let deskTakeaway = inter(.title3, .medium)
    static let deskSection = inter(.headline, .medium)
    static let deskLabel = inter(.caption, .medium)
    static let deskMono = Font.system(.callout, design: .monospaced)
}

extension CompletionState {
    var color: Color {
        switch self {
        case .delivered: return Palette.success
        case .inProgress: return Palette.inkMuted
        case .needsAttention, .openQuestion: return Palette.error
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
            .font(.inter(.caption2, .semibold))
            .foregroundStyle(Palette.primary)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(Palette.primaryWash))
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
                    .font(.inter(.caption, .bold).monospacedDigit())
                    .foregroundStyle(Palette.primary)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Palette.secondaryWash))
                Text(title).font(.deskSection).foregroundStyle(Palette.ink)
            }
            if let subtitle {
                Text(subtitle).font(.inter(.caption)).foregroundStyle(Palette.inkMuted).padding(.leading, 42)
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
            Text(text).font(.inter(.callout)).italic().foregroundStyle(Palette.inkMuted).fixedSize(horizontal: false, vertical: true)
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
            .font(.inter(.caption))
            .foregroundStyle(Palette.inkMuted)
            .lineLimit(1)
    }
}

extension View {
    @ViewBuilder
    func deskWindowBackground() -> some View {
        if #available(macOS 15, *), DevLaunch.snapshotDirectory == nil {
            containerBackground(Palette.surface, for: .window)
        } else {
            self
        }
    }

    @ViewBuilder
    func deskColumnBackground() -> some View {
        if #available(macOS 26, *), DevLaunch.snapshotDirectory == nil {
            self
        } else {
            background(Palette.surface)
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
            background(RoundedRectangle(cornerRadius: cornerRadius).fill(Palette.surface))
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
            Circle().fill(Gradients.brand.opacity(0.18))
            Image("KumikoMascot").resizable().scaledToFit().frame(width: size * 0.86).offset(y: size * 0.08)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
