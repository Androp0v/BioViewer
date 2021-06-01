//
//  BasicRenderer.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import Foundation
import MetalKit

class BasicRenderer: NSObject {

    // Metal variables
    var device: MTLDevice
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!

    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!

    // Render runtime variables
    var frame: Int = 0

    // If provided, this will be called at the end of every frame, and should return a drawable that will be presented.
    var getCurrentDrawable: (() -> CAMetalDrawable?)?

    // Example vertex data (icosahedron)
    var vertexData: [Float] = [
        -0.5,  (1 + sqrt(5)) / 4, 0,
        0.5,  (1 + sqrt(5)) / 4, 0,
        -0.5, -(1 + sqrt(5)) / 4, 0,
        0.5, -(1 + sqrt(5)) / 4, 0,

        0, -0.5, (1 + sqrt(5)) / 4,
        0,  0.5, (1 + sqrt(5)) / 4,
        0, -0.5, -(1 + sqrt(5)) / 4,
        0,  0.5, -(1 + sqrt(5)) / 4,

        (1 + sqrt(5)) / 4, 0, -0.5,
        (1 + sqrt(5)) / 4, 0,  0.5,
        -(1 + sqrt(5)) / 4, 0, -0.5,
        -(1 + sqrt(5)) / 4, 0,  0.5,
    ]

    // Example index data (icosahedron)
    let indexData: [UInt32] = [0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1]

    // MARK: - Initialization

    init(device: MTLDevice) {

        self.device = device

        // Initialize buffers
        let dataSizeVertices = vertexData.count * MemoryLayout<Float>.size*3
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: dataSizeVertices,
                                         options: [])

        let dataSizeIndices = indexData.count * MemoryLayout<UInt32>.stride
        indexBuffer = device.makeBuffer(bytes: indexData,
                                        length: dataSizeIndices,
                                        options: [])

        var rotationMatrix = Transform.rotationMatrix(radians: Float.pi, axis: simd_float3(0.0, 1.0, 0.0))
        uniformBuffer = device.makeBuffer(bytes: &rotationMatrix,
                                          length: MemoryLayout<simd_float4x4>.stride,
                                          options: [])

        // Setup pipeline
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

        // Setup command queue
        commandQueue = device.makeCommandQueue()
    }
}

// MARK: - Drawing
extension BasicRenderer: MTKViewDelegate {

    /// This will be called when the ProteinMetalView changes size
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TO-DO: Update G-Buffer texture size to match view size
    }

    // This is called periodically to render the scene contents on display
    func draw(in view: MTKView) {

        // Retrieve current view drawable
        guard let drawable = view.currentDrawable else { return }

        // Update uniforms buffer
        withUnsafePointer(to: Transform.rotationMatrix(radians: 0.005 * Float(frame), axis: simd_float3(0,1,0))) {
            self.uniformBuffer.contents().copyMemory(from: $0, byteCount: MemoryLayout<simd_float4x4>.stride)
        }

        // Create render pass descriptor
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0,
                                                                            green: 0.0,
                                                                            blue: 0.0,
                                                                            alpha: 1.0)

        // Create command buffer
        let commandBuffer = commandQueue.makeCommandBuffer()!

        // Create render command encoder
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)

        // Add buffers to pipeline
        renderEncoder.setVertexBuffer(vertexBuffer,
                                      offset: 0,
                                      index: 0)
        renderEncoder.setVertexBuffer(uniformBuffer,
                                      offset: 0,
                                      index: 1)

        // Don't render back-facing triangles (cull them)
        renderEncoder.setCullMode(.back)

        // Draw primitives
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: indexData.count,
                                            indexType: .uint32,
                                            indexBuffer: indexBuffer,
                                            indexBufferOffset: 0)
        renderEncoder.endEncoding()

        // Commit command buffer
        commandBuffer.present(drawable)
        commandBuffer.commit()

        // Update frame number
        frame += 1
    }


}
