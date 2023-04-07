//
//  ProteinRenderedViewDepthTexture.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 7/4/23.
//

import Foundation
import MetalKit

struct ProteinRenderedViewDepthTexture {
    
    var depthTexture: MTLTexture!
        
    mutating func makeTextures(device: MTLDevice, textureWidth: Int, textureHeight: Int) {
        let depthTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: .depth32Float,
                width: textureWidth,
                height: textureHeight,
                mipmapped: false
            )
        depthTextureDescriptor.textureType = .type2D
        depthTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        depthTextureDescriptor.storageMode = .shared
        depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)
        depthTexture.label = "Depth Texture"
    }
}
