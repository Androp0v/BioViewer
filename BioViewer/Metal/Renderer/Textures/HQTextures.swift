//
//  HQTextures.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 20/12/21.
//

import Foundation
import Metal

struct HQTextures {
    var hqTexture: MTLTexture!
    var hqDepthTexture: MTLTexture!
    var hqSampler: MTLSamplerState?
    var textureWidth: Int!
    var textureHeight: Int!
    
    // Since the texture should be just enough to fit the bounding sphere on an
    // orthographic projection, the hq texture should be square. High resolution
    // hqs are *very* expensive due to the need to call the fragment shader.
        
    static let hqTexturePixelFormat = MTLPixelFormat.bgra8Unorm
    static let hqDepthTexturePixelFormat = MTLPixelFormat.depth32Float
    
    mutating func makeTextures(device: MTLDevice, photoConfig: PhotoModeConfig) {
        
        // MARK: - Common texture descriptor
        let hqTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: HQTextures.hqTexturePixelFormat,
                                 width: photoConfig.finalTextureSize,
                                 height: photoConfig.finalTextureSize,
                                 mipmapped: false)
        
        hqTextureDescriptor.textureType = .type2D
        
        // MARK: - HQ color texture
        
        hqTextureDescriptor.pixelFormat = HQTextures.hqTexturePixelFormat
        hqTextureDescriptor.usage = [.renderTarget]
                
        hqTexture = device.makeTexture(descriptor: hqTextureDescriptor)
        hqTexture.label = "HQ Texture"
        
        // MARK: - HQ depth texture
        
        hqTextureDescriptor.pixelFormat = .depth32Float
        hqTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        hqTextureDescriptor.storageMode = .shared
        hqDepthTexture = device.makeTexture(descriptor: hqTextureDescriptor)
        hqDepthTexture.label = "HQ Depth Texture"
    }
}
