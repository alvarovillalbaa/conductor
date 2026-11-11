import XCTest

final class ConductorUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        executionTimeAllowance = 180
    }

    @MainActor
    func testPlanAndRunSurviveRelaunchWithExplicitCompletion() throws {
        let app = XCUIApplication()
        // Standard OS locale arguments only: all fixture data is entered through the UI.
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        let planTitle = "Authored UI acceptance plan"
        let taskTitle = "Authored two-minute task"
        app.launch()
        defer { app.terminate() }

        tap(app.buttons["plans.create"])
        let minutes = app.steppers.matching(prefix: "plan.task.minutes.").firstMatch
        let minutesExist = minutes.waitForExistence(timeout: 10)
        if !minutesExist { emitStepperDiagnostic(app) }
        XCTAssertTrue(minutesExist)
        // New tasks start at five minutes; use the real Stepper to select two.
        for _ in 0..<3 { tap(minutes.buttons["Decrement"]) }
        enter(planTitle, into: app.textFields["plan.title"])
        enter(taskTitle, into: app.textFields.matching(prefix: "plan.task.title.").firstMatch)
        tap(app.buttons["plan.save"])
        XCTAssertTrue(app.staticTexts[planTitle].waitForExistence(timeout: 10))

        app.terminate()
        app.launch()
        let savedPlan = app.staticTexts[planTitle]
        XCTAssertTrue(savedPlan.waitForExistence(timeout: 15))
        tap(savedPlan)
        XCTAssertTrue(app.staticTexts[taskTitle].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["2m 0s"].exists)
        tap(app.buttons["plan.configureRun"])
        let soonest = app.switches["run.setup.soonest"]
        tap(soonest)
        XCTAssertEqual(soonest.value as? String, "1")
        tap(app.buttons["run.setup.create"])
        expectPhase("Waiting", in: app)
        XCTAssertTrue(app.staticTexts["Ready to start"].exists)
        tap(app.buttons.matching(prefix: "run.start.").firstMatch)
        expectPhase("Running", in: app)
        tap(app.buttons.matching(prefix: "run.pause.").firstMatch)
        expectPhase("Paused", in: app)

        app.terminate()
        app.launch()
        expectPhase("Paused", in: app)
        XCTAssertTrue(app.staticTexts[planTitle].exists)
        XCTAssertTrue(app.staticTexts[taskTitle].exists)
        screenshot("paused-after-relaunch", app: app)
        tap(app.buttons.matching(prefix: "run.resume.").firstMatch)
        expectPhase("Running", in: app)
        let complete = app.buttons.matching(prefix: "run.complete.").firstMatch
        XCTAssertEqual(complete.label, "Confirm \(taskTitle) is done")
        tap(complete)
        expectPhase("Done", in: app)
        expectLabel("All tasks checked off or skipped", of: app.staticTexts["run.summary"])

        app.terminate()
        app.launch()
        expectPhase("Done", in: app)
        XCTAssertTrue(app.staticTexts[taskTitle].exists)
        expectLabel("All tasks checked off or skipped", of: app.staticTexts["run.summary"])
        XCTAssertFalse(app.buttons.matching(prefix: "run.start.").firstMatch.exists)
        XCTAssertFalse(app.buttons.matching(prefix: "run.resume.").firstMatch.exists)
        XCTAssertFalse(app.buttons.matching(prefix: "run.complete.").firstMatch.exists)
        screenshot("done-after-relaunch", app: app)
    }

    @MainActor
    private func emitStepperDiagnostic(_ app: XCUIApplication) {
        screenshot("plan-editor-failure", app: app)
        let identifiers = app.descendants(matching: .any).matching(prefix: "plan.task.minutes.")
        let labels = ["New Plan", "Plan", "Task name", "Task minutes", "Minutes: 5",
                      "Hours: 0", "Seconds: 0", "Add Task", "Save", "Cancel",
                      "Name, such as Dinner together"]
        let matching = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@ OR label IN %@", argumentArray: ["plan.", labels]))
        let matchingCount = matching.count
        var elements: [[String: Any]] = []
        for index in 0..<min(matchingCount, 16) {
            let element = matching.element(boundBy: index)
            elements.append(["type": Int(element.elementType.rawValue),
                             "identifier": String(element.identifier.prefix(160)),
                             "label": String(element.label.prefix(160))])
        }
        var payload: [String: Any] = ["schemaVersion": 1,
            "typedStepperCount": app.steppers.matching(prefix: "plan.task.minutes.").count,
            "identifierMatchedCount": identifiers.count, "matchingElementCount": matchingCount,
            "elements": elements, "omittedElements": matchingCount - elements.count]
        while let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              data.count > 3500, !elements.isEmpty {
            elements.removeLast()
            payload["elements"] = elements
            payload["omittedElements"] = matchingCount - elements.count
        }
        let marker = "CONDUCTOR_UI_STEPPER_DIAGNOSTIC "
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              data.count <= 3500 else {
            print(marker + "{\"schemaVersion\":1,\"status\":\"unavailable\"}")
            return
        }
        print(marker + String(decoding: data, as: UTF8.self))
    }

    @MainActor
    private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), file: file, line: line)
        XCTAssertTrue(element.isHittable, file: file, line: line)
        element.tap()
    }

    @MainActor
    private func enter(_ text: String, into field: XCUIElement) {
        tap(field)
        field.typeText(text)
    }

    @MainActor
    private func expectPhase(_ phase: String, in app: XCUIApplication) {
        let phases = app.staticTexts.matching(prefix: "run.phase.")
        expectLabel(phase, of: phases.firstMatch)
        XCTAssertEqual(phases.count, 1)
    }

    @MainActor
    private func expectLabel(_ label: String, of element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        let expected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", label), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: 10), .completed)
    }

    @MainActor
    private func screenshot(_ name: String, app: XCUIApplication) {
        XCTContext.runActivity(named: name) { activity in
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
    }
}

private extension XCUIElementQuery {
    func matching(prefix: String) -> XCUIElementQuery {
        matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
    }
}
