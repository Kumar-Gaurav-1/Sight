import Foundation
import SwiftUI

// Mock basic Color object to avoid bringing in AppKit/SwiftUI view layers
struct MockColor {
    let hue: Double
    let saturation: Double
    let brightness: Double
}

func testDynamic() {
    for _ in 0..<100000 {
        let colors = (0..<12).map {
            MockColor(hue: Double($0) / 12.0, saturation: 0.7, brightness: 0.8)
        }
        _ = colors
    }
}

let cachedColors = (0..<12).map {
    MockColor(hue: Double($0) / 12.0, saturation: 0.7, brightness: 0.8)
}

func testStatic() {
    for _ in 0..<100000 {
        let colors = cachedColors
        _ = colors
    }
}

let startDynamic = CFAbsoluteTimeGetCurrent()
testDynamic()
let endDynamic = CFAbsoluteTimeGetCurrent()
print("Dynamic array creation time: \((endDynamic - startDynamic) * 1000) ms")

let startStatic = CFAbsoluteTimeGetCurrent()
testStatic()
let endStatic = CFAbsoluteTimeGetCurrent()
print("Static array creation time: \((endStatic - startStatic) * 1000) ms")
