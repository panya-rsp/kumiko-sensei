import SwiftUI

struct OnboardingView: View {
    @Environment(LibraryStore.self) private var store

    var body: some View {
        VStack(spacing: 22) {
            MascotBadge(size: 200)
                .accessibilityLabel("Kumiko-sensei, the visual teaching companion")
            VStack(spacing: 8) {
                Text("Kumiko Sensei").font(.deskTitle).foregroundStyle(Palette.ink)
                Text("A calm, local home for the decisions, visual explanations, and open questions behind your code.")
                    .font(.title3).foregroundStyle(Palette.inkMuted).multilineTextAlignment(.center).frame(maxWidth: 460)
            }
            if case .accessLost(let message) = store.state {
                Panel(fill: Palette.coralWash) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle").foregroundStyle(Palette.coral)
                        Text(message).font(.callout).foregroundStyle(Palette.ink)
                    }
                }
                .frame(maxWidth: 520)
            }
            VStack(spacing: 10) {
                Button { store.chooseFolder() } label: {
                    Label("Choose Cheatbook Folder…", systemImage: "folder").frame(minWidth: 240)
                }
                .deskGlassButton(prominent: true).controlSize(.large).keyboardShortcut(.defaultAction)
                Button { store.openSampleLibrary() } label: {
                    Text("Try the sample library").frame(minWidth: 240)
                }
                .deskGlassButton().controlSize(.large)
            }
            VStack(alignment: .leading, spacing: 6) {
                bullet("Reads sessions/ and handoffs/inbox/ in place. Nothing is copied, migrated, or uploaded.")
                bullet("Remembers the folder with a security-scoped bookmark you can revoke any time.")
                bullet("No GitHub access, cloud sync, telemetry, or hidden model calls.")
            }
            .font(.callout).foregroundStyle(Palette.inkMuted).frame(maxWidth: 520)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .deskColumnBackground()
        .deskWindowBackground()
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle().fill(Palette.mint).frame(width: 6, height: 6).offset(y: -2)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
    }
}
