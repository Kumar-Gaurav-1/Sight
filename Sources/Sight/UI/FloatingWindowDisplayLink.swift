import AppKit
import os.log

public final class FloatingWindowDisplayLink {
    private let logger = Logger(subsystem: "com.kumargaurav.Sight.ui", category: "FloatingWindowDisplayLink")

    private var displayLink: CVDisplayLink?
    private var displayLinkActive = false
    private var fallbackTimer: Timer?

    private let updateAction: () -> Void
    private let targetFrameRate: () -> Int

    public init(targetFrameRate: @escaping () -> Int, updateAction: @escaping () -> Void) {
        self.targetFrameRate = targetFrameRate
        self.updateAction = updateAction
    }

    deinit {
        stop()
    }

    public func start() {
        guard displayLink == nil else { return }

        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard let displayLink = link else {
            logger.warning("Failed to create CVDisplayLink, using fallback timer")
            startFallbackTimer()
            return
        }

        self.displayLink = displayLink
        displayLinkActive = true

        let outputCallback: CVDisplayLinkOutputCallback = {
            displayLink, inNow, inOutputTime, flagsIn, flagsOut, displayLinkContext -> CVReturn in
            guard let context = displayLinkContext else { return kCVReturnSuccess }

            let manager = Unmanaged<FloatingWindowDisplayLink>.fromOpaque(context).takeUnretainedValue()
            guard manager.displayLinkActive else { return kCVReturnSuccess }

            DispatchQueue.main.async { [weak manager] in
                guard let manager = manager, manager.displayLinkActive else { return }
                manager.updateAction()
            }
            return kCVReturnSuccess
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, outputCallback, selfPointer)
        CVDisplayLinkStart(displayLink)
        logger.info("CVDisplayLink started")
    }

    public func stop() {
        displayLinkActive = false
        if let link = displayLink {
            CVDisplayLinkStop(link)
            displayLink = nil
        }
        stopFallbackTimer()
    }

    private func startFallbackTimer() {
        let interval = 1.0 / Double(targetFrameRate())
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateAction()
        }
    }

    private func stopFallbackTimer() {
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }
}
