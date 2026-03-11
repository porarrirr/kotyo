import Foundation

struct FPSStatistics {
    var currentFPS: Double = 0.0
    var averageFPS: Double = 0.0
    var minFPS: Double = Double.infinity
    var maxFPS: Double = 0.0
    var frameTime: Double = 0.0
    var droppedFrames: Int = 0
    var targetDiff: Double = 0.0
}