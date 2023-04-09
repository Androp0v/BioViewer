//
//  MetalFXUpscaledTexture.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
import MetalKit

struct MetalFXUpscaledTexture {
    
    var upscaledTexture: MTLTexture!
    
    mutating func makeTexture(device: MTLDevice, width: Int, height: Int) {
                
        // Color texture descriptor
        let colorTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: BenchmarkTextures.colorPixelFormat,
                width: width,
                height: height,
                mipmapped: false
            )
        colorTextureDescriptor.textureType = .type2D
        colorTextureDescriptor.usage = [.renderTarget]
        colorTextureDescriptor.storageMode = .private
        upscaledTexture = device.makeTexture(descriptor: colorTextureDescriptor)
        upscaledTexture.label = "MetalFX Upscaled Texture"
    }
}
