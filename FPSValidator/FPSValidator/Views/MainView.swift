import SwiftUI
import MetalKit

struct MainView: View {
    @StateObject var viewModel: FPSGeneratorViewModel
    @State private var showValidation = false
    @State private var showSettings = false
    @State private var showExportSheet = false
    @State private var customFPS: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    MetalViewRepresentable(viewModel: viewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        FPSSummaryView(statistics: viewModel.statistics, targetFPS: viewModel.targetFPS)
                        
                        HStack(spacing: 12) {
                            ForEach(viewModel.presetFPSOptions, id: \.self) { fps in
                                FPSButton(
                                    title: "\(Int(fps))",
                                    isSelected: viewModel.targetFPS == fps
                                ) {
                                    viewModel.setTargetFPS(fps)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("Custom FPS", text: $customFPS)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .frame(width: 100)
                            
                            Button("Set") {
                                if let fps = Double(customFPS) {
                                    viewModel.setTargetFPS(fps)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        HStack(spacing: 20) {
                            Button(viewModel.isRunning ? "Stop" : "Start") {
                                if viewModel.isRunning {
                                    viewModel.stop()
                                } else {
                                    viewModel.start()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(viewModel.isRunning ? .red : .green)
                            
                            Button("Reset") {
                                viewModel.reset()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Export") {
                                showExportSheet = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                }
            }
            .navigationTitle("FPS Validator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Validation") { showValidation = true }
                        Button("Settings") { showSettings = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showValidation) {
                ValidationView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showExportSheet) {
                ExportView(csvContent: viewModel.exportCSV())
            }
        }
    }
}

struct MetalViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: FPSGeneratorViewModel
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = true
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
        
        viewModel.setMetalView(mtkView)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
    }
}

struct FPSSummaryView: View {
    let statistics: FPSStatistics
    let targetFPS: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 30) {
                VStack {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f", statistics.currentFPS))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack {
                    Text("Average")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f", statistics.averageFPS))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack {
                    Text("Min/Max")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", statistics.minFPS))/\(String(format: "%.1f", statistics.maxFPS))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            HStack(spacing: 30) {
                VStack {
                    Text("Frame Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f ms", statistics.frameTime))
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                
                VStack {
                    Text("Dropped")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(statistics.droppedFrames)")
                        .font(.subheadline)
                        .foregroundColor(statistics.droppedFrames > 0 ? .red : .green)
                }
                
                VStack {
                    Text("vs Target")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(String(format: "%+.1f", statistics.targetDiff))
                        .font(.subheadline)
                        .foregroundColor(abs(statistics.targetDiff) < 1.0 ? .green : .yellow)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct FPSButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.green : Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
    }
}

struct ExportView: View {
    let csvContent: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("CSV Export")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    Text(csvContent)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                }
                
                ShareLink(item: csvContent) {
                    Text("Share CSV")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Export")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}