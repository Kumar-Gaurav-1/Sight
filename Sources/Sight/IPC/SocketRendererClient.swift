import Foundation
import os.log

/// Unix socket-based renderer client
/// Uses local domain sockets for cross-process communication
/// Better for development and debugging
public final class SocketRendererClient: RendererAPI {

    // MARK: - Properties

    private let socketPath: String
    private var socket: Int32 = -1
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.renderer", category: "Socket")
    private let queue = DispatchQueue(label: "com.sight.socket", qos: .userInteractive)
    private var _isAvailable = false

    public var isAvailable: Bool { _isAvailable }

    // MARK: - Socket Path

    /// Default socket path in user's temporary directory
    public static var defaultSocketPath: String {
        let tmpDir = FileManager.default.temporaryDirectory
        return tmpDir.appendingPathComponent("sight-renderer.sock").path
    }

    // MARK: - Initialization

    public init(socketPath: String = SocketRendererClient.defaultSocketPath) {
        self.socketPath = socketPath
        connect()
    }

    deinit {
        disconnect()
    }

    // MARK: - Connection Management

    private func connect() {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.socket = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
            guard self.socket >= 0 else {
                self.logger.error("Failed to create socket")
                return
            }

            var addr = sockaddr_un()
            addr.sun_family = sa_family_t(AF_UNIX)

            // Copy socket path to sun_path safely
            let pathSize = MemoryLayout.size(ofValue: addr.sun_path)
            self.socketPath.withCString { cPath in
                withUnsafeMutableBytes(of: &addr.sun_path) { buffer in
                    let dest = buffer.baseAddress!.assumingMemoryBound(to: CChar.self)
                    strncpy(dest, cPath, pathSize - 1)
                }
            }

            let result = withUnsafePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                    Darwin.connect(self.socket, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
                }
            }

            if result == 0 {
                self._isAvailable = true
                self.logger.info("Connected to renderer socket")
            } else {
                self.logger.warning("Failed to connect to socket: \(errno)")
                Darwin.close(self.socket)
                self.socket = -1
            }
        }
    }

    private func disconnect() {
        if socket >= 0 {
            Darwin.close(socket)
            socket = -1
        }
        _isAvailable = false
    }

    // MARK: - Message Sending

    private func send(_ message: RendererMessage) {
        queue.async { [weak self] in
            guard let self = self, self.socket >= 0 else {
                self?.logger.warning("Socket not connected")
                return
            }

            do {
                let data = try JSONEncoder().encode(message)
                let lengthData = withUnsafeBytes(of: UInt32(data.count).bigEndian) { Data($0) }

                // Send length prefix
                _ = lengthData.withUnsafeBytes { ptr in
                    Darwin.send(self.socket, ptr.baseAddress!, lengthData.count, 0)
                }

                // Send message data
                _ = data.withUnsafeBytes { ptr in
                    Darwin.send(self.socket, ptr.baseAddress!, data.count, 0)
                }

            } catch {
                self.logger.error("Failed to encode message: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - RendererAPI

    public func showPreBreak(preSeconds: Int) {
        logger.info("Socket: showPreBreak(\(preSeconds))")
        send(.showPreBreak(preSeconds: preSeconds))
    }

    public func showBreak(duration: Int, style: BreakStyle) {
        logger.info("Socket: showBreak(\(duration), \(style.rawValue))")
        send(.showBreak(duration: duration, style: style))
    }

    public func showFloatingCounter(params: FloatingCounterParams) {
        logger.info("Socket: showFloatingCounter")
        send(.showFloatingCounter(params: params))
    }

    public func showNudge(type: NudgeType) {
        logger.info("Socket: showNudge(\(type.rawValue))")
        send(.showNudge(type: type))
    }

    public func updateCountdown(remainingSeconds: Int) {
        send(.updateCountdown(remainingSeconds: remainingSeconds))
    }

    public func hide() {
        logger.info("Socket: hide()")
        send(.hide)
    }
}

// MARK: - Socket Server (Renderer Side)

/// Simple socket server for the renderer process
/// Used for development and testing
public final class SocketRendererServer {

    private let socketPath: String
    private var serverSocket: Int32 = -1
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.renderer", category: "SocketServer")
    private let queue = DispatchQueue(label: "com.sight.socket.server")

    public var onMessage: ((RendererMessage) -> Void)?

    public init(socketPath: String = SocketRendererClient.defaultSocketPath) {
        self.socketPath = socketPath
    }

    public func start() {
        queue.async { [weak self] in
            self?.startServer()
        }
    }

    public func stop() {
        if serverSocket >= 0 {
            Darwin.close(serverSocket)
            serverSocket = -1
        }
        unlink(socketPath)
    }

    private func startServer() {
        // Remove existing socket file
        unlink(socketPath)

        serverSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            logger.error("Failed to create server socket")
            return
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)

        // Copy socket path to sun_path safely
        let pathSize = MemoryLayout.size(ofValue: addr.sun_path)
        socketPath.withCString { cPath in
            withUnsafeMutableBytes(of: &addr.sun_path) { buffer in
                let dest = buffer.baseAddress!.assumingMemoryBound(to: CChar.self)
                strncpy(dest, cPath, pathSize - 1)
            }
        }

        let bindResult = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockPtr in
                bind(serverSocket, sockPtr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }

        guard bindResult == 0 else {
            logger.error("Failed to bind socket")
            return
        }

        // SECURITY: Restrict socket file permissions to owner-only (0600)
        // This prevents other users from connecting to the socket
        chmod(socketPath, 0o600)

        guard listen(serverSocket, 5) == 0 else {
            logger.error("Failed to listen on socket")
            return
        }

        logger.info("Socket server listening on \(self.socketPath)")
        acceptConnections()
    }

    // SECURITY: Maximum concurrent connections to prevent DoS
    private let maxConnections = 10
    private var activeConnections = 0
    private let connectionLock = NSLock()

    private func acceptConnections() {
        while serverSocket >= 0 {
            let clientSocket = accept(serverSocket, nil, nil)
            guard clientSocket >= 0 else { continue }

            // SECURITY: Enforce connection limit
            connectionLock.lock()
            let currentConnections = activeConnections
            if currentConnections >= maxConnections {
                connectionLock.unlock()
                logger.warning("Connection limit reached, rejecting client")
                Darwin.close(clientSocket)
                continue
            }
            activeConnections += 1
            connectionLock.unlock()

            logger.info("Client connected (\\(currentConnections + 1)/\\(maxConnections))")
            handleClient(clientSocket)
        }
    }

    private func handleClient(_ clientSocket: Int32) {
        queue.async { [weak self] in
            defer {
                Darwin.close(clientSocket)
                // SECURITY: Release connection slot when client disconnects
                self?.connectionLock.lock()
                self?.activeConnections -= 1
                self?.connectionLock.unlock()
            }

            var lengthBuffer = [UInt8](repeating: 0, count: 4)

            while true {
                // Read length prefix
                let lengthRead = recv(clientSocket, &lengthBuffer, 4, 0)
                guard lengthRead == 4 else { break }

                let length = Int(
                    UInt32(bigEndian: lengthBuffer.withUnsafeBytes { $0.load(as: UInt32.self) }))
                // SECURITY: Reduced max message size from 1MB to 64KB to prevent DoS attacks
                guard length > 0 && length < 64 * 1024 else { break }

                // Read message data
                var messageBuffer = [UInt8](repeating: 0, count: length)
                let messageRead = recv(clientSocket, &messageBuffer, length, 0)
                guard messageRead == length else { break }

                // Decode and handle message
                let data = Data(messageBuffer)
                if let message = try? JSONDecoder().decode(RendererMessage.self, from: data) {
                    DispatchQueue.main.async {
                        self?.onMessage?(message)
                    }
                }
            }
        }
    }
}
