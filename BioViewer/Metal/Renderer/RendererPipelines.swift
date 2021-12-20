//
//  RendererPipelines.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 8/12/21.
//

import Foundation
import Metal

extension ProteinRenderer {
    
    // MARK: - Shadow pass
    func makeShadowRenderPipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        let vertexProgram = defaultLibrary.makeFunction(name: "shadow_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "shadow_fragment")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        
        // Specify the format of the depth textures
        pipelineStateDescriptor.depthAttachmentPixelFormat = ShadowTextures.shadowDepthTexturePixelFormat
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = ShadowTextures.shadowTexturePixelFormat

        shadowRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    // MARK: - Opaque geometry pass
    func makeOpaqueRenderPipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float

        opaqueRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    // MARK: - Impostor geometry pass
    
    enum ImpostorRenderPassVariant {
        case normal
        case highQuality
    }
    
    func makeImpostorRenderPipelineState(device: MTLDevice, variant: ImpostorRenderPassVariant) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        
        // Constant values to avoid unwanted branching
        let constantValues = MTLFunctionConstantValues()
        switch variant {
        case .normal:
            var useHighShadowSampleCount: Bool = false
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
        case .highQuality:
            var useHighShadowSampleCount: Bool = true
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
        }
        
        // Vertex and fragment functions
        let vertexProgram = defaultLibrary.makeFunction(name: "impostor_vertex")
        let fragmentProgram = try? defaultLibrary.makeFunction(name: "impostor_fragment", constantValues: constantValues)

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        // Save to the appropriate pipeline state
        switch variant {
        case .normal:
            impostorRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        case .highQuality:
            impostorHQRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
    }
}
