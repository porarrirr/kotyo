import UIKit
import MetalKit

protocol FPSEngineDelegate: AnyObject {
    func engineDidUpdateFrame(_ frame: FPSFrame, statistics: FPSStatistics)
}

class FPSEngine {
    weak var delegate: FPSEngineDelegate?
    
    private var displayLink: CADisplayLink?
    private var measurer: FPSMeasurer
    private var renderer: Renderer?
    private var metalView: MTKView?
    private var targetFPS: Double = 60.0
    private(set) var isRunning: Bool = false
    
    let deviceMaxFPS: Int
    
    init() {
        self.measurer = FPSMeasurer()
        self.deviceMaxFPS = Int(UIScreen.main.maximumFramesPerSecond)
    }
    
    func configure(metalView: MTKView, targetFPS: Double, settings: AppSettings) {
        self.metalView = metalView
        self.targetFPS = targetFPS
        
        metalView.preferredFramesPerSecond = Int(targetFPS)
        
        if let renderer = Renderer(metalView: metalView) {
            self.renderer = renderer
            renderer.setFlashEnabled(settings.flashEnabled)
        }
        
        measurer.configure(
            targetFPS: targetFPS,
            movingAverageFrames: settings.movingAverageFrames,
            frameDropThreshold: settings.frameDropThreshold
        )
    }
    
    func updateTargetFPS(_ fps: Double) {
        self.targetFPS = fps
        metalView?.preferredFramesPerSecond = Int(fps)
        measurer.configure(
            targetFPS: fps,
            movingAverageFrames: 60,
            frameDropThreshold: 2.0
        )
    }
    
    func start() {
        guard !isRunning else { return }
        
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        
        if #available(iOS 15.0, *) {
            let fps = Float(targetFPS)
            displayLink?.preferredFrameRateRange = CAFrameRateRange(
                minimum: fps,
                maximum: fps,
                preferred: fps
            )
        } else {
            displayLink?.preferredFramesPerSecond = Int(targetFPS)
        }
        
        displayLink?.add(to: .main, forMode: .common)
        isRunning = true
    }
    
    func stop() {
        guard isRunning else { return }
        
        displayLink?.invalidate()
        displayLink = nil
        isRunning = false
    }
    
    func reset() {
        stop()
        measurer.reset()
        renderer?.reset()
    }
    
    @objc private func handleDisplayLink(_ displayLink: CADisplayLink) {
        let timestamp = displayLink.timestamp
        
        let frame = measurer.addFrame(timestamp: timestamp)
        let statistics = measurer.getStatistics()
        
        delegate?.engineDidUpdateFrame(frame, statistics: statistics)
    }
    
    func getStatistics() -> FPSStatistics {
        return measurer.getStatistics()
    }
    
    func exportCSV() -> String {
        return measurer.exportToCSV()
    }
    
    func getRecentFrames(count: Int) -> [FPSFrame] {
        return measurer.getRecentFrames(count: count)
    }
}