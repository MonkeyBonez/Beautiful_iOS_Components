import XCTest

final class LiquidGlassToastUITests: XCTestCase {
    @MainActor
    func testCatalogShowsActualToast() async throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let component = app.buttons["Liquid Glass Toast"].firstMatch
        XCTAssertTrue(component.waitForExistence(timeout: 5))
        component.tap()
        let show = app.buttons["Show Toast"]
        for _ in 0 ..< 6 {
            if show.isHittable {
                break
            }
            app.swipeUp()
        }
        XCTAssertTrue(show.isHittable)
        capture(app, "catalog-controls")
        show.tap()
        let toast = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Liquid Glass Toast")).firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        try await Task.sleep(for: .seconds(1))
        capture(app, "catalog-toast")
        XCTAssertTrue(app.buttons["Close"].exists)
        app.buttons["Close"].tap()
        XCTAssertTrue(show.waitForExistence(timeout: 5))
    }

    @MainActor
    func testNormalToastCanBeDismissed() {
        continueAfterFailure = false
        let app = launch()
        app.buttons["show-validation-toast"].tap()
        let toast = app.descendants(matching: .any)["validation-toast"].firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        capture(app, "toast-normal")
        toast.tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLargeMessageRemainsOnScreen() {
        continueAfterFailure = false
        let app = launch(large: true)
        app.buttons["show-validation-toast"].tap()
        let toast = app.descendants(matching: .any)["validation-toast"].firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        capture(app, "toast-accessibility-large")
        let window = app.windows.firstMatch.frame
        XCTAssertGreaterThanOrEqual(toast.frame.minX, window.minX)
        XCTAssertLessThanOrEqual(toast.frame.maxX, window.maxX)
    }

    @MainActor
    func testOldOpeningCannotDismissAReplacement() async throws {
        continueAfterFailure = false
        let app = launch()
        app.buttons["replace-validation-toast"].tap()
        try await Task.sleep(for: .seconds(2))
        capture(app, "toast-replaced")
        XCTAssertTrue(app.staticTexts["Dismissals: 0"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["validation-toast"].firstMatch.exists)
    }

    @MainActor
    func testRemovalCancelsDismissal() async throws {
        continueAfterFailure = false
        let app = launch()
        app.buttons["remove-validation-toast"].tap()
        try await Task.sleep(for: .seconds(2))
        capture(app, "toast-removed")
        XCTAssertTrue(app.staticTexts["Dismissals: 0"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["validation-toast"].firstMatch.exists)
    }

    @MainActor
    func testClearingDismissesOnce() async throws {
        continueAfterFailure = false
        let app = launch()
        app.buttons["show-validation-toast"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["validation-toast"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["clear-validation-toast"].tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
        try await Task.sleep(for: .seconds(1))
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].exists)
        capture(app, "toast-cleared")
    }

    @MainActor
    func testActualReduceMotionSetting() throws {
        continueAfterFailure = false
        let app = launch(slow: true)
        let (settings, toggle) = motionSettings()
        let original = try XCTUnwrap(toggle.value as? String)
        XCTAssertTrue(["0", "1"].contains(original))
        addTeardownBlock { @MainActor in
            settings.activate()
            if toggle.value as? String != original {
                toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            }
            XCTAssertEqual(toggle.value as? String, original)
            settings.terminate()
        }
        capture(settings, "motion-settings-before")
        if original == "0" {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertEqual(toggle.value as? String, "1")
        capture(settings, "motion-settings-on")

        app.activate()
        XCTAssertTrue(app.staticTexts["Reduce Motion: On"].waitForExistence(timeout: 5))
        app.buttons["show-validation-toast"].tap()
        let toast = app.descendants(matching: .any)["validation-toast"].firstMatch
        XCTAssertTrue(toast.waitForExistence(timeout: 5))
        capture(app, "toast-reduce-motion")
        toast.tap()
        XCTAssertTrue(app.staticTexts["Dismissals: 1"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func motionSettings() -> (XCUIApplication, XCUIElement) {
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        let toggle = settings.switches["REDUCE_MOTION"].firstMatch
        if !toggle.exists {
            let motion = settings.staticTexts["Motion"].firstMatch
            if !motion.isHittable {
                let accessibility = settings.staticTexts["Accessibility"].firstMatch
                for _ in 0 ..< 6 {
                    if accessibility.isHittable {
                        break
                    }
                    settings.swipeUp()
                }
                XCTAssertTrue(accessibility.isHittable)
                accessibility.tap()
            }
            XCTAssertTrue(motion.waitForExistence(timeout: 5))
            motion.tap()
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        return (settings, toggle)
    }

    @MainActor
    private func launch(large: Bool = false, slow: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--toast-validation"]
        if large {
            app.launchArguments.append("--toast-validation-large")
        }
        if slow {
            app.launchArguments.append("--toast-validation-slow")
        }
        app.launch()
        return app
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "\(name)-accessibility"
        tree.lifetime = .keepAlways
        add(tree)
    }
}
