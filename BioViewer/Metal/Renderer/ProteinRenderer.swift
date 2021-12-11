//
//  BasicRenderer.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 30/5/21.
//

import Foundation
import MetalKit
import SwiftUI

class ProteinRenderer: NSObject, ObservableObject {
    
    // MARK: - Constants
    
    let maxBuffersInFlight = 3
    
    // MARK: - Metal variables
    
    /// GPU
    var device: MTLDevice
    /// Pipeline state for the directional shadow creation
    var shadowRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the opaque geometry rendering
    var opaqueRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times)
    var impostorRenderingPipelineState: MTLRenderPipelineState?
    /// Shadow depth state
    var shadowDepthState: MTLDepthStencilState?
    /// Depth state
    var depthState: MTLDepthStencilState?
    /// Command queue
    var commandQueue: MTLCommandQueue?
    /// Used to signal that a new frame is ready to be computed by the CPU
    var frameBoundarySemaphore: DispatchSemaphore
    /// Used to index the dynamic buffers
    var currentFrameIndex: Int
    
    // MARK: - Buffers
    
    /// Used to pass the geometry vertex data to the shader when using a dense mesh
    var opaqueVertexBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader when using a dense mesh
    var opaqueIndexBuffer: MTLBuffer?
    /// Used to pass the geometry vertex data to the shader when using billboarding
    var impostorVertexBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader  when using billboarding
    var impostorIndexBuffer: MTLBuffer?
    /// Used to pass the subunit index to the shader (used for coloring)
    var subunitBuffer: MTLBuffer?
    /// Used to pass the atomic type data to the shader (used for coloring, size...)
    var atomTypeBuffer: MTLBuffer?
    /// Used to pass constant frame data to the shader
    var uniformBuffers: [MTLBuffer]?
    
    // MARK: - Textures
    var shadowTextures = ShadowTextures()

    // MARK: - Runtime variables
    
    /// The scene contains the high-level information about the rendering of the scene (cameras, lighting...)
    var scene = MetalScene()
    
    /// If provided, this will be called at the end of every frame, and should return a drawable that will be presented.
    var getCurrentDrawable: (() -> CAMetalDrawable?)?
    
    /// Get the MTLClearColor for the scene's background color. Defaults to black if color can't be retrieved.
    func getBackgroundClearColor() -> MTLClearColor {
        
        // Convert color to RGB from other color spaces (i.e. grayscale) as MTLClearColor requires
        // a RGBA value.
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let rgbaColor = scene.backgroundColor.converted(to: rgbColorSpace, intent: .defaultIntent, options: nil) else {
            return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        
        // We expect 4 color components in RGBA
        guard rgbaColor.numberOfComponents == 4 else {
            return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        guard let rgbaColorComponents = rgbaColor.components else {
            return MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        }
        
        return MTLClearColor(red: rgbaColorComponents[0],
                             green: rgbaColorComponents[1],
                             blue: rgbaColorComponents[2],
                             alpha: rgbaColorComponents[3])
    }
    
    // MARK: - Render pass descriptors
    
    let shadowRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].loadAction = .dontCare
        descriptor.colorAttachments[0].storeAction = .dontCare
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        
        descriptor.defaultRasterSampleCount = 0
        descriptor.renderTargetWidth = ShadowTextures.textureWidth
        descriptor.renderTargetHeight = ShadowTextures.textureHeight
        return descriptor
    }()
    
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
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[1].loadAction = .load
        descriptor.colorAttachments[1].storeAction = .dontCare
        return descriptor
    }()
    
    // MARK: - Texture descriptors
    
    let shadowDepthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()

    let depthDescriptor: MTLDepthStencilDescriptor = {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = MTLCompareFunction.less
        descriptor.isDepthWriteEnabled = true
        return descriptor
    }()
    
    // MARK: - Initialization

    init(device: MTLDevice) {

        self.device = device
        
        // Initialize the uniforms triple buffering array
        self.uniformBuffers = [MTLBuffer]()

        // Setup command queue
        self.commandQueue = device.makeCommandQueue()
        
        // Create frame boundary semaphore
        self.frameBoundarySemaphore = DispatchSemaphore(value: maxBuffersInFlight)
        self.currentFrameIndex = 0
        
        // Call super initializer
        super.init()
        
        // Add buffers to uniforms buffer array
        for _ in 0..<maxBuffersInFlight {
            let uniformBuffer = device.makeBuffer(bytes: &self.scene.frameData,
                                                  length: MemoryLayout<FrameData>.stride,
                                                  options: [])
            guard let uniformBuffer = uniformBuffer else {
                NSLog("Unable to create uniform buffer.")
                continue
            }
            uniformBuffers?.append(uniformBuffer)
        }
        
        // Create pipeline states
        makeShadowRenderPipelineState(device: device)
        makeOpaqueRenderPipelineState(device: device)
        makeImpostorRenderPipelineState(device: device)
        
        // Create shadow textures and sampler
        shadowTextures.makeTextures(device: device,
                                    size: CGSize(width: ShadowTextures.textureWidth, height: ShadowTextures.textureHeight))
        shadowTextures.makeShadowSampler(device: device)
        
        // Depth state
        shadowDepthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }

    // MARK: - Public functions
    
    /// Adds the necessary buffers to display a protein in the renderer with a dense mesh
    func addOpaqueBuffers(vertexBuffer: inout MTLBuffer, atomTypeBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
        self.opaqueVertexBuffer = vertexBuffer
        self.atomTypeBuffer = atomTypeBuffer
        self.opaqueIndexBuffer = indexBuffer
        self.scene.needsRedraw = true
    }
    
    /// Adds the necessary buffers to display a protein in the renderer using billboarding
    func addBillboardingBuffers(vertexBuffer: inout MTLBuffer, subunitBuffer: inout MTLBuffer, atomTypeBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
        self.impostorVertexBuffer = vertexBuffer
        self.subunitBuffer = subunitBuffer
        self.atomTypeBuffer = atomTypeBuffer
        self.impostorIndexBuffer = indexBuffer
        self.scene.needsRedraw = true
    }
    
    /// Deallocates the MTLBuffers used to render a protein
    func removeBuffers() {
        self.opaqueVertexBuffer = nil
        self.atomTypeBuffer = nil
        self.opaqueIndexBuffer = nil
        self.scene.needsRedraw = true
    }
}

// MARK: - Drawing
extension ProteinRenderer: MTKViewDelegate {

    /// This will be called when the ProteinMetalView changes size
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TO-DO: Update G-Buffer texture size to match view size
        self.scene.camera.updateProjection(drawableSize: size)
        self.scene.aspectRatio = Float(size.width / size.height)

        // TO-DO: Enqueue draw calls so this doesn't drop the FPS
        view.draw()
    }

    // This is called periodically to render the scene contents on display
    func draw(in view: MTKView) {
        
        // Check if the scene needs to be redrawn
        guard scene.needsRedraw else { return }
        
        // Retrieve current view drawable
        guard let drawable = view.currentDrawable else { return }
        
        // Assure buffers are loaded
        guard let subunitBuffer = self.subunitBuffer else { return }
        guard let atomTypeBuffer = self.atomTypeBuffer else { return }
        guard let uniformBuffers = self.uniformBuffers else { return }
        
        // Wait until the inflight command buffer has completed its work
        _ = frameBoundarySemaphore.wait(timeout: .distantFuture)

        // MARK: - Update uniforms buffer
        
        // Ensure the uniform buffer is loaded
        let uniformBuffer = uniformBuffers[currentFrameIndex]
        
        // Update current frame index
        currentFrameIndex = (currentFrameIndex + 1) % maxBuffersInFlight
                
        // TO-DO: Address directly instead of copying data on each frame
        self.scene.updateScene()
        withUnsafePointer(to: self.scene.frameData) {
            uniformBuffer.contents()
                .copyMemory(from: $0, byteCount: MemoryLayout<FrameData>.stride)
        }
        
        // MARK: - Command buffer & depth
        
        guard let commandQueue = commandQueue else {
            NSLog("Command queue is nil.")
            return
        }
        
        // Clear the depth texture (depth is in normalized device coordinates,
        // where 1.0 is the maximum/deepest value).
        view.clearDepth = 1.0
        
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Unable to create command buffer.")
            return
        }
        
        // MARK: - Shadow Map pass
        
        shadowRenderingBlock: if scene.hasShadows {
            
            // TO-DO: Shadow pass
            
            // Ensure transparent buffers are loaded
            guard let impostorVertexBuffer = self.impostorVertexBuffer else { return }
            guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
            
            // Attach textures
            shadowRenderPassDescriptor.depthAttachment.texture = shadowTextures.shadowDepthTexture
            shadowRenderPassDescriptor.colorAttachments[0].texture = shadowTextures.shadowTexture
            shadowRenderPassDescriptor.depthAttachment.clearDepth = 1.0
            
            // Create render command encoder
            guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: shadowRenderPassDescriptor) else {
                break shadowRenderingBlock
            }
            
            // Set pipeline state
            guard let shadowRenderingPipelineState = shadowRenderingPipelineState else {
                break shadowRenderingBlock
            }
            renderCommandEncoder.setRenderPipelineState(shadowRenderingPipelineState)
            
            // Set depth state
            renderCommandEncoder.setDepthStencilState(shadowDepthState)
            
            // Add buffers to pipeline
            renderCommandEncoder.setVertexBuffer(impostorVertexBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBuffer(subunitBuffer,
                                                 offset: 0,
                                                 index: 1)
            renderCommandEncoder.setVertexBuffer(atomTypeBuffer,
                                                 offset: 0,
                                                 index: 2)
            renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                                 offset: 0,
                                                 index: 3)
            
            renderCommandEncoder.setFragmentBuffer(uniformBuffer,
                                                   offset: 0,
                                                   index: 1)

            // Don't render back-facing triangles (cull them)
            renderCommandEncoder.setCullMode(.back)
            
            // FIXME: SHADOW
            /*renderCommandEncoder.setDepthBias(0.015, slopeScale: 7, clamp: 0.02)*/

            // Draw primitives
            renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                       indexCount: impostorIndexBuffer.length / MemoryLayout<UInt32>.stride,
                                                       indexType: .uint32,
                                                       indexBuffer: impostorIndexBuffer,
                                                       indexBufferOffset: 0)

            renderCommandEncoder.endEncoding()
        }
                
        // MARK: - Transparent geometry pass
        transparentGeometryBlock: if true {
            
            // Ensure transparent buffers are loaded
            guard let impostorVertexBuffer = self.impostorVertexBuffer else { return }
            guard let impostorIndexBuffer = self.impostorIndexBuffer else { return }
            
            // Attach textures. colorAttachments[0] is the final texture we draw onscreen
            impostorRenderPassDescriptor.colorAttachments[0].texture = drawable.texture
            impostorRenderPassDescriptor.colorAttachments[0].clearColor = getBackgroundClearColor()
            impostorRenderPassDescriptor.depthAttachment.texture = view.depthStencilTexture

            // Create render command encoder
            guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: impostorRenderPassDescriptor) else {
                break transparentGeometryBlock
            }

            // Set pipeline state
            guard let impostorRenderingPipelineState = impostorRenderingPipelineState else {
                break transparentGeometryBlock
            }
            renderCommandEncoder.setRenderPipelineState(impostorRenderingPipelineState)

            // Set depth state
            renderCommandEncoder.setDepthStencilState(depthState)

            // Add buffers to pipeline
            renderCommandEncoder.setVertexBuffer(impostorVertexBuffer,
                                                 offset: 0,
                                                 index: 0)
            renderCommandEncoder.setVertexBuffer(subunitBuffer,
                                                 offset: 0,
                                                 index: 1)
            renderCommandEncoder.setVertexBuffer(atomTypeBuffer,
                                                 offset: 0,
                                                 index: 2)
            renderCommandEncoder.setVertexBuffer(uniformBuffer,
                                                 offset: 0,
                                                 index: 3)
            
            renderCommandEncoder.setFragmentBuffer(uniformBuffer,
                                                   offset: 0,
                                                   index: 1)
            renderCommandEncoder.setFragmentTexture(shadowTextures.shadowDepthTexture,
                                                    index: 0)
            renderCommandEncoder.setFragmentSamplerState(shadowTextures.shadowSampler,
                                                         index: 0)

            // Don't render back-facing triangles (cull them)
            renderCommandEncoder.setCullMode(.back)

            // Draw primitives
            renderCommandEncoder.drawIndexedPrimitives(type: .triangle,
                                                       indexCount: impostorIndexBuffer.length / MemoryLayout<UInt32>.stride,
                                                       indexType: .uint32,
                                                       indexBuffer: impostorIndexBuffer,
                                                       indexBufferOffset: 0)

            renderCommandEncoder.endEncoding()
        }
        
        // MARK: - Triple buffering
        
        // Schedule a drawable presentation to occur after the GPU completes its work
        // commandBuffer.present(drawable, afterMinimumDuration: averageGPUTime)
        commandBuffer.present(drawable)
        
        commandBuffer.addCompletedHandler({ [weak self] commandBuffer in
            guard let self = self else { return }
            // GPU work is complete, signal the semaphore to start the CPU work
            self.frameBoundarySemaphore.signal()
        })
        
        // MARK: - Commit buffer
        // Commit command buffer
        commandBuffer.commit()        
    }

}
