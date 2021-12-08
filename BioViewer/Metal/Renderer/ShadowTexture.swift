//
//  ShadowTexture.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 8/12/21.
//

import Foundation
import Metal

struct ShadowTextures {
    var shadowTexture: MTLTexture!
    var shadowDepthTexture: MTLTexture!
    
    static let textureWidth: Int = 1024
    static let textureHeight: Int = 1024
    
    static let shadowTexturePixelFormat = MTLPixelFormat.bgra8Unorm // FIXME: .r32Float
    static let shadowDepthTexturePixelFormat = MTLPixelFormat.depth32Float
    
    mutating func makeTextures(device: MTLDevice, size: CGSize, storageMode: MTLStorageMode) {
        
        let shadowTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb,
                                 width: ShadowTextures.textureWidth,
                                 height: ShadowTextures.textureHeight,
                                 mipmapped: false)
        
        shadowTextureDescriptor.textureType = .type2D
        shadowTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        shadowTextureDescriptor.storageMode = storageMode
        
        // Shadow color texture
        shadowTextureDescriptor.pixelFormat = ShadowTextures.shadowTexturePixelFormat
        shadowTexture = device.makeTexture(descriptor: shadowTextureDescriptor)
        shadowTexture.label = "Shadow Texture"
        
        // Shadow depth texture
        shadowTextureDescriptor.pixelFormat = .depth32Float
        shadowTextureDescriptor.usage = [.shaderRead, .renderTarget]
        shadowDepthTexture = device.makeTexture(descriptor: shadowTextureDescriptor)
        shadowDepthTexture.label = "Shadow Depth Texture"
    }
}
