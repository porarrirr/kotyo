import SwiftUI
import MetalKit

class FPSGeneratorViewModel: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var targetFPS: Double = 60.0
    @Published var statistics: FPSStatistics = FPSStatistics()
    @Published var settings: AppSettings = AppSettings()
    @Published var validationModel: ValidationModel = ValidationModel()
    @Published var frames: [FPSFrame] = []
    @Published var deviceMaxFPS: Int = 60
    
    private var engine: FPSEngine?
    private var metalView: MTKView?
    
    var presetFPSOptions: [Double] {
        let baseOptions: [Double] = [30, 60, 90, 120, 144]
        return baseOptions.filter { $0 <= Double(deviceMaxFPS) }
    }
    
    init() {
        self.engine = FPSEngine()
        self.deviceMaxFPS = engine?.deviceMaxFPS ?? 60
        engine?.delegate = self
    }
    
    func setMetalView(_ view: MTKView) {
        self.metalView = view
        engine?.configure(metalView: view, targetFPS: targetFPS, settings: settings)
    }
    
    func start() {
        guard let metalView = metalView else { return }
        engine?.configure(metalView: metalView, targetFPS: targetFPS, settings: settings)
        engine?.start()
        isRunning = true
    }
    
    func stop() {
        engine?.stop()
        isRunning = false
    }
    
    func reset() {
        engine?.reset()
        statistics = FPSStatistics()
        frames.removeAll()
        validationModel.reset()
    }
    
    func setTargetFPS(_ fps: Double) {
        targetFPS = min(fps, Double(deviceMaxFPS))
        if isRunning {
            engine?.updateTargetFPS(targetFPS)
        }
    }
    
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        if let metalView = metalView {
            engine?.configure(metalView: metalView, targetFPS: targetFPS, settings: settings)
        }
    }
    
    func addValidationComparison(windowsFPS: Double) -> ValidationResult {
        return validationModel.addComparison(iOSFPS: statistics.currentFPS, windowsFPS: windowsFPS)
    }
    
    func exportCSV() -> String {
        return engine?.exportCSV() ?? ""
    }
    
    func updateFrames(count: Int) {
        frames = engine?.getRecentFrames(count: count) ?? []
    }
}

extension FPSGeneratorViewModel: FPSEngineDelegate {
    func engineDidUpdateFrame(_ frame: FPSFrame, statistics: FPSStatistics) {
        DispatchQueue.main.async { [weak self] in
            self?.statistics = statistics
            self?.frames.append(frame)
            if let maxFrames = self?.settings.graphDisplayFrames,
               self?.frames.count ?? 0 > maxFrames {
                self?.frames.removeFirst()
            }
        }
    }
}