import Metal
import MetalKit
import simd

class Renderer: NSObject, MTKViewDelegate {
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private var pipelineState: MTLRenderPipelineState
    private var vertexBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    
    private var frameIndex: Int = 0
    private var time: Float = 0.0
    private var isEvenFrame: Bool = false
    private var flashEnabled: Bool = true
    
    private var ballPosition: SIMD2<Float> = [0.0, 0.0]
    private var ballVelocity: SIMD2<Float> = [0.02, 0.015]
    private var ballRadius: Float = 0.08
    private var ballColor: SIMD4<Float> = [1.0, 0.3, 0.3, 1.0]
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertex_main"),
              let fragmentFunction = library.makeFunction(name: "fragment_main") else {
            return nil
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }
        
        super.init()
        
        metalView.device = device
        metalView.sampleCount = 1
        metalView.isPaused = false
        metalView.enableSetNeedsDisplay = false
    }
    
    func setFlashEnabled(_ enabled: Bool) {
        self.flashEnabled = enabled
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        frameIndex += 1
        time += 1.0 / 60.0
        isEvenFrame = frameIndex % 2 == 0
        
        let width = Float(view.drawableSize.width)
        let height = Float(view.drawableSize.height)
        let aspectRatio = width / height
        
        updateBall(aspectRatio: aspectRatio)
        
        let vertices = createVertices(aspectRatio: aspectRatio)
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        if let vertexBuffer = vertexBuffer {
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func updateBall(aspectRatio: Float) {
        ballPosition.x += ballVelocity.x
        ballPosition.y += ballVelocity.y
        
        let maxX: Float = 0.9
        let maxY: Float = 0.9
        
        if ballPosition.x > maxX || ballPosition.x < -maxX {
            ballVelocity.x *= -1
            ballPosition.x = max(-maxX, min(maxX, ballPosition.x))
            changeBallColor()
        }
        
        if ballPosition.y > maxY || ballPosition.y < -maxY {
            ballVelocity.y *= -1
            ballPosition.y = max(-maxY, min(maxY, ballPosition.y))
            changeBallColor()
        }
        
        ballVelocity.x = ballVelocity.x > 0 ? 
            min(ballVelocity.x * 1.0001, 0.05) : max(ballVelocity.x * 1.0001, -0.05)
        ballVelocity.y = ballVelocity.y > 0 ?
            min(ballVelocity.y * 1.0001, 0.05) : max(ballVelocity.y * 1.0001, -0.05)
    }
    
    private func changeBallColor() {
        let hue = Float.random(in: 0...1)
        let saturation: Float = 0.8
        let brightness: Float = 0.9
        
        let c = brightness * saturation
        let x = c * (1 - abs((hue * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        
        var r: Float = 0, g: Float = 0, b: Float = 0
        
        switch Int(hue * 6) {
        case 0: r = c; g = x; b = 0
        case 1: r = x; g = c; b = 0
        case 2: r = 0; g = c; b = x
        case 3: r = 0; g = x; b = c
        case 4: r = x; g = 0; b = c
        default: r = c; g = 0; b = x
        }
        
        ballColor = [r + m, g + m, b + m, 1.0]
    }
    
    private func createVertices(aspectRatio: Float) -> [Vertex] {
        var vertices: [Vertex] = []
        
        if flashEnabled {
            let flashColor: SIMD4<Float> = isEvenFrame ? [1.0, 1.0, 1.0, 0.3] : [0.0, 0.0, 0.0, 0.3]
            vertices.append(contentsOf: createQuadVertices(x: 0, y: 0, width: 2.0, height: 2.0, color: flashColor))
        }
        
        let ballVertices = createCircleVertices(
            x: ballPosition.x,
            y: ballPosition.y,
            radius: ballRadius / aspectRatio,
            color: ballColor,
            segments: 32
        )
        vertices.append(contentsOf: ballVertices)
        
        let timestampX = -0.95 + (Float(frameIndex % 100) / 100.0) * 0.1
        let timestampColor: SIMD4<Float> = [0.0, 1.0, 0.5, 1.0]
        vertices.append(contentsOf: createQuadVertices(
            x: timestampX,
            y: 0.85,
            width: 0.005,
            height: 0.03,
            color: timestampColor
        ))
        
        let frameNum = frameIndex % 10000
        let digits = [
            createDigitVertices(digit: (frameNum / 1000) % 10, x: -0.5, y: 0, scale: 0.08, color: SIMD4<Float>([1.0, 1.0, 1.0, 1.0])),
            createDigitVertices(digit: (frameNum / 100) % 10, x: -0.35, y: 0, scale: 0.08, color: SIMD4<Float>([1.0, 1.0, 1.0, 1.0])),
            createDigitVertices(digit: (frameNum / 10) % 10, x: -0.2, y: 0, scale: 0.08, color: SIMD4<Float>([1.0, 1.0, 1.0, 1.0])),
            createDigitVertices(digit: frameNum % 10, x: -0.05, y: 0, scale: 0.08, color: SIMD4<Float>([1.0, 1.0, 1.0, 1.0]))
        ]
        for digit in digits {
            vertices.append(contentsOf: digit)
        }
        
        return vertices
    }
    
    private func createQuadVertices(x: Float, y: Float, width: Float, height: Float, color: SIMD4<Float>) -> [Vertex] {
        let halfW = width / 2
        let halfH = height / 2
        
        return [
            Vertex(position: [x - halfW, y - halfH], color: color),
            Vertex(position: [x + halfW, y - halfH], color: color),
            Vertex(position: [x - halfW, y + halfH], color: color),
            Vertex(position: [x + halfW, y - halfH], color: color),
            Vertex(position: [x + halfW, y + halfH], color: color),
            Vertex(position: [x - halfW, y + halfH], color: color)
        ]
    }
    
    private func createCircleVertices(x: Float, y: Float, radius: Float, color: SIMD4<Float>, segments: Int) -> [Vertex] {
        var vertices: [Vertex] = []
        
        for i in 0..<segments {
            let angle1 = Float(i) * 2.0 * Float.pi / Float(segments)
            let angle2 = Float(i + 1) * 2.0 * Float.pi / Float(segments)
            
            let x1 = x + radius * cos(angle1)
            let y1 = y + radius * sin(angle1)
            let x2 = x + radius * cos(angle2)
            let y2 = y + radius * sin(angle2)
            
            vertices.append(Vertex(position: [x, y], color: color))
            vertices.append(Vertex(position: [x1, y1], color: color))
            vertices.append(Vertex(position: [x2, y2], color: color))
        }
        
        return vertices
    }
    
    private let digitSegments: [[Float]] = [
        [1,1,1,1,1,1,0],
        [0,1,1,0,0,0,0],
        [1,1,0,1,1,0,1],
        [1,1,1,1,0,0,1],
        [0,1,1,0,0,1,1],
        [1,0,1,1,0,1,1],
        [1,0,1,1,1,1,1],
        [1,1,1,0,0,0,0],
        [1,1,1,1,1,1,1],
        [1,1,1,1,0,1,1]
    ]
    
    private func createDigitVertices(digit: Int, x: Float, y: Float, scale: Float, color: SIMD4<Float>) -> [Vertex] {
        var vertices: [Vertex] = []
        let segments = digitSegments[digit]
        
        let positions: [(Float, Float, Float, Float)] = [
            (x - scale/2, y + scale, scale, scale/8),
            (x + scale/2, y + scale, scale, scale/8),
            (x + scale, y + scale/2, scale/8, scale),
            (x + scale, y - scale/2, scale/8, scale),
            (x - scale/2, y - scale, scale, scale/8),
            (x + scale/2, y - scale, scale, scale/8),
            (x - scale, y - scale/2, scale/8, scale)
        ]
        
        for (index, isOn) in segments.enumerated() {
            if isOn == 1 {
                let (px, py, w, h) = positions[index]
                vertices.append(contentsOf: createQuadVertices(x: px, y: py, width: w, height: h, color: color))
            }
        }
        
        return vertices
    }
    
    func reset() {
        frameIndex = 0
        time = 0.0
        isEvenFrame = false
        ballPosition = [0.0, 0.0]
        ballVelocity = [0.02, 0.015]
        ballColor = [1.0, 0.3, 0.3, 1.0]
    }
}