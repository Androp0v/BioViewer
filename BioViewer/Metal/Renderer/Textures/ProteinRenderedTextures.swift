//
//  ProteinRenderedViewDepthTexture.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/4/23.
//

import Foundation
import MetalKit

struct ProteinRenderedTextures {
    
    var colorTexture: MTLTexture!
    var depthTexture: MTLTexture!
        
    mutating func makeTextures(device: MTLDevice, textureWidth: Int, textureHeight: Int) {
        let colorTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: textureWidth,
                height: textureHeight,
                mipmapped: false
            )
        colorTextureDescriptor.textureType = .type2D
        colorTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        colorTextureDescriptor.storageMode = .private
        colorTexture = device.makeTexture(descriptor: colorTextureDescriptor)
        colorTexture.label = "Color Texture"
        
        let depthTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: .depth32Float,
                width: textureWidth,
                height: textureHeight,
                mipmapped: false
            )
        depthTextureDescriptor.textureType = .type2D
        depthTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        depthTextureDescriptor.storageMode = .private
        depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)
        depthTexture.label = "Depth Texture"
    }
}
