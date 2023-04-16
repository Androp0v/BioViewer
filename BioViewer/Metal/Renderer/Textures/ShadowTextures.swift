//
//  ShadowTextures.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 8/12/21.
//

import Foundation
import Metal
import CoreGraphics

struct ShadowTextures {
    var shadowTexture: MTLTexture!
    var shadowDepthTexture: MTLTexture!
    var shadowSampler: MTLSamplerState?
    var textureWidth: Int!
    var textureHeight: Int!
    
    // Since the texture should be just enough to fit the bounding sphere on an
    // orthographic projection, the shadow texture should be square. High resolution
    // shadows are *very* expensive due to the need to call the fragment shader.
    
    static let defaultTextureWidth: Int = 2048
    static let defaultTextureHeight: Int = 2048
    
    static let shadowTexturePixelFormat = MTLPixelFormat.r32Float
    static let shadowDepthTexturePixelFormat = MTLPixelFormat.depth32Float
    
    mutating func makeTextures(device: MTLDevice, textureWidth: Int, textureHeight: Int) {
        
        // MARK: - Texture size
        self.textureWidth = textureWidth
        self.textureHeight = textureHeight
        
        // MARK: - Common texture descriptor
        let shadowTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: ShadowTextures.shadowTexturePixelFormat,
                                 width: self.textureWidth,
                                 height: self.textureHeight,
                                 mipmapped: false)
        
        shadowTextureDescriptor.textureType = .type2D
        
        // MARK: - Shadow color texture
        
        shadowTextureDescriptor.pixelFormat = ShadowTextures.shadowTexturePixelFormat
        shadowTextureDescriptor.usage = [.renderTarget]
        
        // Memoryless storage mode only works on TBDR GPUs
        if device.supportsFamily(.apple1) {
            shadowTextureDescriptor.storageMode = .memoryless
        } else {
            shadowTextureDescriptor.storageMode = .private
        }
        
        shadowTexture = device.makeTexture(descriptor: shadowTextureDescriptor)
        shadowTexture.label = "Shadow Texture"
        
        // MARK: - Shadow depth texture
        
        shadowTextureDescriptor.pixelFormat = .depth32Float
        shadowTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        shadowTextureDescriptor.storageMode = .private
        shadowDepthTexture = device.makeTexture(descriptor: shadowTextureDescriptor)
        shadowDepthTexture.label = "Shadow Depth Texture"
    }
    
    // MARK: - Shadow sampler
    
    mutating func makeShadowSampler(device: MTLDevice) {
        
        let shadowSamplerDescriptor = MTLSamplerDescriptor()
        
        // Address modes
        shadowSamplerDescriptor.sAddressMode = .clampToEdge
        shadowSamplerDescriptor.rAddressMode = .clampToEdge
        shadowSamplerDescriptor.tAddressMode = .clampToEdge
        
        // Interpolation
        shadowSamplerDescriptor.magFilter = .linear
        shadowSamplerDescriptor.minFilter = .linear
        
        // If it's less or equal than the depth seen by the sun's frame of reference, the
        // fragment will be lit.
        if AppState.hasSamplerCompareSupport() {
            shadowSamplerDescriptor.compareFunction = .lessEqual
        }
        
        shadowSampler = device.makeSamplerState(descriptor: shadowSamplerDescriptor)
    }
}
