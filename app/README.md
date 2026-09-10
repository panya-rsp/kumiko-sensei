# Kumiko Sensei — build and run

Native SwiftUI macOS app (macOS 14+, built with Xcode 26 / macOS 26 SDK). No third-party dependencies.

## Requirements

- Xcode 26 (any 16+ should open the project; Liquid Glass chrome appears only on macOS 26).
- A Cheatbook folder containing `sessions/` and `handoffs/`.

## Open in Xcode

```sh
open KumikoSensei.xcodeproj
```

Select the `KumikoSensei` scheme and press Run. On first launch choose your Cheatbook folder or click **Try the sample library** (installs `PreviewLibrary/` into the app's container).

## Command line

```sh
# Build the sandboxed app
xcodebuild -project KumikoSensei.xcodeproj -scheme KumikoSensei \
  -configuration Debug -derivedDataPath .build build

# Unit tests (24 tests: front matter, Markdown, scanner, search, composer, notes, media feedback)
xcodebuild -project KumikoSensei.xcodeproj -scheme KumikoSensei \
  -derivedDataPath .build -destination 'platform=macOS' \
  -only-testing:KumikoSenseiTests test

# Launch the built app
open .build/Build/Products/Debug/Kumiko\ Sensei.app
```

## Developer launch arguments

The app accepts a few arguments for previews and screenshots:

| Argument | Effect |
|---|---|
| `--sample-library` | Installs and opens `PreviewLibrary/` instead of restoring the bookmark |
| `--library <path>` | Opens a folder directly. Works only in a non-sandboxed dev build (see below) |
| `--snapshot-dir <dir>` | Walks the main screens and writes PNG captures there, then quits |
| `--dark` | Forces the dark appearance for this launch only, without changing System Settings |

Non-sandboxed dev build for `--library` and offscreen screenshots:

```sh
xcodebuild -project KumikoSensei.xcodeproj -scheme KumikoSensei \
  -configuration Debug -derivedDataPath .build-shots CODE_SIGN_ENTITLEMENTS="" build
.build-shots/Build/Products/Debug/Kumiko\ Sensei.app/Contents/MacOS/Kumiko\ Sensei \
  --library /path/to/cheatbook --snapshot-dir "$PWD/screenshots/final"
```

Snapshot mode renders columns with opaque paper and a plain sidebar list because the offscreen renderer cannot capture Liquid Glass panes; the live app uses the system glass sidebar and toolbar.

## UI walkthrough test

`KumikoSenseiUITests` drives search, detail, image inspector, inbox, composer, and Ask Kumiko, and saves screenshots to `$KUMIKO_SHOTS_DIR`. It needs the macOS Automation permission prompt to be accepted once:

```sh
KUMIKO_LIBRARY=/path/to/cheatbook KUMIKO_SHOTS_DIR="$PWD/screenshots/ui" \
xcodebuild -project KumikoSensei.xcodeproj -scheme KumikoSensei \
  -derivedDataPath .build-shots CODE_SIGN_ENTITLEMENTS="" -destination 'platform=macOS' \
  -only-testing:KumikoSenseiUITests test
```

## Layout

```
KumikoSensei/
  App/        entry point, menu commands, dev launch + snapshot runner
  Model/      KnowledgeItem
  Parsing/    FrontMatter, MarkdownDocument (sections, evidence, identifiers), MarkdownBlocks (renderer input)
  Library/    LibraryScanner, LibraryStore, FolderAccess (bookmarks), FolderWatcher (FSEvents)
  Search/     SearchIndex + SearchProvider protocol (LexicalSearchProvider today)
  Composer/   HandoffComposer (template fill, Ask Kumiko question drafts)
  Views/      Theme, RootView/Sidebar, LibraryListView, DetailView, MarkdownView, MediaViews, SearchPalette, Composer, AskKumiko, Onboarding
KumikoSenseiTests/   Swift Testing unit tests (fixture: PreviewLibrary/)
KumikoSenseiUITests/ XCUITest walkthrough
PreviewLibrary/             small Cheatbook-shaped sample library bundled as a resource
Tools/make-fixture-media.swift  regenerates the sample PNGs
```
