import Foundation

enum JudgeStatus: String {
    case pass = "PASS"
    case warning = "WARNING"
    case fail = "FAIL"
    
    var symbol: String {
        switch self {
        case .pass: return "✅"
        case .warning: return "⚠️"
        case .fail: return "❌"
        }
    }
}

struct ValidationResult {
    let iOSFPS: Double
    let windowsFPS: Double
    let diff: Double
    let status: JudgeStatus
    let timestamp: Date
    
    init(iOSFPS: Double, windowsFPS: Double) {
        self.iOSFPS = iOSFPS
        self.windowsFPS = windowsFPS
        self.diff = iOSFPS - windowsFPS
        self.timestamp = Date()
        
        let absDiff = abs(self.diff)
        if absDiff <= 2.0 {
            self.status = .pass
        } else if absDiff <= 5.0 {
            self.status = .warning
        } else {
            self.status = .fail
        }
    }
}