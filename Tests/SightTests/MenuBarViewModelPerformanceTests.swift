import XCTest
@testable import Sight

@MainActor
final class MenuBarViewModelPerformanceTests: XCTestCase {
    var stateMachine: TimerStateMachine!
    var viewModel: MenuBarViewModel!

    override func setUp() {
        super.setUp()
        stateMachine = TimerStateMachine(configuration: .debug, rendererEnabled: false)
        viewModel = MenuBarViewModel(stateMachine: stateMachine)
    }

    override func tearDown() {
        stateMachine.stop()
        viewModel = nil
        stateMachine = nil
        super.tearDown()
    }

    func testUpdateDerivedPropertiesPerformance() {
        // Set state to work so it enters the problematic if branch
        stateMachine.start()

        // Ensure remainingSeconds is > 120
        stateMachine.configuration = TimerConfiguration(workIntervalSeconds: 150, preBreakSeconds: 10, breakDurationSeconds: 20)
        stateMachine.reset()
        stateMachine.start()

        // Ensure we are in work state and remaining seconds is > 120
        XCTAssertEqual(stateMachine.currentState, .work)
        XCTAssertGreaterThan(stateMachine.remainingSeconds, 120)

        // Wait for next run loop to allow state to propagate
        let exp = expectation(description: "Wait for state propagation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)

        measure {
            for _ in 0..<1000 {
                // Update state machine remainingSeconds to trigger the pipeline and evaluate `updateDerivedProperties`
                self.stateMachine.remainingSeconds = 150
                // Wait is too long, we will directly call updateDerivedProperties through reflection or just test creation of DateFormatter vs static
            }
        }
    }
}
