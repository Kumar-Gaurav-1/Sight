import XCTest
@testable import Sight

final class RendererAPITests: XCTestCase {
    
    // MARK: - BreakStyle Tests
    
    func testBreakStyleSceneKey() {
        XCTAssertEqual(BreakStyle.calm.sceneStyleKey, "calm")
        XCTAssertEqual(BreakStyle.focus.sceneStyleKey, "focus")
        XCTAssertEqual(BreakStyle.energize.sceneStyleKey, "energize")
    }
    
    // MARK: - FloatingCounterParams Tests
    
    func testFloatingCounterParamsDefaults() {
        let params = FloatingCounterParams()
        XCTAssertEqual(params.position.x, 0.95, accuracy: 0.01)
        XCTAssertEqual(params.position.y, 0.05, accuracy: 0.01)
        XCTAssertTrue(params.visible)
        XCTAssertEqual(params.state, .idle)
    }
    
    func testFloatingCounterParamsCodable() throws {
        let params = FloatingCounterParams(
            position: CGPoint(x: 0.5, y: 0.5),
            visible: true,
            state: .work,
            formattedTime: "15:30"
        )
        
        let data = try JSONEncoder().encode(params)
        let decoded = try JSONDecoder().decode(FloatingCounterParams.self, from: data)
        
        XCTAssertEqual(decoded.formattedTime, "15:30")
        XCTAssertEqual(decoded.state, .work)
    }
    
    // MARK: - RendererMessage Tests
    
    func testRendererMessageShowPreBreakEncoding() throws {
        let message = RendererMessage.showPreBreak(preSeconds: 10)
        let data = try JSONEncoder().encode(message)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"showPreBreak\""))
        XCTAssertTrue(json.contains("\"preSeconds\""))
        XCTAssertTrue(json.contains("10"))
    }
    
    func testRendererMessageShowBreakEncoding() throws {
        let message = RendererMessage.showBreak(duration: 20, style: .calm)
        let data = try JSONEncoder().encode(message)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"showBreak\""))
        XCTAssertTrue(json.contains("\"calm\""))
    }
    
    func testRendererMessageRoundtrip() throws {
        let original = RendererMessage.showBreak(duration: 30, style: .focus)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RendererMessage.self, from: data)
        
        if case .showBreak(let duration, let style) = decoded {
            XCTAssertEqual(duration, 30)
            XCTAssertEqual(style, .focus)
        } else {
            XCTFail("Failed to decode message")
        }
    }
    
    // MARK: - Renderer Fallback Tests
    
    func testRendererSharedInstance() {
        let renderer = Renderer.shared
        XCTAssertNotNil(renderer)
    }
    
    // Note: Static method tests removed because they trigger UNUserNotificationCenter
    // which requires entitlements not available in unit test environment.
    // These are tested manually via the acceptance tests.
}
