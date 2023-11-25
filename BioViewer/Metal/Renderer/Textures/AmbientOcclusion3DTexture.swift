//
//  AmbientOcclusion3DTexture.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 29/4/23.
//

import Foundation
import Metal

struct AmbientOcclusion3DTexture {
    
    static let defaultSize: Int = 64
    static let pixelFormat: MTLPixelFormat = .r32Float
    
    var texture: MTLTexture?
    var textureSize: Int = AmbientOcclusion3DTexture.defaultSize
    
    mutating func makeTexture(device: MTLDevice) {
        
        // MARK: - Texture size
        self.textureSize = AmbientOcclusion3DTexture.defaultSize
        
        // MARK: - Texture descriptor
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.width = textureSize
        textureDescriptor.height = textureSize
        textureDescriptor.depth = textureSize
        textureDescriptor.textureType = .type3D
        textureDescriptor.storageMode = .private
        
        texture = device.makeTexture(descriptor: textureDescriptor)
        texture?.label = "Ambient Occlusion Texture"
    }
}
