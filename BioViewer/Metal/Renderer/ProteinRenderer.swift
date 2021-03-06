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
    
    // MARK: - Scheduling
    
    /// Whether a frame is currently being processed on the CPU.
    var isProcessingFrame: Bool = false
    /// GCD queue used to process frames.
    let renderQueue = DispatchQueue(label: "com.bioviewer.renderqueue", qos: .userInteractive)
    /// Used to signal that a new frame is ready to be computed by the CPU.
    var frameBoundarySemaphore: DispatchSemaphore
    /// Used to index the dynamic buffers.
    var currentFrameIndex: Int
    /// Used to ensure buffers are untouched during frame rendering.
    let bufferResourceLock = NSLock()
    
    // MARK: - Metal variables
    
    /// GPU
    var device: MTLDevice
    /// Pipeline state for filling the color buffer.
    var fillColorComputePipelineState: MTLComputePipelineState?
    /// Pipeline state for the directional shadow creation.
    var shadowRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the opaque geometry rendering.
    var opaqueRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times).
    var impostorRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times) in Photo Mode.
    var impostorHQRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times).
    var impostorBondRenderingPipelineState: MTLRenderPipelineState?
    /// Pipeline state for the impostor geometry rendering (transparent at times) in Photo Mode.
    var impostorBondHQRenderingPipelineState: MTLRenderPipelineState?
    /// Shadow depth state.
    var shadowDepthState: MTLDepthStencilState?
    /// Depth state.
    var depthState: MTLDepthStencilState?
    /// Command queue.
    var commandQueue: MTLCommandQueue?
    
    // MARK: - Buffers
    
    /// Used to pass the geometry vertex data to the shader when using a dense mesh
    var opaqueVertexBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader when using a dense mesh
    var opaqueIndexBuffer: MTLBuffer?
    
    /// Used to pass the geometry vertex data to the shader when using billboarding
    var impostorVertexBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader  when using billboarding
    var impostorIndexBuffer: MTLBuffer?
    /// Used to pass the atomic type data to the shader (used for coloring, size...)
    var atomTypeBuffer: MTLBuffer?
    /// Used to pass the subunit index to the shader (used for coloring)
    var subunitBuffer: MTLBuffer?
    /// Used to pass the atom base color to the shader (used for coloring, size...)
    var atomColorBuffer: MTLBuffer?
    /// Used to pass constant frame data to the shader
    var uniformBuffers: [MTLBuffer]?
    
    /// Used to pass the geometry vertex data to the shader when using billboarding bonds
    var impostorBondVertexBuffer: MTLBuffer?
    /// Used to pass the index data (how the vertices data is connected to form triangles) to the shader  when using billboarding bonds.
    var impostorBondIndexBuffer: MTLBuffer?
    
    // MARK: - Textures
    
    var shadowTextures = ShadowTextures()

    // MARK: - Runtime variables
    
    /// The scene contains the high-level information about the rendering of the scene (cameras, lighting...)
    var scene = MetalScene()
    /// Data source with the proteins that back the rendering.
    var proteinDataSource: ProteinViewDataSource?
    
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
        return descriptor
    }()
    
    let impostorRenderPassDescriptor: MTLRenderPassDescriptor = {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .dontCare
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
        
        // Create compute pipeline states
        makeFillColorComputePipelineState(device: device)
        
        // Create render pipeline states
        makeShadowRenderPipelineState(device: device, useFixedRadius: false)
        makeOpaqueRenderPipelineState(device: device)
        makeImpostorRenderPipelineState(device: device, variant: .solidSpheres)
        makeImpostorBondRenderPipelineState(device: device, variant: .solidSpheres)
        
        // Create shadow textures and sampler
        shadowTextures.makeTextures(device: device,
                                    textureWidth: ShadowTextures.defaultTextureWidth,
                                    textureHeight: ShadowTextures.defaultTextureHeight)
        shadowTextures.makeShadowSampler(device: device)
        
        // Depth state
        shadowDepthState = device.makeDepthStencilState(descriptor: depthDescriptor)
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }

    // MARK: - Public functions
        
    func createAtomColorBuffer(protein: Protein, subunitBuffer: MTLBuffer, atomTypeBuffer: MTLBuffer, colorList: [Color]?, colorBy: Int?) {
        
        // Get the number of configurations
        let configurationCount = protein.configurationCount
        
        // WORKAROUND: The memory layout should conform to simd_half3's stride, which is
        // syntactic sugar for SIMD3<Float16>, but Float16 is (still) unavailable on macOS
        // due to lack of support on x86. We assume SIMD3<Int16> is packed in the same way
        // Metal packs the half3 type.
        guard let generatedColorBuffer = device.makeBuffer(
            length: protein.atomCount * configurationCount * MemoryLayout<SIMD3<Int16>>.stride
        ) else { return }
        
        bufferResourceLock.lock()
        self.atomColorBuffer = generatedColorBuffer
        bufferResourceLock.unlock()
    }
    
    /// Adds the necessary buffers to display a protein in the renderer with a dense mesh
    func addOpaqueBuffers(vertexBuffer: inout MTLBuffer, atomTypeBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
        bufferResourceLock.lock()
        self.opaqueVertexBuffer = vertexBuffer
        self.atomTypeBuffer = atomTypeBuffer
        self.opaqueIndexBuffer = indexBuffer
        self.scene.needsRedraw = true
        bufferResourceLock.unlock()
    }
    
    /// Sets the necessary buffers to display a protein in the renderer using billboarding
    func setBillboardingBuffers(vertexBuffer: inout MTLBuffer, subunitBuffer: inout MTLBuffer, atomTypeBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
        bufferResourceLock.lock()
        self.impostorVertexBuffer = vertexBuffer
        self.subunitBuffer = subunitBuffer
        self.atomTypeBuffer = atomTypeBuffer
        self.impostorIndexBuffer = indexBuffer
        self.scene.needsRedraw = true
        self.scene.lastColorPassRequest = CACurrentMediaTime()
        bufferResourceLock.unlock()
    }
    
    /// Sets the necessary buffers to display a protein in the renderer using billboarding
    func setColorBuffer(colorBuffer: inout MTLBuffer) {
        bufferResourceLock.lock()
        self.atomColorBuffer = colorBuffer
        bufferResourceLock.unlock()
    }
    
    /// Sets the necessary buffers to display atom bonds in the renderer using billboarding
    func setBillboardingBonds(vertexBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer) {
        bufferResourceLock.lock()
        self.impostorBondVertexBuffer = vertexBuffer
        self.impostorBondIndexBuffer = indexBuffer
        self.scene.needsRedraw = true
        bufferResourceLock.unlock()
    }
    
    /// Deallocates the MTLBuffers used to render a protein
    func removeBuffers() {
        bufferResourceLock.lock()
        self.opaqueVertexBuffer = nil
        self.atomTypeBuffer = nil
        self.opaqueIndexBuffer = nil
        self.scene.needsRedraw = true
        bufferResourceLock.unlock()
    }
    
    /// Make new impostor pipeline variant.
    func remakeImpostorPipelineForVariant(variant: ImpostorRenderPassVariant) {
        makeImpostorRenderPipelineState(device: self.device, variant: variant)
    }
    
    /// Make new shadow pipeline variant.
    func remakeShadowPipelineForVariant(useFixedRadius: Bool) {
        makeShadowRenderPipelineState(device: self.device, useFixedRadius: useFixedRadius)
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
        guard scene.needsRedraw || scene.isPlaying else { return }
        guard !isProcessingFrame else { return }
        
        isProcessingFrame = true
        
        // Render on a background thread
        renderQueue.async { [weak self] in
                                                
            guard let self = self else {
                self?.isProcessingFrame = false
                return
            }
            
            self.bufferResourceLock.lock()
            
            // Assure buffers are loaded
            guard self.atomTypeBuffer != nil else {
                self.isProcessingFrame = false
                self.bufferResourceLock.unlock()
                return
            }
            guard self.atomColorBuffer != nil else {
                self.isProcessingFrame = false
                self.bufferResourceLock.unlock()
                return
            }
            guard let uniformBuffers = self.uniformBuffers else {
                self.isProcessingFrame = false
                self.bufferResourceLock.unlock()
                return
            }
            
            // Wait until the inflight command buffer has completed its work
            _ = self.frameBoundarySemaphore.wait(timeout: .distantFuture)

            // MARK: - Update uniforms buffer
            
            // Ensure the uniform buffer is loaded
            var uniformBuffer = uniformBuffers[self.currentFrameIndex]
            
            // Update current frame index
            self.currentFrameIndex = (self.currentFrameIndex + 1) % self.maxBuffersInFlight
                    
            // Update uniform buffer
            self.scene.updateScene()
            withUnsafePointer(to: self.scene.frameData) {
                uniformBuffer.contents()
                    .copyMemory(from: $0, byteCount: MemoryLayout<FrameData>.stride)
            }
            
            // MARK: - Command buffer & queue
            
            guard let commandQueue = self.commandQueue else {
                NSLog("Command queue is nil.")
                self.isProcessingFrame = false
                self.bufferResourceLock.unlock()
                return
            }
                    
            // Create command buffer
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                NSLog("Unable to create command buffer.")
                self.isProcessingFrame = false
                self.bufferResourceLock.unlock()
                return
            }
            
            /*- COMPUTE PASSES -*/
            
            // MARK: - Fill color pass
            
            if self.scene.lastColorPassRequest > self.scene.lastColorPass {
                self.fillColorPass(commandBuffer: commandBuffer,
                                   colorBuffer: self.atomColorBuffer,
                                   subunitBuffer: self.subunitBuffer,
                                   atomTypeBuffer: self.atomTypeBuffer,
                                   colorFill: self.scene.colorFill)
            }
            
            /*- RENDER PASSES -*/
            
            // MARK: - Shadow Map pass
            
            self.shadowRenderPass(commandBuffer: commandBuffer, uniformBuffer: &uniformBuffer, shadowTextures: self.shadowTextures)
            
            // GETTING THE DRAWABLE
            // The final pass can only render if a drawable is available, otherwise it needs to skip
            // rendering this frame. Get the drawable as late as possible.
            if let drawable = view.currentDrawable {
                    
                // MARK: - Impostor pass
                
                self.impostorRenderPass(commandBuffer: commandBuffer,
                                        uniformBuffer: &uniformBuffer,
                                        drawableTexture: drawable.texture,
                                        depthTexture: view.depthStencilTexture,
                                        shadowTextures: self.shadowTextures,
                                        variant: .solidSpheres,
                                        renderBonds: self.scene.currentVisualization == .ballAndStick)
                                
                // Schedule a drawable presentation to occur after the GPU completes its work
                // commandBuffer.present(drawable, afterMinimumDuration: averageGPUTime)
                commandBuffer.present(drawable)
            }
            
            // MARK: - Triple buffering
            
            commandBuffer.addCompletedHandler({ [weak self] commandBuffer in
                guard let self = self else { return }
                // GPU work is complete, signal the semaphore to start the CPU work
                self.frameBoundarySemaphore.signal()
            })
            
            // MARK: - Commit buffer
            // Commit command buffer
            commandBuffer.commit()
            
            // MARK: - Finish
            self.isProcessingFrame = false
            self.bufferResourceLock.unlock()
        }
    }

}
