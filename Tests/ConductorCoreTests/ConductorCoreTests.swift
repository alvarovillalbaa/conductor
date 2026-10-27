import Foundation
import XCTest
@testable import ConductorCore

// Authored in-memory inputs only. Native execution requires the owning scope.
final class ConductorCoreTests: XCTestCase {
    private let origin = Date(timeIntervalSince1970: 1_800_000_000)

    private func plan(_ durations: [Int] = [1_800, 600]) -> TaskPlan {
        TaskPlan(title: "Authored plan", tasks: durations.enumerated().map {
            TaskDefinition(title: "Authored task \($0.offset + 1)", durationSeconds: $0.element)
        }, updatedAt: origin)
    }

    private func session(_ durations: [Int] = [1_800, 600], finishAfter: TimeInterval = 3_600) throws -> RunSession {
        try ScheduleEngine.start(plan: plan(durations), finishAt: origin.addingTimeInterval(finishAfter), now: origin)
    }

    private func apply(_ action: RunAction, _ run: RunSession, index: Int = 0, after seconds: TimeInterval) throws -> RunSession {
        try ScheduleEngine.applying(action, to: run, taskID: run.tasks[index].id, now: origin.addingTimeInterval(seconds))
    }

    private func object(_ workspace: Workspace) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: WorkspaceCodec.encode(workspace)) as? [String: Any])
    }

    private func data(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    func testBackwardPlanningAlignsDifferentDurationsAtOneTarget() throws {
        let run = try session()
        let longest = ScheduleEngine.timing(for: run.tasks[0], in: run, now: origin)
        let shortest = ScheduleEngine.timing(for: run.tasks[1], in: run, now: origin)
        XCTAssertEqual(longest.plannedStart, origin.addingTimeInterval(1_800))
        XCTAssertEqual(shortest.plannedStart, origin.addingTimeInterval(3_000))
        XCTAssertEqual(longest.estimatedFinish, run.commonFinish)
        XCTAssertEqual(shortest.estimatedFinish, run.commonFinish)
    }

    func testEarliestTargetIsAcceptedAndEarlierTargetIsRejected() throws {
        let plan = plan()
        let earliest = try ScheduleEngine.earliestFinish(for: plan, now: origin)
        XCTAssertEqual(earliest, origin.addingTimeInterval(1_800))
        XCTAssertNoThrow(try ScheduleEngine.start(plan: plan, finishAt: earliest, now: origin))
        XCTAssertThrowsError(try ScheduleEngine.start(plan: plan, finishAt: earliest.addingTimeInterval(-0.001), now: origin))
    }

    func testSharedTargetHorizonHasAnExactSevenDayBoundary() throws {
        let plan = plan()
        XCTAssertNoThrow(try ScheduleEngine.start(plan: plan, finishAt: origin.addingTimeInterval(604_800), now: origin))
        XCTAssertThrowsError(try ScheduleEngine.start(plan: plan, finishAt: origin.addingTimeInterval(604_801), now: origin))
    }

    func testTaskDurationBoundariesAreOneSecondAndTwentyFourHours() throws {
        XCTAssertNoThrow(try ScheduleEngine.validate(plan([1, 86_400])))
        for duration in [0, -1, 86_401] { XCTAssertThrowsError(try ScheduleEngine.validate(plan([duration]))) }
    }

    func testAbsoluteDurationSurvivesDaylightSavingSpringTransition() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let finish = try XCTUnwrap(utc.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 7, minute: 10)))
        let now = finish.addingTimeInterval(-3_600)
        let run = try ScheduleEngine.start(plan: plan([1_200]), finishAt: finish, now: now)
        let timing = ScheduleEngine.timing(for: run.tasks[0], in: run, now: now)
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        XCTAssertEqual(newYork.component(.hour, from: finish), 3)
        XCTAssertEqual(newYork.component(.hour, from: timing.plannedStart), 1)
        XCTAssertEqual(finish.timeIntervalSince(timing.plannedStart), 1_200)
    }

    func testAPlanEditDoesNotChangeTheFrozenRunOrRequireSavedPlanMembership() throws {
        var plan = plan()
        let run = try ScheduleEngine.start(plan: plan, finishAt: origin.addingTimeInterval(3_600), now: origin)
        plan.title = "Changed reusable plan"
        plan.tasks[0].durationSeconds = 300
        XCTAssertEqual(run.plan.title, "Authored plan")
        XCTAssertEqual(run.tasks[0].definition.durationSeconds, 1_800)
        XCTAssertNoThrow(try ScheduleEngine.validate(Workspace(plans: [plan], session: run)))
        XCTAssertNoThrow(try ScheduleEngine.validate(Workspace(plans: [], session: run)))
    }

    func testStartRecordsObservedTimeWithoutChangingTheTargetOrInput() throws {
        let original = try session()
        let started = try apply(.start, original, after: 1_800)
        XCTAssertEqual(started.tasks[0].phase, .running)
        XCTAssertEqual(started.tasks[0].firstStartedAt, origin.addingTimeInterval(1_800))
        XCTAssertEqual(started.tasks[0].runningSince, origin.addingTimeInterval(1_800))
        XCTAssertEqual(started.commonFinish, original.commonFinish)
        XCTAssertEqual(original.tasks[0].phase, .waiting)
    }

    func testWaitingCueIsDueAtTheExactStartBoundary() throws {
        let run = try session()
        XCTAssertFalse(ScheduleEngine.timing(for: run.tasks[0], in: run, now: origin.addingTimeInterval(1_799.999)).isDue)
        XCTAssertTrue(ScheduleEngine.timing(for: run.tasks[0], in: run, now: origin.addingTimeInterval(1_800)).isDue)
    }

    func testLateWaitingTaskShowsAnHonestLaterEstimate() throws {
        let run = try session()
        let timing = ScheduleEngine.timing(for: run.tasks[0], in: run, now: origin.addingTimeInterval(1_920))
        XCTAssertTrue(timing.isDue)
        XCTAssertEqual(timing.estimatedFinish, run.commonFinish.addingTimeInterval(120))
        XCTAssertEqual(run.commonFinish, origin.addingTimeInterval(3_600))
    }

    func testRunningTimeCountsFromTheActualStartIncludingLateStarts() throws {
        let run = try apply(.start, session(), after: 1_920)
        let timing = ScheduleEngine.timing(for: run.tasks[0], in: run, now: origin.addingTimeInterval(2_520))
        XCTAssertEqual(timing.elapsedSeconds, 600)
        XCTAssertEqual(timing.remainingSeconds, 1_200)
        XCTAssertEqual(timing.estimatedFinish, run.commonFinish.addingTimeInterval(120))
    }

    func testPauseAndResumeAccumulateOnlyRunningIntervals() throws {
        let started = try apply(.start, session(), after: 1_800)
        let paused = try apply(.pause, started, after: 2_400)
        let pausedTiming = ScheduleEngine.timing(for: paused.tasks[0], in: paused, now: origin.addingTimeInterval(2_700))
        XCTAssertEqual(pausedTiming.elapsedSeconds, 600)
        XCTAssertEqual(pausedTiming.remainingSeconds, 1_200)
        XCTAssertEqual(pausedTiming.estimatedFinish, origin.addingTimeInterval(3_900))
        let resumed = try apply(.resume, paused, after: 2_700)
        let resumedTiming = ScheduleEngine.timing(for: resumed.tasks[0], in: resumed, now: origin.addingTimeInterval(3_000))
        XCTAssertEqual(resumedTiming.elapsedSeconds, 900)
        XCTAssertEqual(resumedTiming.remainingSeconds, 900)
        XCTAssertEqual(resumed.tasks[0].firstStartedAt, started.tasks[0].firstStartedAt)
        XCTAssertEqual(resumed.commonFinish, started.commonFinish)
    }

    func testBackwardClockDeltasNeverCreateNegativeElapsedTimeOrInventTimestamps() throws {
        let started = try apply(.start, session(), after: 1_800)
        let paused = try apply(.pause, started, after: 1_700)
        XCTAssertEqual(paused.tasks[0].elapsedBeforeRun, 0)
        XCTAssertEqual(paused.tasks[0].firstStartedAt, origin.addingTimeInterval(1_800))
        let completed = try apply(.complete, paused, after: 1_600)
        XCTAssertEqual(completed.tasks[0].endedAt, origin.addingTimeInterval(1_600))
        XCTAssertNoThrow(try ScheduleEngine.validate(Workspace(session: completed)))
    }

    func testTimerExpiryDoesNotConfirmPhysicalCompletion() throws {
        let running = try apply(.start, session(), after: 1_800)
        let timing = ScheduleEngine.timing(for: running.tasks[0], in: running, now: origin.addingTimeInterval(4_000))
        XCTAssertEqual(timing.remainingSeconds, 0)
        XCTAssertTrue(timing.isOvertime)
        XCTAssertEqual(running.tasks[0].phase, .running)
        XCTAssertNil(running.tasks[0].endedAt)
        XCTAssertTrue(ScheduleEngine.isActive(running))
    }

    func testExplicitCompletionRetainsActualEarlyOrLateOffset() throws {
        let started = try apply(.start, session(), after: 1_800)
        let early = try apply(.complete, started, after: 2_100)
        let late = try apply(.complete, started, after: 3_720)
        XCTAssertEqual(ScheduleEngine.timing(for: early.tasks[0], in: early, now: origin).completionOffsetSeconds, -1_500)
        XCTAssertEqual(ScheduleEngine.timing(for: late.tasks[0], in: late, now: origin).completionOffsetSeconds, 120)
        XCTAssertEqual(early.tasks[0].elapsedBeforeRun, 300)
        XCTAssertEqual(early.commonFinish, late.commonFinish)
    }

    func testCompletionWithoutStartingDoesNotFabricateAStartedTime() throws {
        let completed = try apply(.complete, session(), after: 500)
        XCTAssertEqual(completed.tasks[0].phase, .completed)
        XCTAssertNil(completed.tasks[0].firstStartedAt)
        XCTAssertEqual(completed.tasks[0].elapsedBeforeRun, 0)
        XCTAssertEqual(completed.tasks[0].endedAt, origin.addingTimeInterval(500))
    }

    func testSkippedTaskHasNoCompletionEstimateOrOffset() throws {
        let run = try apply(.skip, session(), after: 400)
        let timing = ScheduleEngine.timing(for: run.tasks[0], in: run, now: origin.addingTimeInterval(1_000))
        XCTAssertEqual(run.tasks[0].phase, .skipped)
        XCTAssertNil(timing.estimatedFinish)
        XCTAssertNil(timing.completionOffsetSeconds)
        XCTAssertEqual(timing.remainingSeconds, 0)
    }

    func testIllegalTransitionsUnknownTasksAndTerminalTasksAreRejected() throws {
        let waiting = try session()
        XCTAssertThrowsError(try apply(.pause, waiting, after: 100))
        XCTAssertThrowsError(try apply(.resume, waiting, after: 100))
        let running = try apply(.start, waiting, after: 1_800)
        XCTAssertThrowsError(try apply(.start, running, after: 1_801))
        let completed = try apply(.complete, running, after: 1_900)
        XCTAssertThrowsError(try apply(.complete, completed, after: 1_901))
        XCTAssertThrowsError(try ScheduleEngine.applying(.start, to: waiting, taskID: UUID(), now: origin))
    }

    func testAllTerminalTasksEndTheRunWithoutMovingItsTarget() throws {
        var run = try apply(.complete, session(), after: 100)
        run = try apply(.skip, run, index: 1, after: 200)
        XCTAssertFalse(ScheduleEngine.isActive(run))
        XCTAssertTrue(ScheduleEngine.reminders(for: run, now: origin).isEmpty)
        XCTAssertThrowsError(try ScheduleEngine.stop(run, now: origin))
        XCTAssertEqual(run.commonFinish, origin.addingTimeInterval(3_600))
    }

    func testStopFreezesRunningElapsedAndRetainsOtherTaskStates() throws {
        var run = try session([1_800, 600, 300])
        run = try apply(.start, run, after: 1_800)
        run = try apply(.complete, run, index: 1, after: 1_900)
        let stopped = try ScheduleEngine.stop(run, now: origin.addingTimeInterval(2_100))
        XCTAssertEqual(stopped.tasks.map(\.phase), [.paused, .completed, .waiting])
        XCTAssertEqual(stopped.tasks[0].elapsedBeforeRun, 300)
        XCTAssertEqual(stopped.stoppedAt, origin.addingTimeInterval(2_100))
        let later = ScheduleEngine.timing(for: stopped.tasks[0], in: stopped, now: origin.addingTimeInterval(9_000))
        XCTAssertEqual(later.elapsedSeconds, 300)
        XCTAssertEqual(later.remainingSeconds, 1_500)
        XCTAssertNil(later.estimatedFinish)
        XCTAssertFalse(ScheduleEngine.isActive(stopped))
        XCTAssertFalse(ScheduleEngine.timing(for: stopped.tasks[2], in: stopped, now: origin.addingTimeInterval(9_000)).isDue)
        XCTAssertThrowsError(try apply(.resume, stopped, after: 2_200))
        XCTAssertTrue(ScheduleEngine.reminders(for: stopped, now: origin).isEmpty)
    }

    func testFutureRemindersHaveStableDistinctIDsAndChronologicalOrder() throws {
        let run = try session()
        let cues = ScheduleEngine.reminders(for: run, now: origin)
        XCTAssertEqual(cues.count, 3)
        XCTAssertEqual(Set(cues.map(\.id)).count, 3)
        XCTAssertEqual(cues.map(\.fireAt), [origin.addingTimeInterval(1_800), origin.addingTimeInterval(3_000), run.commonFinish])
        XCTAssertEqual(cues, ScheduleEngine.reminders(for: run, now: origin))
        let other = try session()
        XCTAssertTrue(Set(cues.map(\.id)).isDisjoint(with: Set(ScheduleEngine.reminders(for: other, now: origin).map(\.id))))
    }

    func testPastStartCuesAreNotReplayedAndPausedTasksHaveNoElapsedCue() throws {
        let waiting = try session()
        let afterStart = ScheduleEngine.reminders(for: waiting, now: origin.addingTimeInterval(1_800))
        XCTAssertEqual(afterStart.count, 2)
        XCTAssertFalse(afterStart.contains { $0.id.contains(waiting.tasks[0].id.uuidString.lowercased()) })
        let running = try apply(.start, waiting, after: 1_800)
        let paused = try apply(.pause, running, after: 1_900)
        let pausedCues = ScheduleEngine.reminders(for: paused, now: origin.addingTimeInterval(2_000))
        XCTAssertFalse(pausedCues.contains { $0.id.contains(paused.tasks[0].id.uuidString.lowercased()) })
    }

    func testRunningReminderUsesActualElapsedEstimateNotTheSharedTarget() throws {
        let running = try apply(.start, session(), after: 1_920)
        let cues = ScheduleEngine.reminders(for: running, now: origin.addingTimeInterval(2_000))
        let elapsedCue = try XCTUnwrap(cues.first { $0.id.hasSuffix(".elapsed") })
        XCTAssertEqual(elapsedCue.fireAt, origin.addingTimeInterval(3_720))
        XCTAssertTrue(cues.contains { $0.id.hasSuffix(".target") && $0.fireAt == running.commonFinish })
        XCTAssertFalse(ScheduleEngine.reminders(for: running, now: origin.addingTimeInterval(4_000)).contains { $0.id.hasSuffix(".elapsed") })
    }

    func testTwentyTasksProduceAtMostTwentyOneFutureCues() throws {
        let run = try session(Array(repeating: 60, count: 20))
        let cues = ScheduleEngine.reminders(for: run, now: origin)
        XCTAssertEqual(cues.count, 21)
        XCTAssertTrue(cues.allSatisfy { $0.fireAt > origin })
    }

    func testInvalidPlanTitlesDurationsCountsAndIdentitiesAreRejected() throws {
        var invalid = plan()
        invalid.title = " \n\t"
        XCTAssertThrowsError(try ScheduleEngine.validate(invalid))
        invalid = plan(); invalid.tasks[0].title = String(repeating: "x", count: 81)
        XCTAssertThrowsError(try ScheduleEngine.validate(invalid))
        invalid = plan(); invalid.tasks = []
        XCTAssertThrowsError(try ScheduleEngine.validate(invalid))
        invalid = plan(Array(repeating: 1, count: 21))
        XCTAssertThrowsError(try ScheduleEngine.validate(invalid))
        invalid = plan(); invalid.tasks[1].id = invalid.tasks[0].id
        XCTAssertThrowsError(try ScheduleEngine.validate(invalid))
        invalid = plan(); invalid.revision = -1
        XCTAssertThrowsError(try ScheduleEngine.validate(invalid))
    }

    func testWorkspacePlanLimitAndDuplicatePlanIDsAreRejectedWithoutFiltering() throws {
        let plans = (0..<50).map { _ in plan([1]) }
        XCTAssertNoThrow(try ScheduleEngine.validate(Workspace(plans: plans)))
        XCTAssertThrowsError(try ScheduleEngine.validate(Workspace(plans: plans + [plan([1])])))
        XCTAssertThrowsError(try ScheduleEngine.validate(Workspace(plans: [plans[0], plans[0]])))
    }

    func testDateAndElapsedValuesMustBeFiniteAndBounded() throws {
        for date in [Date(timeIntervalSince1970: -1), Date(timeIntervalSince1970: 32_503_680_001), Date(timeIntervalSince1970: .nan)] {
            var invalid = plan(); invalid.updatedAt = date
            XCTAssertThrowsError(try ScheduleEngine.validate(invalid))
        }
        for elapsed in [-1.0, .infinity, .nan] {
            var invalid = try session(); invalid.tasks[0].elapsedBeforeRun = elapsed
            XCTAssertThrowsError(try ScheduleEngine.validate(Workspace(session: invalid)))
        }
    }

    func testFrozenDefinitionMismatchDuplicateRunIDsAndBadPhaseShapesAreRejected() throws {
        var invalid = try session(); invalid.tasks[0].definition.title = "Mutated frozen task"
        XCTAssertThrowsError(try ScheduleEngine.validate(Workspace(session: invalid)))
        invalid = try session(); invalid.tasks[1] = invalid.tasks[0]
        XCTAssertThrowsError(try ScheduleEngine.validate(Workspace(session: invalid)))
        invalid = try session(); invalid.tasks[0].phase = .running
        XCTAssertThrowsError(try ScheduleEngine.validate(Workspace(session: invalid)))
        invalid = try session(); invalid.tasks[0].phase = .completed
        XCTAssertThrowsError(try ScheduleEngine.validate(Workspace(session: invalid)))
        invalid = try apply(.start, session(), after: 1_800); invalid.stoppedAt = origin
        XCTAssertThrowsError(try ScheduleEngine.validate(Workspace(session: invalid)))
    }

    func testEmptyWorkspaceAndFullTimingStateRoundTripWithoutLosingValues() throws {
        XCTAssertEqual(try WorkspaceCodec.decode(WorkspaceCodec.encode(Workspace())), Workspace())
        var run = try apply(.start, session(), after: 1_800.125)
        run = try apply(.pause, run, after: 1_806.875)
        run = try apply(.resume, run, after: 1_900.375)
        let original = Workspace(plans: [run.plan], session: run, remindersEnabled: true)
        let encoded = try WorkspaceCodec.encode(original)
        XCTAssertEqual(try WorkspaceCodec.decode(encoded), original)
        let object = try self.object(original)
        let rawSession = try XCTUnwrap(object["session"] as? [String: Any])
        XCTAssertTrue(rawSession["createdAt"] is NSNumber)
    }

    func testMaximumRevisionSurvivesTheCodecWithoutSilentNarrowing() throws {
        var plan = plan([1]); plan.revision = .max
        let workspace = Workspace(plans: [plan])
        XCTAssertEqual(try WorkspaceCodec.decode(WorkspaceCodec.encode(workspace)).plans[0].revision, Int.max)
    }

    func testUnknownFieldsAtEveryStoredRecordLevelAreRejected() throws {
        let workspace = Workspace(plans: [plan()], session: try session())
        var root = try object(workspace); root["futureField"] = "Do not drop this"
        XCTAssertThrowsError(try WorkspaceCodec.decode(data(root)))
        root = try object(workspace)
        var plans = try XCTUnwrap(root["plans"] as? [[String: Any]])
        plans[0]["futureField"] = "Do not drop this"; root["plans"] = plans
        XCTAssertThrowsError(try WorkspaceCodec.decode(data(root)))
        root = try object(workspace); plans = try XCTUnwrap(root["plans"] as? [[String: Any]])
        var definitions = try XCTUnwrap(plans[0]["tasks"] as? [[String: Any]])
        definitions[0]["futureField"] = "Do not drop this"; plans[0]["tasks"] = definitions; root["plans"] = plans
        XCTAssertThrowsError(try WorkspaceCodec.decode(data(root)))
        root = try object(workspace)
        var run = try XCTUnwrap(root["session"] as? [String: Any]); run["futureField"] = "Do not drop this"; root["session"] = run
        XCTAssertThrowsError(try WorkspaceCodec.decode(data(root)))
        root = try object(workspace); run = try XCTUnwrap(root["session"] as? [String: Any])
        var runTasks = try XCTUnwrap(run["tasks"] as? [[String: Any]])
        runTasks[0]["futureField"] = "Do not drop this"; run["tasks"] = runTasks; root["session"] = run
        XCTAssertThrowsError(try WorkspaceCodec.decode(data(root)))
    }

    func testUnsupportedVersionMissingRequiredFieldsAndUnknownPhaseAreRejected() throws {
        var object = try self.object(Workspace(plans: [plan()], session: try session()))
        object["version"] = 2
        XCTAssertThrowsError(try WorkspaceCodec.decode(data(object)))
        object = try self.object(Workspace())
        object.removeValue(forKey: "remindersEnabled")
        XCTAssertThrowsError(try WorkspaceCodec.decode(data(object)))
        object = try self.object(Workspace(session: try session()))
        var run = try XCTUnwrap(object["session"] as? [String: Any])
        var tasks = try XCTUnwrap(run["tasks"] as? [[String: Any]])
        tasks[0]["phase"] = "automaticDone"; run["tasks"] = tasks; object["session"] = run
        XCTAssertThrowsError(try WorkspaceCodec.decode(data(object)))
    }

    func testMalformedUtf8AndNonWorkspaceJsonAreRejectedWithoutMutatingInputBytes() {
        for data in [Data([0xff, 0xfe, 0xfd]), Data("[]".utf8), Data("{broken".utf8)] {
            let original = data
            XCTAssertThrowsError(try WorkspaceCodec.decode(data))
            XCTAssertEqual(data, original)
        }
    }

    func testDecodeByteCapRejectsOversizedWhitespaceBeforeParsing() {
        let data = Data(repeating: 0x20, count: WorkspaceCodec.maximumBytes + 1)
        XCTAssertThrowsError(try WorkspaceCodec.decode(data))
    }

    func testTitleUtf8BoundRejectsUnboundedCombiningMarksEvenWithinCharacterLimit() {
        var plan = plan([1])
        plan.title = "x" + String(repeating: "\u{0301}", count: 2_048)
        XCTAssertEqual(plan.title.count, 1)
        XCTAssertEqual(plan.title.utf8.count, 4_097)
        XCTAssertThrowsError(try ScheduleEngine.validate(plan))
        plan.title = "x" + String(repeating: "\u{0301}", count: 2_047)
        XCTAssertNoThrow(try ScheduleEngine.validate(plan))
    }

    func testEncodeByteCapRejectsAnOversizedOtherwiseValidWorkspace() {
        var plans = (0..<50).map { _ in plan(Array(repeating: 1, count: 20)) }
        for planIndex in plans.indices {
            for taskIndex in plans[planIndex].tasks.indices {
                plans[planIndex].tasks[taskIndex].title = "x" + String(repeating: "\u{0301}", count: 2_047)
            }
        }
        let workspace = Workspace(plans: plans)
        XCTAssertNoThrow(try ScheduleEngine.validate(workspace))
        XCTAssertThrowsError(try WorkspaceCodec.encode(workspace)) { error in
            guard let failure = error as? ConductorError,
                  case .invalidData(let message) = failure else { return XCTFail("Unexpected encode failure: \(error)") }
            XCTAssertTrue(message.contains("two-megabyte"))
        }
    }

    func testExactDecodeByteCapAndUtf8BomAreAccepted() throws {
        let encoded = try WorkspaceCodec.encode(Workspace())
        var exact = encoded
        exact.append(Data(repeating: 0x20, count: WorkspaceCodec.maximumBytes - encoded.count))
        XCTAssertEqual(try WorkspaceCodec.decode(exact), Workspace())
        XCTAssertEqual(try WorkspaceCodec.decode(Data([0xef, 0xbb, 0xbf]) + encoded), Workspace())
    }

    func testBomlessUtf16AndUtf32AreNotMisidentifiedAsNativeUtf8Backups() throws {
        let text = String(decoding: try WorkspaceCodec.encode(Workspace()), as: UTF8.self)
        for encoding in [String.Encoding.utf16LittleEndian, .utf16BigEndian, .utf32LittleEndian, .utf32BigEndian] {
            let encoded = try XCTUnwrap(text.data(using: encoding))
            XCTAssertTrue(encoded.contains(0))
            XCTAssertThrowsError(try WorkspaceCodec.decode(encoded))
        }
    }

    func testDuplicateRootKeysCannotSilentlyReplaceStoredPlansWithAnEmptyList() throws {
        let workspace = try object(Workspace(plans: [plan()]))
        let plans = try JSONSerialization.data(withJSONObject: try XCTUnwrap(workspace["plans"]))
        let original = "{\"version\":1,\"plans\":" + String(decoding: plans, as: UTF8.self)
            + ",\"plans\":[],\"remindersEnabled\":false}"
        let data = Data(original.utf8)
        let before = data
        XCTAssertThrowsError(try WorkspaceCodec.decode(data))
        XCTAssertEqual(data, before)
    }

    func testNestedDuplicateAndEscapedEquivalentKeysAreRejected() throws {
        let original = String(decoding: try WorkspaceCodec.encode(Workspace(plans: [plan()])), as: UTF8.self)
        let title = "\"title\":\"Authored task 1\""
        XCTAssertTrue(original.contains(title))
        for replacement in ["\"title\":\"Original\",\"title\":\"Replaced\"", "\"title\":\"Original\",\"ti\\u0074le\":\"Replaced\""] {
            XCTAssertThrowsError(try WorkspaceCodec.decode(Data(original.replacingOccurrences(of: title, with: replacement).utf8)))
        }
    }

    func testQuotedKeyLikeTextAndRepeatedKeysInSeparateObjectsAreNotDuplicates() throws {
        var plan = plan()
        plan.title = "Quoted \"plans\":[] and brace } text are values"
        plan.tasks[0].title = "A \\" + " \"title\": marker"
        let workspace = Workspace(plans: [plan], session: try session())
        XCTAssertEqual(try WorkspaceCodec.decode(WorkspaceCodec.encode(workspace)), workspace)
    }
}
