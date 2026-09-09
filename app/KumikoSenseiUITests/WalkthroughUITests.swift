import XCTest

final class WalkthroughUITests: XCTestCase {
    private var shotsDirectory: URL?

    override func setUp() {
        continueAfterFailure = false
        if let dir = ProcessInfo.processInfo.environment["KUMIKO_SHOTS_DIR"], !dir.isEmpty {
            shotsDirectory = URL(fileURLWithPath: dir, isDirectory: true)
            try? FileManager.default.createDirectory(at: shotsDirectory!, withIntermediateDirectories: true)
        }
    }

    private var libraryPath: String {
        if let path = ProcessInfo.processInfo.environment["KUMIKO_LIBRARY"], !path.isEmpty { return path }
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "PreviewLibrary").path
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--library", libraryPath]
        app.launch()
        return app
    }

    private func snap(_ element: XCUIElement, _ name: String) {
        let shot = element.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = shotsDirectory { try? shot.pngRepresentation.write(to: dir.appending(path: "\(name).png")) }
    }

    func testLibraryDetailSearchAndSheets() throws {
        let app = launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["All knowledge"].firstMatch.waitForExistence(timeout: 10), "library list header renders")
        sleep(1)
        snap(window, "01-library")

        let search = app.buttons["toolbar.search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.click()
        let field = app.textFields["search.field"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "⌘K palette opens")
        field.typeText("replace")
        sleep(1)
        snap(app.sheets.firstMatch.exists ? app.sheets.firstMatch : window, "02-search")
        field.typeKey(.enter, modifierFlags: [])
        XCTAssertTrue(app.staticTexts["Takeaway"].firstMatch.waitForExistence(timeout: 5), "search result opens detail")
        XCTAssertTrue(app.staticTexts["Evidence"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Files on disk"].firstMatch.exists)
        sleep(1)
        snap(window, "03-detail")

        let media = app.buttons["media.primary"].firstMatch
        if media.waitForExistence(timeout: 3) {
            media.click()
            XCTAssertTrue(app.buttons["Done"].firstMatch.waitForExistence(timeout: 5), "image inspector opens")
            sleep(1)
            snap(app.sheets.firstMatch.exists ? app.sheets.firstMatch : window, "04-inspector")
            app.buttons["Done"].firstMatch.click()
        }

        let inbox = app.staticTexts["Inbox / needs attention"].firstMatch
        if inbox.waitForExistence(timeout: 3) {
            inbox.click()
            sleep(1)
            snap(window, "05-inbox")
        }

        app.buttons["toolbar.newHandoff"].firstMatch.click()
        XCTAssertTrue(app.staticTexts["New handoff"].firstMatch.waitForExistence(timeout: 5), "composer opens")
        sleep(1)
        snap(app.sheets.firstMatch.exists ? app.sheets.firstMatch : window, "06-composer")
        app.buttons["Cancel"].firstMatch.click()

        app.buttons["toolbar.askKumiko"].firstMatch.click()
        XCTAssertTrue(app.staticTexts["Ask Kumiko"].firstMatch.waitForExistence(timeout: 5), "Ask Kumiko opens")
        sleep(1)
        snap(app.sheets.firstMatch.exists ? app.sheets.firstMatch : window, "07-ask-kumiko")
        app.buttons["Cancel"].firstMatch.click()
        XCTAssertTrue(app.staticTexts["Takeaway"].firstMatch.waitForExistence(timeout: 5), "back on the detail after cancel")
    }
}
