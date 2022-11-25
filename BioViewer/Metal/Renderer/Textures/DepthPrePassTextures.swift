//
//  DepthPrePassTextures.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/22.
//

import Foundation
import Metal
import CoreGraphics

struct DepthPrePassTextures {
    
    var colorTexture: MTLTexture!
    
    var shadowColorTexture: MTLTexture!

    static let pixelFormat = MTLPixelFormat.r32Float
    
    mutating func makeTextures(device: MTLDevice, textureWidth: Int, textureHeight: Int) {
                
        // MARK: - Common texture descriptor
        let commonTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: DepthPrePassTextures.pixelFormat,
                                 width: textureWidth,
                                 height: textureHeight,
                                 mipmapped: false)
        
        commonTextureDescriptor.textureType = .type2D
        
        // MARK: - Visible texture
        
        commonTextureDescriptor.usage = [.renderTarget]
        
        // Memoryless storage mode only works on TBDR GPUs
        if device.supportsFamily(.apple1) {
            commonTextureDescriptor.storageMode = .memoryless
        } else {
            commonTextureDescriptor.storageMode = .private
        }
        
        colorTexture = device.makeTexture(descriptor: commonTextureDescriptor)
        colorTexture.label = "Depth Pre-pass Texture"
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
        
        commonTextureDescriptor.pixelFormat = DepthPrePassTextures.pixelFormat
        commonTextureDescriptor.usage = [.renderTarget]
        
        // Memoryless storage mode only works on TBDR GPUs
        if device.supportsFamily(.apple1) {
            commonTextureDescriptor.storageMode = .memoryless
        } else {
            commonTextureDescriptor.storageMode = .private
        }
        
        shadowColorTexture = device.makeTexture(descriptor: commonTextureDescriptor)
        shadowColorTexture.label = "Shadow Depth Pre-pass Texture"
    }
}
