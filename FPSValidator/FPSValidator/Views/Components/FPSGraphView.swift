import SwiftUI

struct FPSGraphView: View {
    let frames: [FPSFrame]
    let targetFPS: Double
    let displayCount: Int
    
    var displayedFrames: [FPSFrame] {
        let start = max(0, frames.count - displayCount)
        return Array(frames[start...])
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FPS Timeline")
                .font(.headline)
                .foregroundColor(.white)
            
            if displayedFrames.isEmpty {
                Text("No data")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 100)
            } else {
                GeometryReader { geometry in
                    ZStack {
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let maxY = max(targetFPS * 1.5, 1)
                            
                            let points = displayedFrames.enumerated().map { index, frame -> CGPoint in
                                let x = CGFloat(index) / CGFloat(max(displayedFrames.count - 1, 1)) * width
                                let y = height - CGFloat(frame.actualFPS / maxY) * height
                                return CGPoint(x: x, y: min(max(y, 0), height))
                            }
                            
                            if let first = points.first {
                                path.move(to: first)
                                for point in points.dropFirst() {
                                    path.addLine(to: point)
                                }
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                        
                        Path { path in
                            let width = geometry.size.width
                            let height = geometry.size.height
                            let maxY = max(targetFPS * 1.5, 1)
                            let y = height - CGFloat(targetFPS / maxY) * height
                            
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        
                        VStack {
                            HStack {
                                Text(String(format: "%.0f", targetFPS * 1.5))
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            Spacer()
                            HStack {
                                Text("0")
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct FPSGraphSimpleView: View {
    let frames: [FPSFrame]
    let targetFPS: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let maxY = max(targetFPS * 1.5, 1)
                    
                    guard !frames.isEmpty else { return }
                    
                    let points = frames.enumerated().map { index, frame -> CGPoint in
                        let x = CGFloat(index) / CGFloat(max(frames.count - 1, 1)) * width
                        let y = height - CGFloat(frame.actualFPS / maxY) * height
                        return CGPoint(x: x, y: min(max(y, 0), height))
                    }
                    
                    if let first = points.first {
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let maxY = max(targetFPS * 1.5, 1)
                    let y = height - CGFloat(targetFPS / maxY) * height
                    
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(Color.green.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
        }
        .frame(height: 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FPSGraphView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFrames = (0..<100).map { i in
            FPSFrame(
                frameIndex: i,
                timestamp: Double(i) / 60.0,
                targetFPS: 60.0,
                actualFPS: 58.0 + Double.random(in: -2...2),
                frameTime: 16.67,
                isDropped: false
            )
        }
        
        FPSGraphView(frames: sampleFrames, targetFPS: 60, displayCount: 100)
            .padding()
            .background(Color.black)
    }
}