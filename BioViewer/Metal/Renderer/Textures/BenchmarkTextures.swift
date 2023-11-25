//
//  BenchmarkTextures.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 25/1/23.
//

import Foundation
import Metal

struct BenchmarkTextures {
    
    static let benchmarkResolution: Int = 1440
    
    var colorTexture: MTLTexture!
    var depthTexture: MTLTexture!

    static let colorPixelFormat = MTLPixelFormat.bgra8Unorm
    static let depthPixelFormat = MTLPixelFormat.depth32Float
    
    mutating func makeTextures(device: MTLDevice) {
                
        // Color texture descriptor
        let colorTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: BenchmarkTextures.colorPixelFormat,
                                 width: BenchmarkTextures.benchmarkResolution,
                                 height: BenchmarkTextures.benchmarkResolution,
                                 mipmapped: false)
        colorTextureDescriptor.textureType = .type2D
        colorTextureDescriptor.usage = [.renderTarget]
        colorTextureDescriptor.storageMode = .shared
        colorTexture = device.makeTexture(descriptor: colorTextureDescriptor)
        colorTexture.label = "Benchmark color Texture"
        
        // Depth texture
        let depthTextureDescriptor = MTLTextureDescriptor
            .texture2DDescriptor(pixelFormat: BenchmarkTextures.depthPixelFormat,
                                 width: BenchmarkTextures.benchmarkResolution,
                                 height: BenchmarkTextures.benchmarkResolution,
                                 mipmapped: false)
        depthTextureDescriptor.textureType = .type2D
        depthTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        depthTextureDescriptor.storageMode = .shared
        depthTexture = device.makeTexture(descriptor: depthTextureDescriptor)
        depthTexture.label = "Benchmark depth Texture"
    }
}
