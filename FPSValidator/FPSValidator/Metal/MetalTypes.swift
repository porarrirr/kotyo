import simd
import Metal

struct Vertex {
    var position: SIMD2<Float>
    var color: SIMD4<Float>
}

struct Uniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var frameIndex: Int32
    var isEvenFrame: Bool
}

struct BallData {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var radius: Float
    var color: SIMD4<Float>
}