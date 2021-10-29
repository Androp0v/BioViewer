//
//  BasicRenderer.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import Foundation
import MetalKit
import SwiftUI

class ProteinRenderer: NSObject {
    
    // MARK: - Metal variables
    
    /// GPU
    var device: MTLDevice
    /// Pipeline state for the opaque geometry rendering
    var opaqueRenderingPipelineState: MTLRenderPipelineState!
    /// Pipeline state for the impostor geometry rendering (transparent at times)
    var impostorRenderingPipelineState: MTLRenderPipelineState!
    /// Depth state
    var depthState: MTLDepthStencilState!
    /// Command queue
    var commandQueue: MTLCommandQueue!
    
    // MARK: - Buffers
    
    /// Used to pass the geometry vertex data to the shader
    var vertexBuffer: MTLBuffer?
    /// Used to pass the atomic type data to the shader (used for coloring, size...)
    var atomTypeBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader
    var indexBuffer: MTLBuffer?
    /// Used to pass constant frame data to the shader
    var uniformBuffer: MTLBuffer?

    // MARK: - Runtime variables
    
    /// The scene contains the high-level information about the rendering of the scene (cameras, lighting...)
    var scene = MetalScene()
    
    // If provided, this will be called at the end of every frame, and should return a drawable that will be presented.
    var getCurrentDrawable: (() -> CAMetalDrawable?)?

    // MARK: - Descriptors
    
    let opaqueRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // colorAttachments[0] is the final drawable texture, set in draw()
        // colorAttachments[1] is the depth texture
        descriptor.colorAttachments[1].loadAction = .dontCare
        return descriptor
    }()
    
    let impostorRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        // Load the depth of the already populated opaque geometry pass
        descriptor.colorAttachments[1].loadAction = .load
        return descriptor
    }()
    
    let depthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()
    
    // MARK: - Pipelines
    
    private func makeOpaqueRenderPipelineState(device: MTLDevice) {
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

        opaqueRenderingPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    private func makeImpostorRenderPipelineState(device: MTLDevice) {
        // Setup pipeline
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "impostor_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "impostor_vertex")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float

        impostorRenderingPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    // MARK: - Initialization

    init(device: MTLDevice) {

        self.device = device

        uniformBuffer = device.makeBuffer(bytes: &self.scene.frameData,
                                          length: MemoryLayout<FrameData>.stride,
                                          options: [])

        // Setup command queue
        commandQueue = device.makeCommandQueue()
        
        super.init()
        
        // Create pipeline states
        makeOpaqueRenderPipelineState(device: device)
        makeImpostorRenderPipelineState(device: device)
        
        // Depth state
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }

    // MARK: - Public functions
    func addBuffers(vertexBuffer: inout MTLBuffer, atomTypeBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
        self.vertexBuffer = vertexBuffer
        self.atomTypeBuffer = atomTypeBuffer
        self.indexBuffer = indexBuffer
    }
}

// MARK: - Drawing
extension ProteinRenderer: MTKViewDelegate {

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
        
        // MARK: - Opaque geometry pass
        
        // Clear the depth texture (depth is in normalized device coordinates,
        // where 1.0 is the maximum/deepest value).
        view.clearDepth = 1.0

        // Attach textures. colorAttachments[0] is the final texture we draw onscreen
        opaqueRenderPassDescriptor.colorAttachments[0].texture = drawable.texture
        opaqueRenderPassDescriptor.colorAttachments[0].loadAction = .clear
        opaqueRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: scene.backgroundColor.components![0],
                                                                                  green: scene.backgroundColor.components![1],
                                                                                  blue: scene.backgroundColor.components![2],
                                                                                  alpha: scene.backgroundColor.components![3])
        opaqueRenderPassDescriptor.depthAttachment.texture = view.depthStencilTexture

        // Create command buffer
        let commandBuffer = commandQueue.makeCommandBuffer()!

        // Create render command encoder
        let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: opaqueRenderPassDescriptor)!

        // Set pipeline state
        renderCommandEncoder.setRenderPipelineState(opaqueRenderingPipelineState)

        // Set depth state
        renderCommandEncoder.setDepthStencilState(depthState)

        // Add buffers to pipeline
        renderCommandEncoder.setVertexBuffer(vertexBuffer,
                                             offset: 0,
                                             index: 0)
        renderCommandEncoder.setVertexBuffer(atomTypeBuffer,
                                             offset: 0,
                                             index: 1)
        renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                             offset: 0,
                                             index: 2)

        // Don't render back-facing triangles (cull them)
        renderCommandEncoder.setCullMode(.back)

        // Draw primitives
        renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                   indexCount: indexBuffer.length / MemoryLayout<UInt32>.stride,
                                                   indexType: .uint32,
                                                   indexBuffer: indexBuffer,
                                                   indexBufferOffset: 0)

        renderCommandEncoder.endEncoding()
        
        // MARK: - Transparent geometry pass
        // TO-DO: Impostor geometry
        
        // MARK: - Commit buffer
        // Commit command buffer
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }


}
