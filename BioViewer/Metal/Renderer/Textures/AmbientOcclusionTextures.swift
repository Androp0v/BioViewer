//
//  AmbientOcclusionTextures.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 14/12/21.
//

import Foundation
import Metal
import CoreGraphics

struct AmbientOcclusionTextures {
    var ambientOcclusionTexture: MTLTexture!
    var ambientOcclusionDepthTexture: MTLTexture!
    var ambientOcclusionSampler: MTLSamplerState?
        
    static let atomTextureWidth: Int = 6
    static let atomTextureHeight: Int = 6
    
    static let ambientOcclusionTexturePixelFormat = MTLPixelFormat.r32Float
    static let ambientOcclusionDepthTexturePixelFormat = MTLPixelFormat.depth32Float
    
    mutating func makeTextures(device: MTLDevice, protein: Protein) {
        
        // MARK: - Common texture descriptor
        let ambientOcclusionTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: AmbientOcclusionTextures.ambientOcclusionTexturePixelFormat,
                                 width: AmbientOcclusionTextures.atomTextureWidth * protein.atomCount,
                                 height: AmbientOcclusionTextures.atomTextureHeight,
                                 mipmapped: false)
        
        ambientOcclusionTextureDescriptor.textureType = .type2D
        
        // MARK: - ambientOcclusion color texture
        
        ambientOcclusionTextureDescriptor.pixelFormat = AmbientOcclusionTextures.ambientOcclusionTexturePixelFormat
        ambientOcclusionTextureDescriptor.usage = [.renderTarget]
        
        // Memoryless storage mode only works on TBDR GPUs
        if device.supportsFamily(.apple1) {
            ambientOcclusionTextureDescriptor.storageMode = .memoryless
        } else {
            ambientOcclusionTextureDescriptor.storageMode = .private
        }
        
        ambientOcclusionTexture = device.makeTexture(descriptor: ambientOcclusionTextureDescriptor)
        ambientOcclusionTexture.label = "ambientOcclusion Texture"
        
        // MARK: - ambientOcclusion depth texture
        
        ambientOcclusionTextureDescriptor.pixelFormat = .depth32Float
        ambientOcclusionTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        ambientOcclusionTextureDescriptor.storageMode = .private
        ambientOcclusionDepthTexture = device.makeTexture(descriptor: ambientOcclusionTextureDescriptor)
        ambientOcclusionDepthTexture.label = "ambientOcclusion Depth Texture"
    }
    
    // MARK: - ambientOcclusion sampler
    
    mutating func makeambientOcclusionSampler(device: MTLDevice) {
        
        let ambientOcclusionSamplerDescriptor = MTLSamplerDescriptor()
        
        // Address modes
        ambientOcclusionSamplerDescriptor.sAddressMode = .clampToEdge
        ambientOcclusionSamplerDescriptor.rAddressMode = .clampToEdge
        ambientOcclusionSamplerDescriptor.tAddressMode = .clampToEdge
        
        // Interpolation
        ambientOcclusionSamplerDescriptor.magFilter = .linear
        ambientOcclusionSamplerDescriptor.minFilter = .linear
        
        // If it's less or equal than the depth seen by the sun's frame of reference, the
        // fragment will be lit.
        if AppState.hasSamplerCompareSupport() {
            ambientOcclusionSamplerDescriptor.compareFunction = .lessEqual
        }
        
        ambientOcclusionSampler = device.makeSamplerState(descriptor: ambientOcclusionSamplerDescriptor)
    }
}
