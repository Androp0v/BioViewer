//
//  ProteinRenderTarget.swift
//  BioViewer
//
//  Created by Raúl Montón Pinillos on 9/4/23.
//

import Foundation
import Metal
import MetalKit

class ProteinRenderTarget {
    
    // MARK: - Constants
    
    /// Supersampling factor, if you want to perform SSAA.
    let superSamplingCount: Float = 1.0
    /// Upscaling factor used for MetalFX upscaling. Render resolution will be drawable resolution / this factor.
    let metalFXUpscalingFactor: Float = 1.5
    
    // MARK: - Window and texture sizes
    
    private(set) var windowSize: MTLSize = MTLSize(width: 0, height: 0, depth: 0)
    private(set) var renderSize: MTLSize = MTLSize(width: 0, height: 0, depth: 0)
    private(set) var upscaledSize: MTLSize = MTLSize(width: 0, height: 0, depth: 0)
    
    // MARK: - Textures
    
    /// Rendered textures, using `renderSize` resolution.
    private(set) var renderedTextures = ProteinRenderedTextures()
    /// MetalFX upscaled texture.
    private(set) var upscaledTexture = MetalFXUpscaledTexture()
    
    // MARK: - Functions
    
    func updateRenderTarget(for newWindowSize: CGSize, renderer: ProteinRenderer) {
        self.windowSize = MTLSizeMake(Int(newWindowSize.width), Int(newWindowSize.height), 1)
        self.renderSize = MTLSizeMake(
            Int(Float(newWindowSize.width) * superSamplingCount / metalFXUpscalingFactor),
            Int(Float(newWindowSize.height) * superSamplingCount / metalFXUpscalingFactor),
            1
        )
        self.upscaledSize = MTLSizeMake(
            Int(Float(newWindowSize.width) * superSamplingCount),
            Int(Float(newWindowSize.height) * superSamplingCount),
            1
        )
        // Update rendered textures
        renderedTextures.makeTextures(
            device: renderer.device,
            textureWidth: renderSize.width,
            textureHeight: renderSize.height
        )
        // Update MetalFX upscaler
        renderer.makeSpatialScaler(
            inputSize: MTLSizeMake(
                renderSize.width,
                renderSize.height,
                1
            ),
            outputSize: MTLSizeMake(
                upscaledSize.width,
                upscaledSize.height,
                1
            )
        )
        renderer.makeTemporalScaler(
            inputSize: MTLSizeMake(
                renderSize.width,
                renderSize.height,
                1
            ),
            outputSize: MTLSizeMake(
                upscaledSize.width,
                upscaledSize.height,
                1
            )
        )
        // Update MetalFX upscaled texture
        upscaledTexture.makeTexture(
            device: renderer.device,
            width: upscaledSize.width,
            height: upscaledSize.height
        )
        // Update the scene
        renderer.scene.renderResolution = simd_float2(
            Float(renderSize.width),
            Float(renderSize.height)
        )
    }
}
