import Foundation
import os.log

/// XPC Service protocol for renderer communication
@objc public protocol XPCRendererProtocol {
    func showPreBreak(preSeconds: Int, reply: @escaping (Bool) -> Void)
    func showBreak(duration: Int, styleRaw: String, reply: @escaping (Bool) -> Void)
    func showFloatingCounter(paramsData: Data, reply: @escaping (Bool) -> Void)
    func showNudge(typeRaw: String, reply: @escaping (Bool) -> Void)
    func updateCountdown(remainingSeconds: Int)
    func hide()
    func ping(reply: @escaping (Bool) -> Void)
}

/// XPC-based renderer client
/// Uses macOS XPC for secure, sandboxed IPC with the renderer process
public final class XPCRendererClient: RendererAPI {

    // MARK: - Properties

    private let connection: NSXPCConnection
    private let logger = Logger(subsystem: "com.sight.renderer", category: "XPC")
    private var _isAvailable = false

    public var isAvailable: Bool { _isAvailable }

    // MARK: - XPC Service Identifier

    /// Bundle identifier for the XPC service
    public static let serviceIdentifier = "com.sight.renderer.xpc"

    // MARK: - Initialization

    public init() {
        connection = NSXPCConnection(serviceName: Self.serviceIdentifier)
        connection.remoteObjectInterface = NSXPCInterface(with: XPCRendererProtocol.self)

        connection.interruptionHandler = { [weak self] in
            self?.logger.warning("XPC connection interrupted")
            self?._isAvailable = false
        }

        connection.invalidationHandler = { [weak self] in
            self?.logger.warning("XPC connection invalidated")
            self?._isAvailable = false
        }

        connection.resume()
        checkAvailability()
    }

    deinit {
        connection.invalidate()
    }

    // MARK: - Private Helpers

    private var proxy: XPCRendererProtocol? {
        connection.remoteObjectProxyWithErrorHandler { [weak self] error in
            self?.logger.error("XPC error: \(error.localizedDescription)")
            self?._isAvailable = false
        } as? XPCRendererProtocol
    }

    private func checkAvailability() {
        proxy?.ping { [weak self] success in
            self?._isAvailable = success
            self?.logger.info("XPC renderer available: \(success)")
        }
    }

    // MARK: - RendererAPI

    public func showPreBreak(preSeconds: Int) {
        logger.info("XPC: showPreBreak(\(preSeconds))")
        proxy?.showPreBreak(preSeconds: preSeconds) { success in
            // Handle response if needed
        }
    }

    public func showBreak(duration: Int, style: BreakStyle) {
        logger.info("XPC: showBreak(\(duration), \(style.rawValue))")
        proxy?.showBreak(duration: duration, styleRaw: style.rawValue) { success in
            // Handle response if needed
        }
    }

    public func showFloatingCounter(params: FloatingCounterParams) {
        guard let data = try? JSONEncoder().encode(params) else {
            logger.error("Failed to encode floating counter params")
            return
        }
        proxy?.showFloatingCounter(paramsData: data) { success in
            // Handle response if needed
        }
    }

    public func showNudge(type: NudgeType) {
        logger.info("XPC: showNudge(\(type.rawValue))")
        proxy?.showNudge(typeRaw: type.rawValue) { success in
            // Handle response if needed
        }
    }

    public func updateCountdown(remainingSeconds: Int) {
        proxy?.updateCountdown(remainingSeconds: remainingSeconds)
    }

    public func hide() {
        logger.info("XPC: hide()")
        proxy?.hide()
    }
}

// MARK: - XPC Service Implementation (Renderer Side)

/// Base class for XPC service implementation
/// The actual renderer would subclass this
open class XPCRendererServiceBase: NSObject, XPCRendererProtocol {

    private let logger = Logger(subsystem: "com.sight.renderer", category: "XPCService")

    // SECURITY: Maximum allowed string lengths to prevent log injection and DoS
    private let maxStyleLength = 64
    private let maxNudgeTypeLength = 64
    private let maxParamsDataSize = 64 * 1024  // 64KB

    public func showPreBreak(preSeconds: Int, reply: @escaping (Bool) -> Void) {
        // SECURITY: Validate preSeconds is within reasonable bounds
        guard preSeconds > 0 && preSeconds <= 300 else {
            logger.warning("Invalid preSeconds value: out of bounds")
            reply(false)
            return
        }
        logger.info("Service: showPreBreak(\(preSeconds))")
        // Override in subclass to implement actual rendering
        reply(true)
    }

    public func showBreak(duration: Int, styleRaw: String, reply: @escaping (Bool) -> Void) {
        // SECURITY: Validate inputs
        guard duration > 0 && duration <= 3600 else {
            logger.warning("Invalid break duration: out of bounds")
            reply(false)
            return
        }
        guard styleRaw.count <= maxStyleLength else {
            logger.warning("Invalid style: too long")
            reply(false)
            return
        }
        guard BreakStyle(rawValue: styleRaw) != nil else {
            logger.warning("Invalid style: unknown value")
            reply(false)
            return
        }
        logger.info("Service: showBreak(\(duration), validated)")
        // Override in subclass to implement actual rendering
        reply(true)
    }

    public func showFloatingCounter(paramsData: Data, reply: @escaping (Bool) -> Void) {
        // SECURITY: Validate data size
        guard paramsData.count <= maxParamsDataSize else {
            logger.warning("Invalid params: data too large")
            reply(false)
            return
        }
        // Validate JSON structure
        guard (try? JSONDecoder().decode(FloatingCounterParams.self, from: paramsData)) != nil
        else {
            logger.warning("Invalid params: failed to decode")
            reply(false)
            return
        }
        logger.info("Service: showFloatingCounter (validated)")
        // Override in subclass to implement actual rendering
        reply(true)
    }

    public func showNudge(typeRaw: String, reply: @escaping (Bool) -> Void) {
        // SECURITY: Validate inputs
        guard typeRaw.count <= maxNudgeTypeLength else {
            logger.warning("Invalid nudge type: too long")
            reply(false)
            return
        }
        guard NudgeType(rawValue: typeRaw) != nil else {
            logger.warning("Invalid nudge type: unknown value")
            reply(false)
            return
        }
        logger.info("Service: showNudge (validated)")
        reply(true)
    }

    public func updateCountdown(remainingSeconds: Int) {
        // SECURITY: Validate bounds (no reply needed for this method)
        guard remainingSeconds >= 0 && remainingSeconds <= 3600 else {
            return
        }
        // Override in subclass
    }

    public func hide() {
        logger.info("Service: hide()")
        // Override in subclass
    }

    public func ping(reply: @escaping (Bool) -> Void) {
        reply(true)
    }
}
