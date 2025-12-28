import AppKit
import Combine
import CoreImage
import Metal
import MetalKit
import SwiftUI
import os.log

// MARK: - Quality Tier

/// Quality tiers for break overlay rendering
public enum OverlayQualityTier: String, CaseIterable, Codable {
    case high  // GPU Metal shader, 60fps
    case medium  // GPU with reduced samples, 30fps
    case low  // CoreImage fallback, 15fps
    case minimal  // Static blurred image

    public var usesGPU: Bool {
        switch self {
        case .high, .medium: return true
        case .low, .minimal: return false
        }
    }

    public var targetFPS: Int {
        switch self {
        case .high: return 60
        case .medium: return 30
        case .low: return 15
        case .minimal: return 1
        }
    }

    public var blurSamples: Int {
        switch self {
        case .high: return 13
        case .medium: return 7
        case .low: return 5
        case .minimal: return 3
        }
    }
}

// MARK: - Shader Uniforms

/// Uniforms passed to Metal shader
struct BreakOverlayUniforms {
    var time: Float = 0
    var blurRadius: Float = 0.5
    var vignetteRadius: Float = 0.4
    var vignetteSoft: Float = 0.3
    var breathePhase: Float = 0
    var breatheScale: Float = 1.0
    var resolution: SIMD2<Float> = .zero
    var center: SIMD2<Float> = SIMD2(0.5, 0.5)
}

// MARK: - Break Overlay Configuration

public struct BreakOverlayConfig {
    public var qualityTier: OverlayQualityTier = .high
    public var blurRadius: Float = 0.5
    public var vignetteRadius: Float = 0.4
    public var vignetteSoftness: Float = 0.3
    public var breathingSpeed: Float = 1.0  // cycles per second
    public var breathingScale: Float = 1.0
    public var tintColor: NSColor = NSColor(red: 0.1, green: 0.15, blue: 0.25, alpha: 1)

    public static let `default` = BreakOverlayConfig()

    /// Low power configuration
    public static let lowPower = BreakOverlayConfig(
        qualityTier: .low,
        blurRadius: 0.3,
        breathingSpeed: 0.5,
        breathingScale: 0.5
    )
}

// MARK: - Metal Overlay View

/// MTKView-based overlay renderer using Metal shaders
public final class MetalOverlayView: MTKView, MTKViewDelegate {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.sight.overlay", category: "Metal")

    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var screenTexture: MTLTexture?

    private var uniforms = BreakOverlayUniforms()
    private var startTime: CFTimeInterval = 0

    // SECURITY: Flag to indicate if Metal setup succeeded
    private var metalAvailable = false

    public var config: BreakOverlayConfig = .default {
        didSet { updateConfig() }
    }

    // MARK: - Initialization

    public init(frame: CGRect, config: BreakOverlayConfig = .default) {
        self.config = config

        // SECURITY: Graceful fallback instead of fatalError when Metal is unavailable
        guard let device = MTLCreateSystemDefaultDevice() else {
            // Initialize with nil device - will use fallback rendering
            super.init(frame: frame, device: nil)
            logger.warning("Metal not supported - using fallback rendering")
            metalAvailable = false
            return
        }

        super.init(frame: frame, device: device)
        metalAvailable = true

        self.delegate = self
        self.framebufferOnly = false
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0.9)

        setupMetal()
        updateConfig()

        logger.info("MetalOverlayView initialized")
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Metal Setup

    private func setupMetal() {
        guard let device = device else { return }

        // Command queue
        commandQueue = device.makeCommandQueue()

        // Try to load pre-compiled library first
        if let library = device.makeDefaultLibrary() {
            setupPipeline(with: library, device: device)
            return
        }

        // Try to compile shader from source
        if let shaderSource = loadShaderSource() {
            do {
                let library = try device.makeLibrary(source: shaderSource, options: nil)
                setupPipeline(with: library, device: device)
                return
            } catch {
                logger.error("Failed to compile Metal shader: \(error.localizedDescription)")
            }
        }

        // Final fallback - use embedded minimal shader
        let fallbackShader = createFallbackShader()
        do {
            let library = try device.makeLibrary(source: fallbackShader, options: nil)
            setupPipeline(with: library, device: device)
        } catch {
            logger.error("Failed to create fallback shader: \(error.localizedDescription)")
        }
    }

    private func loadShaderSource() -> String? {
        // Try to load from bundle resources
        if let url = Bundle.module.url(
            forResource: "BreakOverlay", withExtension: "metal", subdirectory: "Shaders")
        {
            return try? String(contentsOf: url, encoding: .utf8)
        }

        // Try the Overlay/Shaders path
        if let url = Bundle.module.url(forResource: "BreakOverlay", withExtension: "metal") {
            return try? String(contentsOf: url, encoding: .utf8)
        }

        logger.warning("Could not find Metal shader source file")
        return nil
    }

    private func createFallbackShader() -> String {
        """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                                       constant float4 *vertices [[buffer(0)]]) {
            VertexOut out;
            float2 pos = vertices[vertexID].xy;
            out.position = float4(pos, 0.0, 1.0);
            out.texCoord = vertices[vertexID].zw;
            return out;
        }

        fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                        constant float *uniforms [[buffer(0)]]) {
            float time = uniforms[0];
            
            // Simple breathing effect with vignette
            float2 uv = in.texCoord;
            float2 center = float2(0.5, 0.5);
            float dist = length(uv - center);
            
            // Vignette
            float vignette = 1.0 - smoothstep(0.3, 0.8, dist);
            
            // Breathing circle
            float breathe = sin(time * 2.0) * 0.5 + 0.5;
            float circleRadius = 0.1 + breathe * 0.05;
            float circle = smoothstep(circleRadius + 0.02, circleRadius, dist);
            
            // Base color
            float3 baseColor = float3(0.1, 0.12, 0.18);
            float3 circleColor = float3(0.4, 0.6, 0.9) * circle;
            
            float3 finalColor = mix(baseColor, circleColor, circle) * vignette;
            return float4(finalColor, 0.9);
        }
        """
    }

    private func setupPipeline(with library: MTLLibrary, device: MTLDevice) {
        // Get shader functions
        guard let vertexFunc = library.makeFunction(name: "vertexShader"),
            let fragmentFunc = library.makeFunction(name: "fragmentShader")
        else {
            logger.error("Failed to load shader functions")
            return
        }

        // Pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        // Enable blending
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        // Vertex descriptor
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4

        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            logger.error("Failed to create pipeline state: \(error.localizedDescription)")
            return
        }

        // Create vertex buffer (fullscreen quad)
        let vertices: [Float] = [
            // Position    // TexCoord
            -1.0, 1.0, 0.0, 0.0,  // Top-left
            -1.0, -1.0, 0.0, 1.0,  // Bottom-left
            1.0, 1.0, 1.0, 0.0,  // Top-right
            1.0, -1.0, 1.0, 1.0,  // Bottom-right
        ]

        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<Float>.size,
            options: .storageModeShared)

        // Uniform buffer
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<BreakOverlayUniforms>.size,
            options: .storageModeShared)

        startTime = CACurrentMediaTime()

        logger.info("Metal pipeline created successfully")
    }

    private func updateConfig() {
        uniforms.blurRadius = config.blurRadius
        uniforms.vignetteRadius = config.vignetteRadius
        uniforms.vignetteSoft = config.vignetteSoftness
        uniforms.breatheScale = config.breathingScale

        // Adjust frame rate based on quality tier
        preferredFramesPerSecond = config.qualityTier.targetFPS
    }

    // MARK: - Screen Capture

    /// Capture current screen content for blur effect
    public func captureScreen() {
        guard let device = device else { return }

        // Capture screen using CGWindowListCreateImage
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame

        guard
            let cgImage = CGWindowListCreateImage(
                screenRect,
                .optionOnScreenBelowWindow,
                kCGNullWindowID,
                [.bestResolution]
            )
        else {
            logger.warning("Failed to capture screen")
            return
        }

        // Create Metal texture from image
        let loader = MTKTextureLoader(device: device)
        do {
            screenTexture = try loader.newTexture(
                cgImage: cgImage,
                options: [
                    .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                    .SRGB: false,
                ])
        } catch {
            logger.error("Failed to create texture: \(error.localizedDescription)")
        }
    }

    // MARK: - MTKViewDelegate

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.resolution = SIMD2(Float(size.width), Float(size.height))
    }

    public func draw(in view: MTKView) {
        guard let pipelineState = pipelineState,
            let commandQueue = commandQueue,
            let drawable = currentDrawable,
            let descriptor = currentRenderPassDescriptor,
            let vertexBuffer = vertexBuffer,
            let uniformBuffer = uniformBuffer
        else {
            return
        }

        // Update uniforms
        let currentTime = CACurrentMediaTime()
        let elapsed = Float(currentTime - startTime)
        uniforms.time = elapsed
        uniforms.breathePhase = elapsed * config.breathingSpeed * 2 * .pi

        // Copy uniforms to buffer
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<BreakOverlayUniforms>.size)

        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)

        if let texture = screenTexture {
            encoder.setFragmentTexture(texture, index: 0)
        }

        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - CoreImage Fallback

/// CoreImage-based fallback for low-power mode
public final class CoreImageOverlayView: NSView {

    private let logger = Logger(subsystem: "com.sight.overlay", category: "CoreImage")

    private var blurredImage: NSImage?
    private var ciContext: CIContext?
    private var displayLink: CVDisplayLink?
    private var breathePhase: CGFloat = 0
    private var breathingTimer: Timer?  // Store timer reference

    public var config: BreakOverlayConfig = .lowPower {
        didSet { needsDisplay = true }
    }

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCoreImage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    deinit {
        stopBreathing()
    }

    private func setupCoreImage() {
        // Create CIContext for rendering
        ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .priorityRequestLow: true,
        ])

        logger.info("CoreImage fallback initialized")
    }

    // MARK: - Screen Capture and Blur

    /// Capture and blur screen content
    public func captureAndBlur() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame

        // Capture screen
        guard
            let cgImage = CGWindowListCreateImage(
                screenRect,
                .optionOnScreenBelowWindow,
                kCGNullWindowID,
                [.bestResolution]
            )
        else {
            logger.warning("Failed to capture screen")
            return
        }

        // Apply CoreImage blur
        let ciImage = CIImage(cgImage: cgImage)

        // Box blur (faster than Gaussian)
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return }
        blurFilter.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter.setValue(config.blurRadius, forKey: kCIInputRadiusKey)

        guard let blurredCI = blurFilter.outputImage else { return }

        // Add vignette
        guard let vignetteFilter = CIFilter(name: "CIVignette") else { return }
        vignetteFilter.setValue(blurredCI, forKey: kCIInputImageKey)
        vignetteFilter.setValue(config.vignetteRadius * 2, forKey: kCIInputRadiusKey)
        vignetteFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let finalCI = vignetteFilter.outputImage,
            let context = ciContext,
            let outputCG = context.createCGImage(finalCI, from: ciImage.extent)
        else {
            return
        }

        blurredImage = NSImage(cgImage: outputCG, size: screenRect.size)
        needsDisplay = true

        logger.debug("Screen captured and blurred")
    }

    // MARK: - Drawing

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw blurred background
        if let image = blurredImage {
            image.draw(in: bounds)
        } else {
            // Fallback solid color
            NSColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 0.9).setFill()
            bounds.fill()
        }

        // Draw breathing circle
        drawBreathingCircle()
    }

    private func drawBreathingCircle() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let baseRadius: CGFloat = 60
        let breatheOffset = sin(breathePhase) * 10 * CGFloat(config.breathingScale)
        let radius = baseRadius + breatheOffset

        let circlePath = NSBezierPath(
            ovalIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))

        // Gradient fill
        let gradient = NSGradient(colors: [
            NSColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 0.6),
            NSColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 0.2),
        ])

        gradient?.draw(in: circlePath, relativeCenterPosition: .zero)
    }

    // MARK: - Animation

    public func startBreathing() {
        stopBreathing()  // Invalidate any existing timer first
        breathingTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / Double(config.qualityTier.targetFPS),
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            self.breathePhase += CGFloat(self.config.breathingSpeed) * 0.1
            self.needsDisplay = true
        }
    }

    public func stopBreathing() {
        breathingTimer?.invalidate()
        breathingTimer = nil
    }
}

// MARK: - Break Overlay Manager

/// Manages break overlay presentation with automatic quality selection
/// Manages break overlay presentation with automatic quality selection
public final class BreakOverlayManager: ObservableObject {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.sight.overlay", category: "Manager")

    @Published public private(set) var isShowing = false
    @Published public private(set) var currentTier: OverlayQualityTier = .high

    private var overlayWindows: [NSWindow] = []
    private var metalViews: [MetalOverlayView] = []
    private var coreImageViews: [CoreImageOverlayView] = []
    private var escapeMonitor: Any?

    // SECURITY: Cancellable work item for auto-hide timer
    private var autoHideWorkItem: DispatchWorkItem?

    public var config: BreakOverlayConfig = .default

    // MARK: - Singleton

    public static let shared = BreakOverlayManager()

    // MARK: - Public API

    /// Show break overlay on all screens
    public func show(duration: Int, style: BreakStyle = .calm) {
        guard !isShowing else { return }

        // Select quality tier based on power state
        selectQualityTier()

        // Create overlay on each screen
        for screen in NSScreen.screens {
            createOverlayWindow(for: screen, duration: duration, isPrimary: screen == NSScreen.main)
        }

        isShowing = true
        setupEscapeHandler()

        logger.info("Break overlay shown on \(NSScreen.screens.count) screen(s)")

        // SECURITY: Auto-hide after duration with cancellable work item
        autoHideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        autoHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration), execute: workItem)
    }

    /// Hide break overlay from all screens
    public func hide() {
        guard isShowing else { return }

        logger.info("Hiding break overlay from all screens")

        // SECURITY: Cancel pending auto-hide work item
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil

        // Remove escape handler
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }

        // Close all windows
        for window in overlayWindows {
            window.orderOut(nil)
        }

        overlayWindows.removeAll()
        metalViews.removeAll()
        coreImageViews.removeAll()
        isShowing = false

        // Notify that break ended (for manual breaks to resume timer)
        NotificationCenter.default.post(
            name: NSNotification.Name("SightBreakEnded"), object: nil)
    }

    // MARK: - Emergency Escape Handler

    private func setupEscapeHandler() {
        // Escape or Cmd+Escape to close overlay (Escape alone after 3 seconds as safety)
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Cmd+Escape = immediate emergency exit
            if event.keyCode == 53 && event.modifierFlags.contains(.command) {
                self.logger.info("Emergency exit: Cmd+Escape pressed")
                self.hide()
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightSkipBreak"), object: nil)
                return nil
            }

            // Plain Escape = skip break (works always)
            if event.keyCode == 53 && !event.modifierFlags.contains(.command) {
                self.logger.info("Skip break: Escape pressed")
                self.hide()
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightSkipBreak"), object: nil)
                return nil
            }

            return event
        }
    }

    // MARK: - Quality Selection

    private func selectQualityTier() {
        // Check low power mode
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            currentTier = .low
            return
        }

        // Check for Metal support
        if MTLCreateSystemDefaultDevice() == nil {
            currentTier = .low
            return
        }

        // Check thermal state
        let thermalState = ProcessInfo.processInfo.thermalState
        switch thermalState {
        case .nominal, .fair:
            currentTier = config.qualityTier
        case .serious:
            currentTier = .medium
        case .critical:
            currentTier = .low
        @unknown default:
            currentTier = .medium
        }
    }

    // MARK: - Window Creation

    private func createOverlayWindow(for screen: NSScreen, duration: Int, isPrimary: Bool) {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = !isPrimary  // Only primary screen is interactive
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Container view
        let containerView = NSView(frame: screen.frame)

        // Background (Metal or CoreImage)
        if currentTier.usesGPU {
            let metalView = MetalOverlayView(frame: screen.frame, config: config)
            metalView.captureScreen()
            metalView.autoresizingMask = [.width, .height]
            containerView.addSubview(metalView)
            metalViews.append(metalView)
        } else {
            let ciView = CoreImageOverlayView(frame: screen.frame)
            ciView.config = config
            ciView.captureAndBlur()
            ciView.startBreathing()
            ciView.autoresizingMask = [.width, .height]
            containerView.addSubview(ciView)
            coreImageViews.append(ciView)
        }

        // Only show HUD on primary screen
        if isPrimary {
            let hudView = SightBreakHUDView(duration: duration) { [weak self] in
                self?.hide()
                NotificationCenter.default.post(
                    name: NSNotification.Name("SightSkipBreak"), object: nil)
            }

            let hostingView = NSHostingView(rootView: hudView)
            hostingView.frame = screen.frame
            hostingView.autoresizingMask = [.width, .height]
            containerView.addSubview(hostingView)
        }

        window.contentView = containerView
        window.makeKeyAndOrderFront(nil)
        overlayWindows.append(window)
    }
}
