import Foundation
import CoreGraphics
import AppKit

public func benchmarkFullscreenDetection() {
    print("Benchmarking Fullscreen Detection...")

    // Method 1: CGWindowListCopyWindowInfo (Baseline)
    let start1 = CFAbsoluteTimeGetCurrent()
    for _ in 0..<100 {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        _ = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    }
    let end1 = CFAbsoluteTimeGetCurrent()
    print("CGWindowListCopyWindowInfo (100x): \((end1 - start1) * 1000)ms")

    // Method 2: NSRunningApplication presentationOptions / NSWorkspace (Alternative)
    let app = NSWorkspace.shared.frontmostApplication
    let start2 = CFAbsoluteTimeGetCurrent()
    for _ in 0..<100 {
        _ = app?.presentationOptions
    }
    let end2 = CFAbsoluteTimeGetCurrent()
    print("frontmostApp.presentationOptions (100x): \((end2 - start2) * 1000)ms")
}
