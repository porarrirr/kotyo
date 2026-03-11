import Foundation

struct FPSFrame {
    let frameIndex: Int
    let timestamp: Double
    let targetFPS: Double
    let actualFPS: Double
    let frameTime: Double
    let isDropped: Bool
}