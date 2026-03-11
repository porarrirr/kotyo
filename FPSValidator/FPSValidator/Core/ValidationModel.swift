import Foundation

class ValidationModel: ObservableObject {
    @Published var validationResults: [ValidationResult] = []
    @Published var averageError: Double = 0.0
    @Published var maxError: Double = 0.0
    @Published var standardDeviation: Double = 0.0
    
    private let maxResults: Int = 1000
    
    func addComparison(iOSFPS: Double, windowsFPS: Double) -> ValidationResult {
        let result = ValidationResult(iOSFPS: iOSFPS, windowsFPS: windowsFPS)
        validationResults.append(result)
        
        if validationResults.count > maxResults {
            validationResults.removeFirst()
        }
        
        updateStatistics()
        return result
    }
    
    private func updateStatistics() {
        guard !validationResults.isEmpty else {
            averageError = 0.0
            maxError = 0.0
            standardDeviation = 0.0
            return
        }
        
        let errors = validationResults.map { abs($0.diff) }
        averageError = errors.reduce(0, +) / Double(errors.count)
        maxError = errors.max() ?? 0.0
        
        let variance = errors.reduce(0) { $0 + pow($1 - averageError, 2) } / Double(errors.count)
        standardDeviation = sqrt(variance)
    }
    
    func generateReport() -> String {
        var report = "=== FPS Validation Report ===\n"
        report += "Generated: \(Date())\n\n"
        report += "Statistics:\n"
        report += "- Total Comparisons: \(validationResults.count)\n"
        report += "- Average Error: \(String(format: "%.2f", averageError)) fps\n"
        report += "- Max Error: \(String(format: "%.2f", maxError)) fps\n"
        report += "- Standard Deviation: \(String(format: "%.2f", standardDeviation)) fps\n\n"
        
        let passCount = validationResults.filter { $0.status == .pass }.count
        let warningCount = validationResults.filter { $0.status == .warning }.count
        let failCount = validationResults.filter { $0.status == .fail }.count
        
        report += "Results:\n"
        report += "- PASS: \(passCount)\n"
        report += "- WARNING: \(warningCount)\n"
        report += "- FAIL: \(failCount)\n"
        
        return report
    }
    
    func reset() {
        validationResults.removeAll()
        averageError = 0.0
        maxError = 0.0
        standardDeviation = 0.0
    }
}