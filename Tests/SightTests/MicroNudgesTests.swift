import XCTest

@testable import Sight

final class MicroNudgesTests: XCTestCase {

    // MARK: - Nudge Type Tests

    func testNudgeTypeDefaultIntervals() {
        XCTAssertEqual(NudgeType.blink.defaultInterval, 2 * 60)  // 2 minutes
        XCTAssertEqual(NudgeType.posture.defaultInterval, 25 * 60)
        XCTAssertEqual(NudgeType.miniExercise.defaultInterval, 50 * 60)
    }

    func testNudgeTypeDisplayNames() {
        XCTAssertEqual(NudgeType.blink.displayName, "Blink Reminder")
        XCTAssertEqual(NudgeType.posture.displayName, "Posture Check")
        XCTAssertEqual(NudgeType.miniExercise.displayName, "Mini Exercise")
    }

    func testNudgeTypeCodable() throws {
        for type in NudgeType.allCases {
            let data = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(NudgeType.self, from: data)
            XCTAssertEqual(decoded, type)
        }
    }

    // MARK: - Mini Exercise Tests

    func testMiniExerciseDefaults() {
        let exercises = MiniExercise.defaults
        XCTAssertGreaterThan(exercises.count, 0)

        for exercise in exercises {
            XCTAssertFalse(exercise.name.isEmpty)
            XCTAssertFalse(exercise.instruction.isEmpty)
            XCTAssertGreaterThan(exercise.durationSeconds, 0)
        }
    }

    func testMiniExerciseCodable() throws {
        let exercise = MiniExercise.defaults[0]
        let data = try JSONEncoder().encode(exercise)
        let decoded = try JSONDecoder().decode(MiniExercise.self, from: data)

        XCTAssertEqual(decoded.name, exercise.name)
        XCTAssertEqual(decoded.instruction, exercise.instruction)
    }

    // MARK: - UX Copy Tests

    func testBlinkMessagesNotEmpty() {
        XCTAssertGreaterThan(NudgeCopy.blinkMessages.count, 0)
    }

    func testPostureMessagesNotEmpty() {
        XCTAssertGreaterThan(NudgeCopy.postureMessages.count, 0)
    }

    func testRandomMessageForType() {
        for type in NudgeType.allCases {
            let message = NudgeCopy.randomMessage(for: type)
            XCTAssertFalse(message.isEmpty)
        }
    }

    // MARK: - Sound Assets Tests

    func testSoundFileForType() {
        XCTAssertEqual(NudgeSounds.soundFile(for: .blink), "blink_soft.wav")
        XCTAssertEqual(NudgeSounds.soundFile(for: .posture), "posture_chime.wav")
        XCTAssertEqual(NudgeSounds.soundFile(for: .miniExercise), "exercise_prompt.wav")
    }

    // MARK: - Snooze State Tests

    func testSnoozeStateInitial() {
        let state = SnoozeState()
        XCTAssertEqual(state.snoozeCount, 0)
        XCTAssertNil(state.lastSnoozeTime)
        XCTAssertNil(state.snoozeUntil)
        XCTAssertFalse(state.isSnoozed)
    }

    func testSnoozeStateSnooze() {
        var state = SnoozeState()
        state.snooze(for: 5)

        XCTAssertEqual(state.snoozeCount, 1)
        XCTAssertNotNil(state.lastSnoozeTime)
        XCTAssertNotNil(state.snoozeUntil)
        XCTAssertTrue(state.isSnoozed)
    }

    func testSnoozeStateMultipleSnoozes() {
        var state = SnoozeState()
        state.snooze(for: 5)
        state.snooze(for: 5)
        state.snooze(for: 5)

        XCTAssertEqual(state.snoozeCount, 3)
    }

    func testSnoozeStateReset() {
        var state = SnoozeState()
        state.snooze(for: 5)
        state.snooze(for: 5)
        state.reset()

        XCTAssertEqual(state.snoozeCount, 0)
        XCTAssertNil(state.lastSnoozeTime)
        XCTAssertNil(state.snoozeUntil)
        XCTAssertFalse(state.isSnoozed)
    }

    // MARK: - Escalation Policy Tests

    func testEscalationPolicyDefaults() {
        let policy = EscalationPolicy()
        XCTAssertTrue(policy.enabled)
        XCTAssertEqual(policy.thresholdSnoozes, 3)
        XCTAssertEqual(policy.action, .suggestLongerBreak)
        XCTAssertEqual(policy.longerBreakMinutes, 5)
    }

    func testEscalationActionCodable() throws {
        for action in [
            EscalationPolicy.EscalationAction.suggestLongerBreak,
            .forceBreak, .notify,
        ] {
            let data = try JSONEncoder().encode(action)
            let decoded = try JSONDecoder().decode(
                EscalationPolicy.EscalationAction.self, from: data)
            XCTAssertEqual(decoded, action)
        }
    }

    // MARK: - Configuration Tests

    func testDefaultConfig() {
        let config = MicroNudgesConfig.default
        XCTAssertTrue(config.enabled)
        XCTAssertTrue(config.blink.enabled)
        XCTAssertTrue(config.posture.enabled)
        XCTAssertTrue(config.miniExercise.enabled)
    }

    func testConfigIntervals() {
        let config = MicroNudgesConfig.default
        XCTAssertEqual(config.blink.intervalSeconds, 20)
        XCTAssertEqual(config.posture.intervalSeconds, 25 * 60)
        XCTAssertEqual(config.miniExercise.intervalSeconds, 50 * 60)
    }

    func testConfigSnoozeOptions() {
        let config = MicroNudgesConfig.default
        XCTAssertEqual(config.snoozeOptions, [5, 10, 15, 30])
        XCTAssertEqual(config.maxSnoozesPerNudge, 3)
    }

    func testConfigForType() {
        let config = MicroNudgesConfig.default
        XCTAssertEqual(config.config(for: .blink).intervalSeconds, 20)
        XCTAssertEqual(config.config(for: .posture).style, .normal)
        XCTAssertEqual(config.config(for: .miniExercise).style, .prominent)
    }

    // MARK: - Nudge Event Tests

    func testNudgeEventCreation() {
        let event = NudgeEvent(type: .blink)
        XCTAssertEqual(event.type, .blink)
        XCTAssertFalse(event.message.isEmpty)
        XCTAssertNil(event.exercise)
    }

    func testNudgeEventWithExercise() {
        let exercise = MiniExercise.defaults[0]
        let event = NudgeEvent(type: .miniExercise, exercise: exercise)
        XCTAssertEqual(event.type, .miniExercise)
        XCTAssertNotNil(event.exercise)
        XCTAssertEqual(event.exercise?.name, exercise.name)
    }

    // MARK: - Manager Tests

    func testManagerSharedInstance() {
        let manager = MicroNudgesManager.shared
        XCTAssertNotNil(manager)
    }

    func testManagerInitialState() {
        let manager = MicroNudgesManager()
        XCTAssertFalse(manager.isRunning)
        XCTAssertNil(manager.currentNudge)
        XCTAssertEqual(manager.dailySnoozeCount, 0)
    }

    func testManagerSnoozeStatesInitialized() {
        let manager = MicroNudgesManager()
        for type in NudgeType.allCases {
            XCTAssertNotNil(manager.snoozeStates[type])
        }
    }

    func testManagerStartStop() {
        let manager = MicroNudgesManager()

        manager.start()
        XCTAssertTrue(manager.isRunning)

        manager.stop()
        XCTAssertFalse(manager.isRunning)
    }

    // MARK: - Interval Variance Tests

    func testNudgeConfigEffectiveIntervalWithoutVariance() {
        let config = NudgeConfig(intervalSeconds: 100, intervalVariance: 0)
        XCTAssertEqual(config.effectiveInterval, 100)
    }

    func testNudgeConfigEffectiveIntervalWithVariance() {
        let config = NudgeConfig(intervalSeconds: 100, intervalVariance: 10)

        // Run multiple times to verify it varies
        var intervals = Set<TimeInterval>()
        for _ in 0..<10 {
            intervals.insert(config.effectiveInterval)
        }

        // All should be in range [90, 110]
        for interval in intervals {
            XCTAssertGreaterThanOrEqual(interval, 90)
            XCTAssertLessThanOrEqual(interval, 110)
        }
    }
}
