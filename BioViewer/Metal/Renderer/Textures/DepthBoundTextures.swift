//
//  DepthBoundTextures.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/22.
//

import Foundation
import Metal
import CoreGraphics

struct DepthBoundTextures {
    
    var colorTexture: MTLTexture!
    
    var shadowColorTexture: MTLTexture!

    static let pixelFormat = MTLPixelFormat.r32Uint
    
    mutating func makeTextures(device: MTLDevice, textureWidth: Int, textureHeight: Int) {
                
        // MARK: - Common texture descriptor
        let commonTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: .r32Float,
                                 width: textureWidth,
                                 height: textureHeight,
                                 mipmapped: false)
        
        commonTextureDescriptor.textureType = .type2D
        
        // MARK: - Visible texture
        
        commonTextureDescriptor.pixelFormat = .r32Float
        commonTextureDescriptor.usage = [.renderTarget]
        
        // Memoryless storage mode only works on TBDR GPUs
        if device.supportsFamily(.apple1) {
            commonTextureDescriptor.storageMode = .memoryless
        } else {
            commonTextureDescriptor.storageMode = .private
        }
        
        colorTexture = device.makeTexture(descriptor: commonTextureDescriptor)
        colorTexture.label = "Color depth-bound Texture"
    }
    
    mutating func makeShadowTextures(device: MTLDevice, shadowTextureWidth: Int, shadowTextureHeight: Int) {
        // MARK: - Common texture descriptor
        let commonTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: ShadowTextures.shadowTexturePixelFormat,
                                 width: shadowTextureWidth,
                                 height: shadowTextureHeight,
                                 mipmapped: false)
        
        commonTextureDescriptor.textureType = .type2D
        
        // MARK: - Visible texture
        
        commonTextureDescriptor.pixelFormat = .r32Float
        commonTextureDescriptor.usage = [.renderTarget]
        
        // Memoryless storage mode only works on TBDR GPUs
        if device.supportsFamily(.apple1) {
            commonTextureDescriptor.storageMode = .memoryless
        } else {
            commonTextureDescriptor.storageMode = .private
        }
        
        shadowColorTexture = device.makeTexture(descriptor: commonTextureDescriptor)
        shadowColorTexture.label = "Shadow color depth-bound Texture"
    }
}
