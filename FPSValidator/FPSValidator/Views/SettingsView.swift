import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: FPSGeneratorViewModel
    @State private var movingAverageFrames: Double = 60
    @State private var frameDropThreshold: Double = 2.0
    @State private var graphDisplayFrames: Double = 300
    @State private var flashEnabled: Bool = true
    @State private var showDeviceInfo: Bool = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Measurement Settings")) {
                    VStack(alignment: .leading) {
                        Text("Moving Average Frames: \(Int(movingAverageFrames))")
                        Slider(value: $movingAverageFrames, in: 10...200, step: 10)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Frame Drop Threshold: \(String(format: "%.1f", frameDropThreshold)) ms")
                        Slider(value: $frameDropThreshold, in: 0.5...10, step: 0.5)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Graph Display Frames: \(Int(graphDisplayFrames))")
                        Slider(value: $graphDisplayFrames, in: 50...600, step: 50)
                    }
                }
                
                Section(header: Text("Display Settings")) {
                    Toggle("Flash Effect", isOn: $flashEnabled)
                    Toggle("Show Device Info", isOn: $showDeviceInfo)
                }
                
                Section(header: Text("Device Information")) {
                    if showDeviceInfo {
                        DeviceInfoView()
                    }
                }
                
                Section {
                    Button("Apply Settings") {
                        applySettings()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.green)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private func loadSettings() {
        movingAverageFrames = Double(viewModel.settings.movingAverageFrames)
        frameDropThreshold = viewModel.settings.frameDropThreshold
        graphDisplayFrames = Double(viewModel.settings.graphDisplayFrames)
        flashEnabled = viewModel.settings.flashEnabled
        showDeviceInfo = viewModel.settings.showDeviceInfo
    }
    
    private func applySettings() {
        let newSettings = AppSettings(
            movingAverageFrames: Int(movingAverageFrames),
            frameDropThreshold: frameDropThreshold,
            graphDisplayFrames: Int(graphDisplayFrames),
            flashEnabled: flashEnabled,
            showDeviceInfo: showDeviceInfo
        )
        viewModel.updateSettings(newSettings)
        dismiss()
    }
}

struct DeviceInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Device:")
                    .foregroundColor(.gray)
                Spacer()
                Text(UIDevice.current.name)
            }
            
            HStack {
                Text("Model:")
                    .foregroundColor(.gray)
                Spacer()
                Text(UIDevice.current.model)
            }
            
            HStack {
                Text("System Version:")
                    .foregroundColor(.gray)
                Spacer()
                Text(UIDevice.current.systemVersion)
            }
            
            HStack {
                Text("Max Refresh Rate:")
                    .foregroundColor(.gray)
                Spacer()
                Text("\(Int(UIScreen.main.maximumFramesPerSecond)) Hz")
            }
            
            HStack {
                Text("Screen Scale:")
                    .foregroundColor(.gray)
                Spacer()
                Text("\(UIScreen.main.scale)x")
            }
        }
        .font(.subheadline)
    }
}