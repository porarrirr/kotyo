import Foundation

class FPSMeasurer {
    private var timestamps: [Double] = []
    private var frameIndex: Int = 0
    private var totalFrames: Int = 0
    private var droppedCount: Int = 0
    private var targetFPS: Double = 60.0
    private var frameDropThreshold: Double = 2.0
    private var movingAverageFrames: Int = 60
    
    private var minFPS: Double = Double.infinity
    private var maxFPS: Double = 0.0
    private var totalFPS: Double = 0.0
    private var fpsCount: Int = 0
    
    private let maxStoredFrames: Int = 36000
    
    private(set) var frames: [FPSFrame] = []
    
    func configure(targetFPS: Double, movingAverageFrames: Int, frameDropThreshold: Double) {
        self.targetFPS = targetFPS
        self.movingAverageFrames = movingAverageFrames
        self.frameDropThreshold = frameDropThreshold
    }
    
    func addFrame(timestamp: Double) -> FPSFrame {
        timestamps.append(timestamp)
        if timestamps.count > movingAverageFrames {
            timestamps.removeFirst()
        }
        
        let actualFPS = calculateActualFPS()
        let frameTime = timestamps.count >= 2 ? 
            (timestamps[timestamps.count - 1] - timestamps[timestamps.count - 2]) * 1000.0 : 0.0
        
        let expectedFrameTime = 1000.0 / targetFPS
        let isDropped = frameTime > (expectedFrameTime + frameDropThreshold)
        
        if isDropped {
            droppedCount += 1
        }
        
        if actualFPS > 0 && !actualFPS.isNaN && !actualFPS.isInfinite {
            if actualFPS < minFPS { minFPS = actualFPS }
            if actualFPS > maxFPS { maxFPS = actualFPS }
            totalFPS += actualFPS
            fpsCount += 1
        }
        
        let frame = FPSFrame(
            frameIndex: frameIndex,
            timestamp: timestamp,
            targetFPS: targetFPS,
            actualFPS: actualFPS,
            frameTime: frameTime,
            isDropped: isDropped
        )
        
        frames.append(frame)
        if frames.count > maxStoredFrames {
            frames.removeFirst()
        }
        
        frameIndex += 1
        totalFrames += 1
        
        return frame
    }
    
    private func calculateActualFPS() -> Double {
        guard timestamps.count >= 2 else { return 0.0 }
        
        let timeDiff = timestamps.last! - timestamps.first!
        guard timeDiff > 0 else { return 0.0 }
        
        let fps = Double(timestamps.count - 1) / timeDiff
        return fps
    }
    
    func getStatistics() -> FPSStatistics {
        let avgFPS = fpsCount > 0 ? totalFPS / Double(fpsCount) : 0.0
        let currentFPS = calculateActualFPS()
        let frameTime = timestamps.count >= 2 ?
            (timestamps[timestamps.count - 1] - timestamps[timestamps.count - 2]) * 1000.0 : 0.0
        
        return FPSStatistics(
            currentFPS: currentFPS,
            averageFPS: avgFPS,
            minFPS: minFPS == Double.infinity ? 0.0 : minFPS,
            maxFPS: maxFPS,
            frameTime: frameTime,
            droppedFrames: droppedCount,
            targetDiff: currentFPS - targetFPS
        )
    }
    
    func reset() {
        timestamps.removeAll()
        frameIndex = 0
        totalFrames = 0
        droppedCount = 0
        minFPS = Double.infinity
        maxFPS = 0.0
        totalFPS = 0.0
        fpsCount = 0
        frames.removeAll()
    }
    
    func exportToCSV() -> String {
        var csv = "FrameIndex,Timestamp,TargetFPS,ActualFPS,FrameTime(ms),IsDropped\n"
        for frame in frames {
            csv += "\(frame.frameIndex),\(frame.timestamp),\(frame.targetFPS),\(String(format: "%.2f", frame.actualFPS)),\(String(format: "%.3f", frame.frameTime)),\(frame.isDropped)\n"
        }
        return csv
    }
    
    func getRecentFrames(count: Int) -> [FPSFrame] {
        let start = max(0, frames.count - count)
        return Array(frames[start...])
    }
}