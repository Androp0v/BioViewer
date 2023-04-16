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
    var motionTexture: MTLTexture?
    
    static let motionPixelFormat: MTLPixelFormat = .rg16Float
        
    mutating func makeTextures(device: MTLDevice, textureWidth: Int, textureHeight: Int) {
        
        // Color
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
        
        // Depth
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
        
        // Motion
        let motionTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(
                pixelFormat: Self.motionPixelFormat,
                width: textureWidth,
                height: textureHeight,
                mipmapped: false
            )
        motionTextureDescriptor.textureType = .type2D
        motionTextureDescriptor.usage = [.shaderRead, .shaderWrite]
        motionTextureDescriptor.storageMode = .private
        motionTexture = device.makeTexture(descriptor: motionTextureDescriptor)
        motionTexture?.label = "Motion Texture"
    }
}
