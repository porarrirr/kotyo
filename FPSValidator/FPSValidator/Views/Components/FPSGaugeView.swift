import SwiftUI

struct FPSGaugeView: View {
    let value: Double
    let maxValue: Double
    let targetFPS: Double
    
    @State private var animatedValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                
                Circle()
                    .trim(from: 0, to: min(animatedValue / maxValue, 1.0))
                    .stroke(
                        colorForValue(animatedValue),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: animatedValue)
                
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", animatedValue))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text("FPS")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if targetFPS > 0 {
                        Text("Target: \(Int(targetFPS))")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(width: min(geometry.size.width, geometry.size.height))
        }
        .onAppear {
            animatedValue = value
        }
        .onChange(of: value) { newValue in
            animatedValue = newValue
        }
    }
    
    private func colorForValue(_ fps: Double) -> Color {
        let diff = abs(fps - targetFPS)
        if diff <= 2.0 {
            return .green
        } else if diff <= 5.0 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct FPSGaugeView_Previews: PreviewProvider {
    static var previews: some View {
        FPSGaugeView(value: 58.5, maxValue: 144, targetFPS: 60)
            .frame(width: 150, height: 150)
            .padding()
            .background(Color.black)
    }
}