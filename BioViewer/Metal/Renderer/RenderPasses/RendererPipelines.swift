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
    func makeShadowRenderPipelineState(device: MTLDevice, useFixedRadius: Bool) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        
        let constantValues = MTLFunctionConstantValues()
        var useFixedRadius = useFixedRadius
        constantValues.setConstantValue(&useFixedRadius, type: .bool, index: 0)
        
        let vertexProgram = defaultLibrary.makeFunction(name: "shadow_vertex")
        guard let fragmentProgram = try? defaultLibrary.makeFunction(name: "shadow_fragment", constantValues: constantValues) else {
            return
        }

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
        case solidSpheres
        case solidSpheresHQ
        case ballAndSticks
        case ballAndSticksHQ
    }
    
    func makeImpostorRenderPipelineState(device: MTLDevice, variant: ImpostorRenderPassVariant) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        
        // Constant values to avoid unwanted branching
        let constantValues = MTLFunctionConstantValues()
        switch variant {
        case .solidSpheres:
            var useHighShadowSampleCount: Bool = false
            var useFixedRadius: Bool = false
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
            constantValues.setConstantValue(&useFixedRadius, type: .bool, index: 1)
        case .solidSpheresHQ:
            var useHighShadowSampleCount: Bool = true
            var useFixedRadius: Bool = false
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
            constantValues.setConstantValue(&useFixedRadius, type: .bool, index: 1)
        case .ballAndSticks:
            var useHighShadowSampleCount: Bool = false
            var useFixedRadius: Bool = true
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
            constantValues.setConstantValue(&useFixedRadius, type: .bool, index: 1)
        case .ballAndSticksHQ:
            var useHighShadowSampleCount: Bool = true
            var useFixedRadius: Bool = true
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
            constantValues.setConstantValue(&useFixedRadius, type: .bool, index: 1)
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
        case .solidSpheres, .ballAndSticks:
            impostorRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        case .solidSpheresHQ, .ballAndSticksHQ:
            impostorHQRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
    }
    
    // MARK: - Impostor bonds
    func makeImpostorBondRenderPipelineState(device: MTLDevice, variant: ImpostorRenderPassVariant) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        
        // Constant values to avoid unwanted branching
        let constantValues = MTLFunctionConstantValues()
        switch variant {
        case .solidSpheres, .ballAndSticks:
            var useHighShadowSampleCount: Bool = false
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
        case .solidSpheresHQ, .ballAndSticksHQ:
            var useHighShadowSampleCount: Bool = true
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
        }
        
        // Vertex and fragment functions
        let vertexProgram = defaultLibrary.makeFunction(name: "impostor_bond_vertex")
        let fragmentProgram = try? defaultLibrary.makeFunction(name: "impostor_bond_fragment", constantValues: constantValues)

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        // Save to the appropriate pipeline state
        switch variant {
        case .solidSpheres, .ballAndSticks:
            impostorBondRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        case .solidSpheresHQ, .ballAndSticksHQ:
            impostorBondHQRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
    }
}
