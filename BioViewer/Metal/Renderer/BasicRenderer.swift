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

    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer!

    // Render runtime variables
    var frame: Int = 0
    var camera: Camera

    // Descriptors
    let renderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // colorAttachments[0] is the final drawable texture, set in draw()
        // colorAttachments[1] is the depth texture
        // descriptor.colorAttachments[1].loadAction = .dontCare
        return descriptor
    }()
    let depthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()

    // If provided, this will be called at the end of every frame, and should return a drawable that will be presented.
    var getCurrentDrawable: (() -> CAMetalDrawable?)?

    // MARK: - Initialization

    init(device: MTLDevice) {

        self.device = device

        var rotationMatrix = Transform.rotationMatrix(radians: Float.pi, axis: simd_float3(0.0, 1.0, 0.0))
        uniformBuffer = device.makeBuffer(bytes: &rotationMatrix,
                                          length: 3 * MemoryLayout<simd_float4x4>.stride,
                                          options: [])

        // Setup pipeline
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

        // Setup command queue
        commandQueue = device.makeCommandQueue()

        // Setup camera
        self.camera = Camera.init(nearPlane: 0.1, farPlane: 3000, focalLength: 85)
    }

    // MARK: - Public functions
    func addBuffers(vertexBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
    }
}

// MARK: - Drawing
extension BasicRenderer: MTKViewDelegate {

    /// This will be called when the ProteinMetalView changes size
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TO-DO: Update G-Buffer texture size to match view size
        self.camera.updateProjection(drawableSize: size)

        // TO-DO: Enqueue draw calls so this doesn't drop the FPS
        view.draw()
    }

    // This is called periodically to render the scene contents on display
    func draw(in view: MTKView) {

        // Retrieve current view drawable
        guard let drawable = view.currentDrawable else { return }

        // Assure buffers are loaded
        guard let vertexBuffer = self.vertexBuffer else {
            return
        }
        guard let indexBuffer = self.indexBuffer else {
            return
        }

        // Update uniforms buffer
        // TO-DO: Address directly instead of copying data on each frame

        withUnsafePointer(to: Transform.translationMatrix(simd_float3(0,0,600))) {
            self.uniformBuffer.contents()
                .copyMemory(from: $0, byteCount: MemoryLayout<simd_float4x4>.stride)
        }

        withUnsafePointer(to: camera.projectionMatrix) {
            self.uniformBuffer.contents().advanced(by: MemoryLayout<simd_float4x4>.stride)
                .copyMemory(from: $0, byteCount: MemoryLayout<simd_float4x4>.stride)
        }

        withUnsafePointer(to: Transform.rotationMatrix(radians: -0.001 * Float(frame), axis: simd_float3(0,1,0))) {
            self.uniformBuffer.contents().advanced(by: 2 * MemoryLayout<simd_float4x4>.stride)
                .copyMemory(from: $0, byteCount: MemoryLayout<simd_float4x4>.stride)
        }

        // Clear the depth texture (depth is in normalized device coordinates,
        // where 1.0 is the maximum value).
        view.clearDepth = 1.0

        // Depth state
        let depthState = device.makeDepthStencilState(descriptor: depthDescriptor)

        // colorAttachments[0] is the final texture we draw onscreen
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0,
                                                                            green: 0.0,
                                                                            blue: 0.0,
                                                                            alpha: 1.0)
        renderPassDescriptor.depthAttachment.texture = view.depthStencilTexture

        // Create command buffer
        let commandBuffer = commandQueue.makeCommandBuffer()!

        // Create render command encoder
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        // Set pipeline state
        renderEncoder.setRenderPipelineState(pipelineState)

        // Set depth state
        renderEncoder.setDepthStencilState(depthState)

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
                                            indexCount: indexBuffer.length / MemoryLayout<UInt32>.stride,
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
