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
    
    static let textureWidth: Int = 2048
    static let textureHeight: Int = 2048
    
    static let shadowTexturePixelFormat = MTLPixelFormat.r32Float
    static let shadowDepthTexturePixelFormat = MTLPixelFormat.depth32Float
    
    mutating func makeTextures(device: MTLDevice, size: CGSize) {
        
        let shadowTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb,
                                 width: ShadowTextures.textureWidth,
                                 height: ShadowTextures.textureHeight,
                                 mipmapped: false)
        
        shadowTextureDescriptor.textureType = .type2D
        shadowTextureDescriptor.usage = [.renderTarget]
        shadowTextureDescriptor.storageMode = .memoryless
        
        // Shadow color texture
        shadowTextureDescriptor.pixelFormat = ShadowTextures.shadowTexturePixelFormat
        shadowTexture = device.makeTexture(descriptor: shadowTextureDescriptor)
        shadowTexture.label = "Shadow Texture"
        
        // Shadow depth texture
        shadowTextureDescriptor.pixelFormat = .depth32Float
        shadowTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        shadowTextureDescriptor.storageMode = .private
        shadowDepthTexture = device.makeTexture(descriptor: shadowTextureDescriptor)
        shadowDepthTexture.label = "Shadow Depth Texture"
    }
}
