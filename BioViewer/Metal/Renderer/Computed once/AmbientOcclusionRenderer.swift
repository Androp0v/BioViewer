//
//  AmbientOcclusionPass.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/12/21.
//

import Foundation
import Metal

class AmbientOcclusionRenderer {
    
    let device: MTLDevice
    let commandQueue: MTLCommandQueue?
    
    var vertexBuffer: MTLBuffer?
    var atomTypeBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    
    var ambientOcclusionRenderingPipelineState: MTLRenderPipelineState?
    
    var ambientOcclusionTextures = AmbientOcclusionTextures()
    
    // MARK: - Render pass descriptor
    private func createAmbientOcclusionRenderPassDescriptor() -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].loadAction = .dontCare
        descriptor.colorAttachments[0].storeAction = .dontCare
        descriptor.depthAttachment.loadAction = .clear
        descriptor.depthAttachment.storeAction = .store
        
        descriptor.defaultRasterSampleCount = 0
        descriptor.renderTargetWidth = AmbientOcclusionTextures.atomTextureWidth
        descriptor.renderTargetHeight = AmbientOcclusionTextures.atomTextureHeight
        return descriptor
    }
    
    // MARK: - Pipeline state
    func makeAmbientOcclusionRenderPipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        let vertexProgram = defaultLibrary.makeFunction(name: "ambient_occlusion_vertex")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        
        // Specify the format of the depth textures
        pipelineStateDescriptor.depthAttachmentPixelFormat = AmbientOcclusionTextures.ambientOcclusionDepthTexturePixelFormat
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = AmbientOcclusionTextures.ambientOcclusionTexturePixelFormat

        ambientOcclusionRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    // MARK: - Initialization
    init(device: MTLDevice, protein: Protein) {
        
        self.device = device
        
        // Setup command queue
        self.commandQueue = device.makeCommandQueue()
        
        // Create textures
        ambientOcclusionTextures.makeTextures(device: device, protein: protein)
        
        let (vertexBuffer, atomTypeBuffer, indexBuffer) = MetalScheduler.shared.createSphereModel(protein: protein)
        self.vertexBuffer = vertexBuffer
        self.atomTypeBuffer = atomTypeBuffer
        self.indexBuffer = indexBuffer
    }
    
    // MARK: - Render pass
    func ambientOcclusionPass(commandBuffer: MTLCommandBuffer, uniformBuffer: inout MTLBuffer) {
        // MARK: - Create geometry
        guard var vertexBuffer = vertexBuffer else { return }
        guard var atomTypeBuffer = atomTypeBuffer else { return }
        guard var indexBuffer = indexBuffer else { return }
        
        guard let commandQueue = commandQueue else {
            NSLog("Command queue is nil.")
            return
        }
        
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            NSLog("Unable to create command buffer.")
            return
        }
        
        
    }
}
