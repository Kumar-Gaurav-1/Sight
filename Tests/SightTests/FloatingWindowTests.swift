import XCTest
@testable import Sight

final class FloatingWindowTests: XCTestCase {
    
    // MARK: - Spring Physics Tests
    
    func testSpringPhysicsDefaultValues() {
        let spring = SpringPhysics.default
        XCTAssertEqual(spring.stiffness, 0.12)
        XCTAssertEqual(spring.damping, 0.85)
    }
    
    func testSpringPhysicsReducedMotionValues() {
        let spring = SpringPhysics.reducedMotion
        XCTAssertEqual(spring.stiffness, 0.5)
        XCTAssertEqual(spring.damping, 0.95)
    }
    
    func testSpringPhysicsUpdateMovesTowardsTarget() {
        var physics = SpringPhysics(stiffness: 0.12, damping: 0.85)
        
        let current = CGPoint(x: 0, y: 0)
        let target = CGPoint(x: 100, y: 100)
        
        let newPosition = physics.update(current: current, target: target, deltaTime: 1.0/60.0)
        
        // Should move towards target
        XCTAssertGreaterThan(newPosition.x, current.x)
        XCTAssertGreaterThan(newPosition.y, current.y)
        
        // Should not overshoot immediately
        XCTAssertLessThan(newPosition.x, target.x)
        XCTAssertLessThan(newPosition.y, target.y)
    }
    
    func testSpringPhysicsSettlesNearTarget() {
        var physics = SpringPhysics(stiffness: 0.12, damping: 0.85)
        
        var current = CGPoint(x: 0, y: 0)
        let target = CGPoint(x: 100, y: 100)
        
        // Simulate many frames
        for _ in 0..<200 {
            current = physics.update(current: current, target: target, deltaTime: 1.0/60.0)
        }
        
        // Should be very close to target after many iterations
        XCTAssertEqual(current.x, target.x, accuracy: 1.0)
        XCTAssertEqual(current.y, target.y, accuracy: 1.0)
    }
    
    func testSpringPhysicsIsSettled() {
        var physics = SpringPhysics(stiffness: 0.5, damping: 0.95)
        
        var current = CGPoint(x: 0, y: 0)
        let target = CGPoint(x: 10, y: 10)
        
        // Initial velocity should not be settled
        _ = physics.update(current: current, target: target, deltaTime: 1.0/60.0)
        XCTAssertFalse(physics.isSettled())
        
        // After many iterations with target reached, should settle
        for _ in 0..<500 {
            current = physics.update(current: current, target: target, deltaTime: 1.0/60.0)
        }
        
        XCTAssertTrue(physics.isSettled())
    }
    
    func testSpringPhysicsVelocityAccumulates() {
        var physics = SpringPhysics(stiffness: 0.12, damping: 0.85)
        
        let current = CGPoint(x: 0, y: 0)
        let target = CGPoint(x: 100, y: 0)
        
        // First update
        let pos1 = physics.update(current: current, target: target, deltaTime: 1.0/60.0)
        let vel1 = physics.velocity.x
        
        // Second update - velocity should increase (spring is still pulling)
        let pos2 = physics.update(current: pos1, target: target, deltaTime: 1.0/60.0)
        let vel2 = physics.velocity.x
        
        XCTAssertGreaterThan(vel2, vel1 * 0.5) // Velocity maintained with damping
        XCTAssertGreaterThan(pos2.x, pos1.x)  // Position advancing
    }
    
    // MARK: - Position Logic Tests
    
    func testTargetPositionCalculation() {
        let cursor = CGPoint(x: 500, y: 300)
        let offset = CGPoint(x: 20, y: 20)
        
        let target = FloatingWindowPositionLogic.targetPosition(
            cursorLocation: cursor,
            offset: offset
        )
        
        XCTAssertEqual(target.x, 520)
        XCTAssertEqual(target.y, 320)
    }
    
    func testTargetPositionWithNegativeOffset() {
        let cursor = CGPoint(x: 500, y: 300)
        let offset = CGPoint(x: -30, y: -30)
        
        let target = FloatingWindowPositionLogic.targetPosition(
            cursorLocation: cursor,
            offset: offset
        )
        
        XCTAssertEqual(target.x, 470)
        XCTAssertEqual(target.y, 270)
    }
    
    func testClampToScreenWithinBounds() {
        let position = CGPoint(x: 500, y: 300)
        let windowSize = CGSize(width: 100, height: 36)
        let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let clamped = FloatingWindowPositionLogic.clampToScreen(
            position: position,
            windowSize: windowSize,
            visibleFrame: visibleFrame,
            margin: 20,
            menubarHeight: 24
        )
        
        // Should remain unchanged (within bounds)
        XCTAssertEqual(clamped.x, 500)
        XCTAssertEqual(clamped.y, 300)
    }
    
    func testClampToScreenLeftEdge() {
        let position = CGPoint(x: -50, y: 300)
        let windowSize = CGSize(width: 100, height: 36)
        let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let clamped = FloatingWindowPositionLogic.clampToScreen(
            position: position,
            windowSize: windowSize,
            visibleFrame: visibleFrame,
            margin: 20,
            menubarHeight: 24
        )
        
        // Should be clamped to margin
        XCTAssertEqual(clamped.x, 20)
    }
    
    func testClampToScreenRightEdge() {
        let position = CGPoint(x: 2000, y: 300)
        let windowSize = CGSize(width: 100, height: 36)
        let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let clamped = FloatingWindowPositionLogic.clampToScreen(
            position: position,
            windowSize: windowSize,
            visibleFrame: visibleFrame,
            margin: 20,
            menubarHeight: 24
        )
        
        // Should be clamped to right edge minus window width and margin
        XCTAssertEqual(clamped.x, 1920 - 100 - 20)
    }
    
    func testClampToScreenTopEdge() {
        let position = CGPoint(x: 500, y: 1100)
        let windowSize = CGSize(width: 100, height: 36)
        let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let clamped = FloatingWindowPositionLogic.clampToScreen(
            position: position,
            windowSize: windowSize,
            visibleFrame: visibleFrame,
            margin: 20,
            menubarHeight: 24
        )
        
        // Should be clamped below menubar
        XCTAssertEqual(clamped.y, 1080 - 36 - 20 - 24)
    }
    
    func testClampToScreenBottomEdge() {
        let position = CGPoint(x: 500, y: -50)
        let windowSize = CGSize(width: 100, height: 36)
        let visibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        
        let clamped = FloatingWindowPositionLogic.clampToScreen(
            position: position,
            windowSize: windowSize,
            visibleFrame: visibleFrame,
            margin: 20,
            menubarHeight: 24
        )
        
        // Should be clamped to bottom margin
        XCTAssertEqual(clamped.y, 20)
    }
    
    // MARK: - Menubar Zone Tests
    
    func testCursorInMenubarZone() {
        let screenMaxY: CGFloat = 1080
        let menubarHeight: CGFloat = 24
        
        // Cursor in menubar zone
        let inZone = FloatingWindowPositionLogic.isCursorInMenubarZone(
            cursorY: 1070,
            screenMaxY: screenMaxY,
            menubarHeight: menubarHeight
        )
        XCTAssertTrue(inZone)
    }
    
    func testCursorNotInMenubarZone() {
        let screenMaxY: CGFloat = 1080
        let menubarHeight: CGFloat = 24
        
        // Cursor below menubar zone
        let inZone = FloatingWindowPositionLogic.isCursorInMenubarZone(
            cursorY: 500,
            screenMaxY: screenMaxY,
            menubarHeight: menubarHeight
        )
        XCTAssertFalse(inZone)
    }
    
    func testCursorExactlyAtMenubarBoundary() {
        let screenMaxY: CGFloat = 1080
        let menubarHeight: CGFloat = 24
        
        // Cursor exactly at boundary (1080 - 24 = 1056)
        let inZone = FloatingWindowPositionLogic.isCursorInMenubarZone(
            cursorY: 1056,
            screenMaxY: screenMaxY,
            menubarHeight: menubarHeight
        )
        XCTAssertTrue(inZone)
    }
    
    // MARK: - Static Corner Position Tests
    
    func testStaticCornerPosition() {
        let visibleFrame = CGRect(x: 0, y: 50, width: 1920, height: 1030)
        let windowSize = CGSize(width: 100, height: 36)
        let margin: CGFloat = 20
        
        let corner = FloatingWindowPositionLogic.staticCornerPosition(
            visibleFrame: visibleFrame,
            windowSize: windowSize,
            margin: margin
        )
        
        // Bottom-right corner
        XCTAssertEqual(corner.x, 1920 - 100 - 20)
        XCTAssertEqual(corner.y, 50 + 20)
    }
    
    // MARK: - Configuration Tests
    
    func testFloatingWindowConfigDefaults() {
        let config = FloatingWindowConfig.default
        
        XCTAssertEqual(config.windowSize.width, 100)
        XCTAssertEqual(config.windowSize.height, 36)
        XCTAssertEqual(config.cursorOffset.x, 20)
        XCTAssertEqual(config.cursorOffset.y, 20)
        XCTAssertEqual(config.edgeMargin, 20)
        XCTAssertEqual(config.menubarHeight, 24)
        XCTAssertEqual(config.targetFrameRate, 30)
    }
}
