import XCTest
@testable import Sight

final class TimerStateMachineTests: XCTestCase {
    
    var stateMachine: TimerStateMachine!
    
    override func setUp() {
        super.setUp()
        // Disable renderer to prevent UNUserNotificationCenter crashes
        stateMachine = TimerStateMachine(configuration: .debug, rendererEnabled: false)
    }
    
    override func tearDown() {
        stateMachine.stop()
        stateMachine = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialStateIsIdle() {
        XCTAssertEqual(stateMachine.currentState, .idle)
    }
    
    func testInitialRemainingSecondsIsZero() {
        XCTAssertEqual(stateMachine.remainingSeconds, 0)
    }
    
    // MARK: - Start/Stop Tests
    
    func testStartTransitionsToWork() {
        stateMachine.start()
        XCTAssertEqual(stateMachine.currentState, .work)
    }
    
    func testStopReturnsToIdle() {
        stateMachine.start()
        stateMachine.stop()
        XCTAssertEqual(stateMachine.currentState, .idle)
    }
    
    func testToggleFromIdleStarts() {
        stateMachine.toggle()
        XCTAssertEqual(stateMachine.currentState, .work)
    }
    
    func testToggleFromWorkStops() {
        stateMachine.start()
        stateMachine.toggle()
        XCTAssertEqual(stateMachine.currentState, .idle)
    }
    
    // MARK: - Skip Tests
    
    func testSkipFromWorkTransitionsToPreBreak() {
        stateMachine.start()
        stateMachine.skipToNext()
        XCTAssertEqual(stateMachine.currentState, .preBreak)
    }
    
    func testSkipFromPreBreakTransitionsToBreak() {
        stateMachine.start()
        stateMachine.skipToNext() // work -> preBreak
        stateMachine.skipToNext() // preBreak -> break
        XCTAssertEqual(stateMachine.currentState, .break)
    }
    
    func testSkipFromBreakTransitionsToWork() {
        stateMachine.start()
        stateMachine.skipToNext() // work -> preBreak
        stateMachine.skipToNext() // preBreak -> break
        stateMachine.skipToNext() // break -> work
        XCTAssertEqual(stateMachine.currentState, .work)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationChangeSetsRemainingSeconds() {
        let config = TimerConfiguration(
            workIntervalSeconds: 100,
            preBreakSeconds: 10,
            breakDurationSeconds: 20
        )
        stateMachine.configuration = config
        stateMachine.start()
        XCTAssertEqual(stateMachine.remainingSeconds, 100)
    }
    
    // MARK: - State Enum Tests
    
    func testTimerStateDisplayNames() {
        XCTAssertEqual(TimerState.idle.displayName, "Idle")
        XCTAssertEqual(TimerState.work.displayName, "Working")
        XCTAssertEqual(TimerState.preBreak.displayName, "Break Soon")
        XCTAssertEqual(TimerState.break.displayName, "On Break")
    }
    
    func testTimerStateIconNames() {
        XCTAssertEqual(TimerState.idle.iconName, "eye")
        XCTAssertEqual(TimerState.work.iconName, "eye.fill")
        XCTAssertEqual(TimerState.preBreak.iconName, "eye.trianglebadge.exclamationmark")
        XCTAssertEqual(TimerState.break.iconName, "eye.slash.fill")
    }
}
