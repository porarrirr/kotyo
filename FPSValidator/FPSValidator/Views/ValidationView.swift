import SwiftUI

struct ValidationView: View {
    @ObservedObject var viewModel: FPSGeneratorViewModel
    @State private var windowsFPSInput: String = ""
    @State private var latestResult: ValidationResult?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text("Current iOS FPS")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.2f", viewModel.statistics.currentFPS))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    
                    VStack(spacing: 12) {
                        Text("Windows Measured FPS")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        TextField("Enter Windows FPS value", text: $windowsFPSInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                        
                        Button("Compare") {
                            if let windowsFPS = Double(windowsFPSInput) {
                                latestResult = viewModel.addValidationComparison(windowsFPS: windowsFPS)
                                windowsFPSInput = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(windowsFPSInput.isEmpty)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    
                    if let result = latestResult {
                        ResultView(result: result)
                    }
                    
                    if !viewModel.validationModel.validationResults.isEmpty {
                        StatisticsView(validationModel: viewModel.validationModel)
                        
                        HistoryView(results: viewModel.validationModel.validationResults.suffix(10))
                    }
                }
                .padding()
            }
            .navigationTitle("Validation")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        viewModel.validationModel.reset()
                        latestResult = nil
                    }
                }
            }
        }
    }
}

struct ResultView: View {
    let result: ValidationResult
    
    var body: some View {
        VStack(spacing: 16) {
            Text(result.status.symbol)
                .font(.system(size: 60))
            
            Text(result.status.rawValue)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(statusColor)
            
            VStack(spacing: 8) {
                HStack {
                    Text("iOS FPS:")
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", result.iOSFPS))
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Windows FPS:")
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", result.windowsFPS))
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Difference:")
                        .foregroundColor(.gray)
                    Text(String(format: "%+.2f fps", result.diff))
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor, lineWidth: 2)
        )
    }
    
    var statusColor: Color {
        switch result.status {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }
}

struct StatisticsView: View {
    @ObservedObject var validationModel: ValidationModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Avg Error")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", validationModel.averageError))
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("Max Error")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", validationModel.maxError))
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("Std Dev")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f", validationModel.standardDeviation))
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct HistoryView: View {
    let results: ArraySlice<ValidationResult>
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Recent History")
                .font(.headline)
            
            ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                HStack {
                    Text(result.status.symbol)
                        .font(.title3)
                    
                    VStack(alignment: .leading) {
                        Text("iOS: \(String(format: "%.1f", result.iOSFPS)) | Win: \(String(format: "%.1f", result.windowsFPS))")
                            .font(.caption)
                        Text("Diff: \(String(format: "%+.1f", result.diff)) fps")
                            .font(.caption2)
                            .foregroundColor(statusColor(for: result.status))
                    }
                    
                    Spacer()
                    
                    Text(result.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    func statusColor(for status: JudgeStatus) -> Color {
        switch status {
        case .pass: return .green
        case .warning: return .yellow
        case .fail: return .red
        }
    }
}