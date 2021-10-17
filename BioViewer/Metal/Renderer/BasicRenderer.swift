//
//  BasicRenderer.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import Foundation
import MetalKit
import SwiftUI

class BasicRenderer: NSObject {

    // MARK: - Properties

    // Metal variables
    var device: MTLDevice
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!

    /// Used to pass the geometry vertex data to the shader
    var vertexBuffer: MTLBuffer?
    /// Used to pass the atomic type data to the shader (used for coloring, size...)
    var atomTypeBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader
    var indexBuffer: MTLBuffer?
    /// Used to pass constant frame data to the shader
    var uniformBuffer: MTLBuffer?

    // Render runtime variables
    var scene = MetalScene()

    // MARK: - Descriptors
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

        uniformBuffer = device.makeBuffer(bytes: &self.scene.frameData,
                                          length: MemoryLayout<FrameData>.stride,
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

    }

    // MARK: - Public functions
    func addBuffers(vertexBuffer: inout MTLBuffer, atomTypeBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
        self.vertexBuffer = vertexBuffer
        self.atomTypeBuffer = atomTypeBuffer
        self.indexBuffer = indexBuffer
    }
}

// MARK: - Drawing
extension BasicRenderer: MTKViewDelegate {

    /// This will be called when the ProteinMetalView changes size
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TO-DO: Update G-Buffer texture size to match view size
        self.scene.camera.updateProjection(drawableSize: size)

        // TO-DO: Enqueue draw calls so this doesn't drop the FPS
        view.draw()
    }

    // This is called periodically to render the scene contents on display
    func draw(in view: MTKView) {

        // Retrieve current view drawable
        guard let drawable = view.currentDrawable else { return }

        // Assure buffers are loaded
        guard let vertexBuffer = self.vertexBuffer else { return }
        guard let atomTypeBuffer = self.atomTypeBuffer else { return }
        guard let indexBuffer = self.indexBuffer else { return }
        guard let uniformBuffer = self.uniformBuffer else { return }

        // Update uniforms buffer
        // TO-DO: Address directly instead of copying data on each frame
        self.scene.update()

        withUnsafePointer(to: self.scene.frameData) {
            uniformBuffer.contents()
                .copyMemory(from: $0, byteCount: MemoryLayout<FrameData>.stride)
        }

        // Clear the depth texture (depth is in normalized device coordinates,
        // where 1.0 is the maximum/deepest value).
        view.clearDepth = 1.0

        // Depth state
        // TO-DO: This can be moved out of the render loop
        let depthState = device.makeDepthStencilState(descriptor: depthDescriptor)

        // Attach textures. colorAttachments[0] is the final texture we draw onscreen
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: scene.backgroundColor.components![0],
                                                                            green: scene.backgroundColor.components![1],
                                                                            blue: scene.backgroundColor.components![2],
                                                                            alpha: scene.backgroundColor.components![3])
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
        renderEncoder.setVertexBuffer(atomTypeBuffer,
                                      offset: 0,
                                      index: 1)
        renderEncoder.setVertexBuffer(uniformBuffer,
                                      offset: 0,
                                      index: 2)

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
    }


}
