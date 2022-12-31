//
//  RendererPipelines.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 8/12/21.
//

import Foundation
import Metal

extension ProteinRenderer {
    
    // MARK: - Shadow depth pre-pass
    
    func makeShadowDepthPrePassRenderPipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        let vertexProgram = defaultLibrary.makeFunction(name: "shadow_depth_pre_pass_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "shadow_depth_pre_pass_fragment")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = ShadowTextures.shadowTexturePixelFormat
        pipelineStateDescriptor.colorAttachments[1].pixelFormat = DepthPrePassTextures.pixelFormat

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        pipelineStateDescriptor.label = "Shadow map depth pre-pass"
        shadowDepthPrePassRenderPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
        
    // MARK: - Shadow pass
    
    func makeShadowRenderPipelineState(device: MTLDevice, highQuality: Bool) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        
        let constantValues = MTLFunctionConstantValues()
        var isHighQuality: Bool = highQuality
        constantValues.setConstantValue(&isHighQuality, type: .bool, index: 0)
        
        let vertexProgram = defaultLibrary.makeFunction(name: "shadow_vertex")
        var fragmentProgram: MTLFunction?
        if AppState.hasDepthPrePasses() {
            fragmentProgram = try? defaultLibrary.makeFunction(name: "shadow_fragment", constantValues: constantValues)
        } else {
            fragmentProgram = try? defaultLibrary.makeFunction(name: "shadow_fragment_no_prepass", constantValues: constantValues)
        }
        guard let fragmentProgram else {
            return
        }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        
        // Specify the format of the depth textures
        pipelineStateDescriptor.depthAttachmentPixelFormat = ShadowTextures.shadowDepthTexturePixelFormat
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = ShadowTextures.shadowTexturePixelFormat
        if AppState.hasDepthPrePasses() {
            pipelineStateDescriptor.colorAttachments[1].pixelFormat = DepthPrePassTextures.pixelFormat
        }

        pipelineStateDescriptor.label = "Shadow map impostor shading"
        
        if isHighQuality {
            shadowHQRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } else {
            shadowRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
    }
    
    // MARK: - Main depth pre-pass
    
    func makeDepthPrePassRenderPipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        let vertexProgram = defaultLibrary.makeFunction(name: "depth_pre_pass_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "depth_pre_pass_fragment")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        if AppState.hasDepthPrePasses() {
            pipelineStateDescriptor.colorAttachments[1].pixelFormat = DepthPrePassTextures.pixelFormat
        }

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float

        pipelineStateDescriptor.label = "Main depth pre-pass"
        depthPrePassRenderPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
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

        pipelineStateDescriptor.label = "Opaque geometry pass"
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
        case .solidSpheres, .ballAndSticks:
            var useHighShadowSampleCount: Bool = false
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
        case .solidSpheresHQ, .ballAndSticksHQ:
            var useHighShadowSampleCount: Bool = true
            constantValues.setConstantValue(&useHighShadowSampleCount, type: .bool, index: 0)
        }
        var hasDepthPrePass: Bool = AppState.hasDepthPrePasses()
        constantValues.setConstantValue(&hasDepthPrePass, type: .bool, index: 1)
        
        // Vertex and fragment functions
        let vertexProgram = defaultLibrary.makeFunction(name: "impostor_vertex")
        var fragmentProgram: MTLFunction?
        if AppState.hasDepthPrePasses() {
            fragmentProgram = try? defaultLibrary.makeFunction(name: "impostor_fragment", constantValues: constantValues)
        } else {
            fragmentProgram = try? defaultLibrary.makeFunction(name: "impostor_fragment_no_prepass", constantValues: constantValues)
        }
        guard let fragmentProgram else {
            return
        }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        if AppState.hasDepthPrePasses() {
            pipelineStateDescriptor.colorAttachments[1].pixelFormat = DepthPrePassTextures.pixelFormat
        }

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        pipelineStateDescriptor.label = "Impostor geometry shading"
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
        if AppState.hasDepthPrePasses() {
            pipelineStateDescriptor.colorAttachments[1].pixelFormat = DepthPrePassTextures.pixelFormat
        }

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        pipelineStateDescriptor.label = "Bond shading"
        // Save to the appropriate pipeline state
        switch variant {
        case .solidSpheres, .ballAndSticks:
            impostorBondRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        case .solidSpheresHQ, .ballAndSticksHQ:
            impostorBondHQRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
    }
    
    // MARK: - Debug Points pipeline
    
    #if DEBUG
    func makeDebugPointsPipelineState(device: MTLDevice) {
        // Setup pipeline
        guard let defaultLibrary = try? device.makeDefaultLibrary(bundle: Bundle(for: ProteinRenderer.self)) else {
            fatalError()
        }
        
        // Vertex and fragment functions
        let vertexProgram = defaultLibrary.makeFunction(name: "debug_point_vertex")
        let fragmentProgram = defaultLibrary.makeFunction(name: "debug_point_fragment")

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // Specify the format of the depth texture
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        pipelineStateDescriptor.label = "[DEBUG] Points shading"
        // Save to the appropriate pipeline state
        debugPointsRenderingPipelineState = try? device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    #endif
}
