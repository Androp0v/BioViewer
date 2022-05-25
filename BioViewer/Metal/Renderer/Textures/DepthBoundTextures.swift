//
//  DepthBoundTextures.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/5/22.
//

import Foundation
import Metal
import CoreGraphics

struct AtomIDTexture {
    
    var atomIDTexture: MTLTexture!

    static let pixelFormat = MTLPixelFormat.r32Uint
    
    mutating func makeTextures(device: MTLDevice, textureWidth: Int, textureHeight: Int) {
                
        // MARK: - Common texture descriptor
        let atomIDTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: ShadowTextures.shadowTexturePixelFormat,
                                 width: textureWidth,
                                 height: textureHeight,
                                 mipmapped: false)
        
        atomIDTextureDescriptor.textureType = .type2D
        
        // MARK: - Shadow color texture
        
        atomIDTextureDescriptor.pixelFormat = AtomIDTexture.pixelFormat
        atomIDTextureDescriptor.usage = [.renderTarget]
        
        // Memoryless storage mode only works on TBDR GPUs
        if device.supportsFamily(.apple1) {
            atomIDTextureDescriptor.storageMode = .memoryless
        } else {
            atomIDTextureDescriptor.storageMode = .private
        }
        
        atomIDTexture = device.makeTexture(descriptor: atomIDTextureDescriptor)
        atomIDTexture.label = "AtomID Texture"
    }
}
